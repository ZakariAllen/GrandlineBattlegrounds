local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("AntiMannerKickCourseStart")
local HitEvent = CombatRemotes:WaitForChild("AntiMannerKickCourseHit")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local MoveConfig = AbilityConfig.BlackLeg.AntiMannerKickCourse
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local DamageText = require(ReplicatedStorage.Modules.Effects.DamageText)
local MoveSoundConfig = require(ReplicatedStorage.Modules.Config.MoveSoundConfig)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local RagdollKnockback = require(ReplicatedStorage.Modules.Combat.RagdollKnockback)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local UltService = require(ReplicatedStorage.Modules.Stats.UltService)
local UltConfig = require(ReplicatedStorage.Modules.Config.UltConfig)
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
    if DEBUG then print("[AntiMannerKickCourse] StartEvent from", player.Name) end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        if DEBUG then print("[AntiMannerKickCourse] No humanoid") end
        return
    end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then
        if DEBUG then print("[AntiMannerKickCourse] Player stunned or locked") end
        return
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[AntiMannerKickCourse] Invalid tool") end
        return
    end
    if not UltService.ConsumeUlt(player) then
        if DEBUG then print("[AntiMannerKickCourse] Ult not full") end
        return
    end
    if not StaminaService.Consume(player, MoveConfig.StaminaCost or 0) then
        if DEBUG then print("[AntiMannerKickCourse] Not enough stamina") end
        return
    end
    playAnimation(humanoid, AnimationData.SpecialMoves.PowerKick)
    if DEBUG then print("[AntiMannerKickCourse] Animation triggered") end
end)

HitEvent.OnServerEvent:Connect(function(player, targets, dir)
    if DEBUG then print("[AntiMannerKickCourse] HitEvent from", player.Name) end
    if typeof(targets) ~= "table" then
        if DEBUG then print("[AntiMannerKickCourse] Invalid targets") end
        return
    end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        if DEBUG then print("[AntiMannerKickCourse] Missing humanoid or HRP") end
        return
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[AntiMannerKickCourse] Invalid tool during hit") end
        return
    end

    local hitLanded = false

    for _, enemyPlayer in ipairs(targets) do
        local enemyChar = enemyPlayer.Character
        local enemyHumanoid = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid then
            if DEBUG then print("[AntiMannerKickCourse] Target has no humanoid") end
            continue
        end
        if not StunService:CanBeHitBy(player, enemyPlayer) then
            if DEBUG then print("[AntiMannerKickCourse] Cannot hit", enemyPlayer.Name) end
            continue
        end

        local blockResult
        if MoveConfig.GuardBreak then
            if MoveConfig.PerfectBlockable then
                local dmg = BlockService.GetBlockHP(enemyPlayer)
                blockResult = BlockService.ApplyBlockDamage(enemyPlayer, dmg, false, hrp)
            else
                blockResult = BlockService.ApplyBlockDamage(enemyPlayer, MoveConfig.Damage, true, hrp)
            end
        else
            blockResult = BlockService.ApplyBlockDamage(enemyPlayer, MoveConfig.Damage, false, hrp)
        end
        if blockResult == "Perfect" then
            if DEBUG then print("[AntiMannerKickCourse] Perfect block by", enemyPlayer.Name) end
            stopAnimation(humanoid)
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), AnimationData.Stun.PerfectBlock, player)
            local soundId = SoundConfig.Blocking.PerfectBlock
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Damaged" then
            if DEBUG then print("[AntiMannerKickCourse] Block damaged", enemyPlayer.Name) end
            continue
        elseif blockResult == "Broken" then
            if DEBUG then print("[AntiMannerKickCourse] Block broken", enemyPlayer.Name) end
            BlockEvent:FireClient(enemyPlayer, false)

            local soundId = SoundConfig.Blocking.BlockBreak
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end

            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), true, player, true)
            -- fallthrough to apply damage on block break
        end

        local dmg = MoveConfig.Damage
        if HakiService.IsActive(player) then
            dmg *= 1.025
        end
        enemyHumanoid:TakeDamage(dmg)
        DamageText.Show(enemyHumanoid, dmg)
        UltService.RegisterHit(player, enemyHumanoid, UltConfig.Moves)
        if DEBUG then print("[AntiMannerKickCourse] Hit", enemyPlayer.Name, "for", dmg) end
        hitLanded = true
        HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent)

        StunService:ApplyStun(enemyHumanoid, MoveConfig.StunDuration, false, player, true)

        local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            local lift = math.sqrt(2 * workspace.Gravity * 50)
            RagdollKnockback.ApplyDirectionalKnockback(enemyHumanoid, {
                DirectionType = RagdollKnockback.DirectionType.AttackerFacingDirection,
                AttackerRoot = hrp,
                TargetRoot = enemyRoot,
                Force = 50,
                Duration = 0.6,
                Lift = lift,
            })
        end
    end

    if hitLanded then
        local hitSfx = MoveSoundConfig.AntiMannerKickCourse and MoveSoundConfig.AntiMannerKickCourse.Hit
        if hitSfx then
            SoundUtils:PlaySpatialSound(hitSfx, hrp)
        end
    end
end)

return nil
