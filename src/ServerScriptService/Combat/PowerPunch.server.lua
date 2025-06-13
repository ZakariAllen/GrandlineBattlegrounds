local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PowerPunchStart")
local HitEvent = CombatRemotes:WaitForChild("PowerPunchHit")
local VFXEvent = CombatRemotes:WaitForChild("PowerPunchVFX")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local PowerPunchConfig = AbilityConfig.BasicCombat.PowerPunch
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local EvasiveService = require(ReplicatedStorage.Modules.Stats.EvasiveService)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local DamageText = require(ReplicatedStorage.Modules.Effects.DamageText)
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local MoveSoundConfig = require(ReplicatedStorage.Modules.Config.MoveSoundConfig)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local RagdollKnockback = require(ReplicatedStorage.Modules.Combat.RagdollKnockback)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local UltService = require(ReplicatedStorage.Modules.Stats.UltService)
local UltConfig = require(ReplicatedStorage.Modules.Config.UltConfig)
local XPService = require(ReplicatedStorage.Modules.Stats.ExperienceService)
local XPConfig = require(ReplicatedStorage.Modules.Config.XPConfig)
local PersistentStats = require(ReplicatedStorage.Modules.Stats.PersistentStatsService)

local DEBUG = Config.GameSettings.DebugEnabled

if DEBUG then
    print("[PowerPunch] Server script loaded")
    print("[PowerPunch] Damage", PowerPunchConfig.Damage, "stun", PowerPunchConfig.StunDuration)
end

local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

local activeTracks = {}
local function playAnimation(humanoid, animId)
    if not animId or not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    animId = tostring(animId)
    if not animId:match("^rbxassetid://") then
        animId = "rbxassetid://" .. animId
    end

    local current = activeTracks[humanoid]
    if current and current.IsPlaying then
        current:Stop(0.05)
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action
    track:Play()

    activeTracks[humanoid] = track

    track.Stopped:Connect(function()
        if activeTracks[humanoid] == track then
            activeTracks[humanoid] = nil
        end
    end)
end

local function stopAnimation(humanoid)
    local current = activeTracks[humanoid]
    if current and current.IsPlaying then
        current:Stop(0.05)
    end
    activeTracks[humanoid] = nil
end

StartEvent.OnServerEvent:Connect(function(player)
    if DEBUG then print("[PowerPunch] StartEvent from", player.Name) end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        if DEBUG then print("[PowerPunch] No humanoid") end
        return
    end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then
        if DEBUG then print("[PowerPunch] Player stunned or locked") end
        return
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BasicCombat" then
        if DEBUG then print("[PowerPunch] Invalid tool") end
        return
    end
    if not StaminaService.Consume(player, 20) then
        if DEBUG then print("[PowerPunch] Not enough stamina") end
        return
    end
    playAnimation(humanoid, AnimationData.SpecialMoves.PowerPunch)
    if DEBUG then print("[PowerPunch] Animation triggered") end
    VFXEvent:FireAllClients(player)
end)

HitEvent.OnServerEvent:Connect(function(player, targets, dir)
    if DEBUG then print("[PowerPunch] HitEvent from", player.Name) end
    if typeof(targets) ~= "table" then
        if DEBUG then print("[PowerPunch] Invalid targets") end
        return
    end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        if DEBUG then print("[PowerPunch] Missing humanoid or HRP") end
        return
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BasicCombat" then
        if DEBUG then print("[PowerPunch] Invalid tool during hit") end
        return
    end

    local hitLanded = false

    for _, enemyPlayer in ipairs(targets) do
        local enemyChar = enemyPlayer.Character
        local enemyHumanoid = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid then
            if DEBUG then print("[PowerPunch] Target has no humanoid") end
            continue
        end
        if EvasiveService.IsActive(enemyPlayer) then
            continue
        end
        if not StunService:CanBeHitBy(player, enemyPlayer) then
            if DEBUG then print("[PowerPunch] Cannot hit", enemyPlayer.Name) end
            continue
        end

        local blockResult
        if PowerPunchConfig.GuardBreak then
            if PowerPunchConfig.PerfectBlockable then
                local dmg = BlockService.GetBlockHP(enemyPlayer)
                blockResult = BlockService.ApplyBlockDamage(enemyPlayer, dmg, false, hrp)
            else
                blockResult = BlockService.ApplyBlockDamage(enemyPlayer, PowerPunchConfig.Damage, true, hrp)
            end
        else
            blockResult = BlockService.ApplyBlockDamage(enemyPlayer, PowerPunchConfig.Damage, false, hrp)
        end
        if blockResult == "Perfect" then
            if DEBUG then print("[PowerPunch] Perfect block by", enemyPlayer.Name) end
            stopAnimation(humanoid)
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), AnimationData.Stun.PerfectBlock, player)
            local soundId = SoundConfig.Blocking.PerfectBlock
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Damaged" then
            if DEBUG then print("[PowerPunch] Block damaged", enemyPlayer.Name) end
            continue
        elseif blockResult == "Broken" then
            if DEBUG then print("[PowerPunch] Block broken", enemyPlayer.Name) end
            BlockEvent:FireClient(enemyPlayer, false)

            -- Play block break sound
            local soundId = SoundConfig.Blocking.BlockBreak
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end

            -- Apply stun but skip the default animation so knockback anim plays
            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), true, player, true)

            -- Apply knockback even though the hit was blocked
            local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                if DEBUG then
                    print("[PowerPunch] Knockback params", PowerPunchConfig.KnockbackDirection)
                end
                RagdollKnockback.ApplyDirectionalKnockback(enemyHumanoid, {
                    DirectionType = PowerPunchConfig.KnockbackDirection or RagdollKnockback.DirectionType.AttackerFacingDirection,
                    AttackerRoot = hrp,
                    TargetRoot = enemyRoot,
                })
            end

            -- fallthrough to apply damage on block break
        end

        local dmg = PowerPunchConfig.Damage
        if HakiService.IsActive(player) then
            dmg *= 1.025
        end
        enemyHumanoid:TakeDamage(dmg)
        DamageText.Show(enemyHumanoid, dmg)
        PersistentStats.RecordHit(player, enemyHumanoid, dmg)
        UltService.RegisterHit(player, enemyHumanoid, UltConfig.Moves)
        XPService.RegisterHit(player, enemyHumanoid, XPConfig.Move)
        if DEBUG then print("[PowerPunch] Hit", enemyPlayer.Name, "for", dmg) end
        hitLanded = true
        HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent)

        StunService:ApplyStun(enemyHumanoid, PowerPunchConfig.StunDuration, false, player, true)
        if DEBUG then print("[PowerPunch] Applied stun to", enemyPlayer.Name) end

        local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            if DEBUG then
                print("[PowerPunch] Knockback params", PowerPunchConfig.KnockbackDirection)
            end
            RagdollKnockback.ApplyDirectionalKnockback(enemyHumanoid, {
                DirectionType = PowerPunchConfig.KnockbackDirection or RagdollKnockback.DirectionType.AttackerFacingDirection,
                AttackerRoot = hrp,
                TargetRoot = enemyRoot,
            })
        end
    end

    if hitLanded then
        local hitSfx = MoveSoundConfig.PowerPunch and MoveSoundConfig.PowerPunch.Hit
        if hitSfx then
            SoundUtils:PlaySpatialSound(hitSfx, hrp)
        end
        if DEBUG then print("[PowerPunch] Hit sequence complete") end
    end
end)

return nil
