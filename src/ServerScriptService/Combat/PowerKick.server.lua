local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PowerKickStart")
local HitEvent = CombatRemotes:WaitForChild("PowerKickHit")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local PowerKickConfig = AbilityConfig.BlackLeg.PowerKick
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local DamageText = require(ReplicatedStorage.Modules.Effects.DamageText)
local MoveSoundConfig = require(ReplicatedStorage.Modules.Config.MoveSoundConfig)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

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
    if DEBUG then print("[PowerKick] StartEvent from", player.Name) end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        if DEBUG then print("[PowerKick] No humanoid") end
        return
    end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then
        if DEBUG then print("[PowerKick] Player stunned or locked") end
        return
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[PowerKick] Invalid tool") end
        return
    end
    if not StaminaService.Consume(player, 20) then
        if DEBUG then print("[PowerKick] Not enough stamina") end
        return
    end
    playAnimation(humanoid, AnimationData.SpecialMoves.PowerKick)
    if DEBUG then print("[PowerKick] Animation triggered") end
end)

HitEvent.OnServerEvent:Connect(function(player, targets, dir)
    if DEBUG then print("[PowerKick] HitEvent from", player.Name) end
    if typeof(targets) ~= "table" then
        if DEBUG then print("[PowerKick] Invalid targets") end
        return
    end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        if DEBUG then print("[PowerKick] Missing humanoid or HRP") end
        return
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[PowerKick] Invalid tool during hit") end
        return
    end

    local hitLanded = false

    for _, enemyPlayer in ipairs(targets) do
        local enemyChar = enemyPlayer.Character
        local enemyHumanoid = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid then
            if DEBUG then print("[PowerKick] Target has no humanoid") end
            continue
        end
        if not StunService:CanBeHitBy(player, enemyPlayer) then
            if DEBUG then print("[PowerKick] Cannot hit", enemyPlayer.Name) end
            continue
        end

        local blockResult
        if PowerKickConfig.GuardBreak then
            if PowerKickConfig.PerfectBlockable then
                local dmg = BlockService.GetBlockHP(enemyPlayer)
                blockResult = BlockService.ApplyBlockDamage(enemyPlayer, dmg, false)
            else
                blockResult = BlockService.ApplyBlockDamage(enemyPlayer, PowerKickConfig.Damage, true)
            end
        else
            blockResult = BlockService.ApplyBlockDamage(enemyPlayer, PowerKickConfig.Damage, false)
        end
        if blockResult == "Perfect" then
            if DEBUG then print("[PowerKick] Perfect block by", enemyPlayer.Name) end
            stopAnimation(humanoid)
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), AnimationData.Stun.PerfectBlock, player)
            local soundId = SoundConfig.Blocking.PerfectBlock
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Damaged" then
            if DEBUG then print("[PowerKick] Block damaged", enemyPlayer.Name) end
            continue
        elseif blockResult == "Broken" then
            if DEBUG then print("[PowerKick] Block broken", enemyPlayer.Name) end
            BlockEvent:FireClient(enemyPlayer, false)

            local soundId = SoundConfig.Blocking.BlockBreak
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end

            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), true, player, true)

            -- No knockback on block break for PowerKick
            local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                -- reserved for potential future effects
            end

            -- fallthrough to apply damage on block break
        end

        enemyHumanoid:TakeDamage(PowerKickConfig.Damage)
        DamageText.Show(enemyHumanoid, PowerKickConfig.Damage)
        if DEBUG then print("[PowerKick] Hit", enemyPlayer.Name, "for", PowerKickConfig.Damage) end
        hitLanded = true
        HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent)

        StunService:ApplyStun(enemyHumanoid, PowerKickConfig.StunDuration, false, player, true)

        local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            -- PowerKick does not apply knockback on hit
        end
    end

    if hitLanded then
        local hitSfx = MoveSoundConfig.PowerKick and MoveSoundConfig.PowerKick.Hit
        if hitSfx then
            SoundUtils:PlaySpatialSound(hitSfx, hrp)
        end
    end
end)

return nil
