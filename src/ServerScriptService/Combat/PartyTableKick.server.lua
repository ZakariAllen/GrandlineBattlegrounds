local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PartyTableKickStart")
local HitEvent = CombatRemotes:WaitForChild("PartyTableKickHit")
local StopEvent = CombatRemotes:WaitForChild("PartyTableKickStop")
local VFXEvent = CombatRemotes:WaitForChild("PartyTableKickVFX")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local PartyTableKickConfig = AbilityConfig.BlackLeg.PartyTableKick
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local EvasiveService = require(ReplicatedStorage.Modules.Stats.EvasiveService)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local UltService = require(ReplicatedStorage.Modules.Stats.UltService)
local UltConfig = require(ReplicatedStorage.Modules.Config.UltConfig)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local DamageText = require(ReplicatedStorage.Modules.Effects.DamageText)
local MoveSoundConfig = require(ReplicatedStorage.Modules.Config.MoveSoundConfig)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local RagdollKnockback = require(ReplicatedStorage.Modules.Combat.RagdollKnockback)
local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

local activeTracks = {}
local activeLoopSounds = {}
local activeDrain = {}

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
    if DEBUG then print("[PartyTableKick] StartEvent from", player.Name) end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        if DEBUG then print("[PartyTableKick] No humanoid") end
        return
    end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then
        if DEBUG then print("[PartyTableKick] Player stunned or locked") end
        return
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[PartyTableKick] Invalid tool") end
        return
    end
    if not StaminaService.Consume(player, 10) then
        if DEBUG then print("[PartyTableKick] Not enough stamina") end
        return
    end
    StaminaService.PauseRegen(player)
    activeDrain[player] = tick()
    playAnimation(humanoid, AnimationData.SpecialMoves.PartyTableKick)
    if DEBUG then print("[PartyTableKick] Animation triggered") end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local loopId = MoveSoundConfig.PartyTableKick and MoveSoundConfig.PartyTableKick.Loop
    if hrp and loopId then
        local sound = SoundUtils:PlayLoopingSpatialSound(loopId, hrp)
        activeLoopSounds[player] = sound
    end
    VFXEvent:FireAllClients(player)
end)

HitEvent.OnServerEvent:Connect(function(player, targets, isFinal)
    if DEBUG then print("[PartyTableKick] HitEvent from", player.Name) end
    if typeof(targets) ~= "table" then
        if DEBUG then print("[PartyTableKick] Invalid targets") end
        return
    end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        if DEBUG then print("[PartyTableKick] Missing humanoid or HRP") end
        return
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[PartyTableKick] Invalid tool during hit") end
        return
    end

    local cfg = PartyTableKickConfig
    local hitLanded = false
    local blockHit = false

    for _, enemyPlayer in ipairs(targets) do
        local enemyChar = enemyPlayer.Character
        local enemyHumanoid = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid then
            if DEBUG then print("[PartyTableKick] Target has no humanoid") end
            continue
        end
        if EvasiveService.IsActive(enemyPlayer) then
            continue
        end
        if not StunService:CanBeHitBy(player, enemyPlayer) then
            if DEBUG then print("[PartyTableKick] Cannot hit", enemyPlayer.Name) end
            continue
        end

        local blockResult = BlockService.ApplyBlockDamage(enemyPlayer, cfg.DamagePerHit, false, hrp)
        if blockResult == "Perfect" then
            if DEBUG then print("[PartyTableKick] Perfect block by", enemyPlayer.Name) end
            blockHit = true
            stopAnimation(humanoid)
            local soundInst = activeLoopSounds[player]
            if soundInst then
                soundInst:Destroy()
                activeLoopSounds[player] = nil
            end
            activeDrain[player] = nil
            StaminaService.ResumeRegen(player)
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), false, player)
            playAnimation(humanoid, AnimationData.Stun.PerfectBlock)
            local soundId = SoundConfig.Blocking.PerfectBlock
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Damaged" then
            if DEBUG then print("[PartyTableKick] Block damaged", enemyPlayer.Name) end
            blockHit = true
            local soundId = SoundConfig.Blocking.Block
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Broken" then
            if DEBUG then print("[PartyTableKick] Block broken", enemyPlayer.Name) end
            blockHit = true
            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), false, player)
            BlockEvent:FireClient(enemyPlayer, false)
            local soundId = SoundConfig.Blocking.BlockBreak
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            -- fallthrough to apply damage on block break
        end

        local dmg = cfg.DamagePerHit
        if HakiService.IsActive(player) then
            dmg *= 1.025
        end
        enemyHumanoid:TakeDamage(dmg)
        DamageText.Show(enemyHumanoid, dmg)
        UltService.RegisterHit(player, enemyHumanoid, UltConfig.Moves)
        hitLanded = true
        if DEBUG then print("[PartyTableKick] Hit", enemyPlayer.Name) end
        local stunDur = isFinal and CombatConfig.M1.M1_5StunDuration or cfg.StunDuration
        StunService:ApplyStun(enemyHumanoid, stunDur, isFinal, player, isFinal)

        if isFinal then
            if DEBUG then print("[PartyTableKick] Final hit on", enemyPlayer.Name) end
            local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                RagdollKnockback.ApplyDirectionalKnockback(enemyHumanoid, {
                    DirectionType = PartyTableKickConfig.KnockbackDirection or RagdollKnockback.DirectionType.AttackerFacingDirection,
                    AttackerRoot = hrp,
                    TargetRoot = enemyRoot,
                })
            end
        end

        local hitSfx = MoveSoundConfig.PartyTableKick and MoveSoundConfig.PartyTableKick.Hit
        if hitSfx then
            SoundUtils:PlaySpatialSound(hitSfx, hrp)
        end
        HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent)
    end
    if not hitLanded and not blockHit then
        local missSfx = MoveSoundConfig.PartyTableKick and MoveSoundConfig.PartyTableKick.Miss
        if missSfx then
            SoundUtils:PlaySpatialSound(missSfx, hrp)
        end
    end
    if DEBUG then print("[PartyTableKick] Hit sequence complete") end
end)

StopEvent.OnServerEvent:Connect(function(player)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        stopAnimation(humanoid)
        if DEBUG then print("[PartyTableKick] Animation stopped for", player.Name) end
    end
    local sound = activeLoopSounds[player]
    if sound then
        sound:Destroy()
        activeLoopSounds[player] = nil
    end
    activeDrain[player] = nil
    StaminaService.ResumeRegen(player)
end)

RunService.Heartbeat:Connect(function(dt)
    for player, last in pairs(activeDrain) do
        StaminaService.Consume(player, 3 * dt)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    activeDrain[player] = nil
    StaminaService.ResumeRegen(player)
end)
