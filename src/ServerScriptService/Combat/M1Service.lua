--[[
    M1Service.lua
    Shared helper for processing melee (M1) requests from both players and NPCs.
    Extracted from CombatService so that NPCs can reuse the exact same logic.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)

local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local AnimationUtils = require(ReplicatedStorage.Modules.Effects.AnimationUtils)
local ActorAdapter = require(ReplicatedStorage.Modules.AI.ActorAdapter)
local DamageText = require(ReplicatedStorage.Modules.Effects.DamageText)
local EvasiveService = require(ReplicatedStorage.Modules.Stats.EvasiveService)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local RagdollKnockback = require(ReplicatedStorage.Modules.Combat.RagdollKnockback)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local UltService = require(ReplicatedStorage.Modules.Stats.UltService)
local UltConfig = require(ReplicatedStorage.Modules.Config.UltConfig)
local XPService = require(ReplicatedStorage.Modules.Stats.ExperienceService)
local XPConfig = require(ReplicatedStorage.Modules.Config.XPConfig)
local PersistentStats = require(ReplicatedStorage.Modules.Stats.PersistentStatsService)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")
local BlockVFXEvent = CombatRemotes:WaitForChild("BlockVFX")

-- Utility functions ---------------------------------------------------------

local function ShouldApplyHit(attackerKey, defenderKey)
    if StunService:WasRecentlyHit(defenderKey) then
        return false
    end

    local atk = comboTimestamps[attackerKey]
    local def = comboTimestamps[defenderKey]
    if atk and def then
        local diff = atk.LastClick - def.LastClick
        if diff > 0 and math.abs(diff) <= CombatConfig.M1.ClashWindow then
            if StunService:WasRecentlyHit(attackerKey) then
                return false
            end
        end
    end
    return true
end

local function resolveTarget(entry)
    if typeof(entry) ~= "Instance" then return nil end
    if entry:IsA("Player") then
        local char = entry.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            return {Key = entry, Player = entry, Humanoid = hum}
        end
        return nil
    end
    local model = entry:IsA("Model") and entry or entry:FindFirstAncestorOfClass("Model")
    if model then
        local player = Players:GetPlayerFromCharacter(model)
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum then
            return {Key = player or hum, Player = player, Humanoid = hum}
        end
    end
    return nil
end

local function sanitizeTargets(list)
    local cleaned = {}
    local added = {}
    for _, entry in ipairs(list) do
        local target = resolveTarget(entry)
        if target and not added[target.Key] then
            added[target.Key] = true
            table.insert(cleaned, target)
        end
    end
    return cleaned
end

local M1Service = {}
local comboTimestamps = {}
M1Service.ComboTimestamps = comboTimestamps

local function getStyleKeyFromTool(tool)
    if tool and ToolConfig.ValidCombatTools[tool.Name] then
        return tool.Name
    end
    return "BasicCombat"
end

local function playAnimation(humanoid, animId)
    if not animId or not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    AnimationUtils.PlayAnimation(animator, animId)
end

-- Processes an M1 request exactly as the RemoteEvent handler would
-- @param player Player-like object (must have Character)
-- @param payload table from client containing combo step and aim info
function M1Service.ProcessM1Request(actor, payload)
    local comboIndex
    if typeof(payload) == "table" then
        comboIndex = payload.step or payload[1]
    else
        comboIndex = payload
    end
    if typeof(comboIndex) ~= "number" then
        return
    end
    comboIndex = math.floor(comboIndex)
    if comboIndex < 1 or comboIndex > CombatConfig.M1.ComboHits then
        return
    end

    local info = ActorAdapter.Get(actor)
    if not info or not info.Character or not info.Humanoid then
        return
    end
    local key = info.Key
    if StunService:IsStunned(key) or StunService:IsAttackerLocked(key) then
        return
    end
    if BlockService.IsBlocking(key) or BlockService.IsInStartup(key) then
        return
    end

    local now = tick()
    comboTimestamps[key] = comboTimestamps[key] or { LastClick = 0, CooldownEnd = 0 }
    local state = comboTimestamps[key]

    if now < state.CooldownEnd then
        return
    end
    state.LastClick = now
    if comboIndex == CombatConfig.M1.ComboHits then
        state.CooldownEnd = now + CombatConfig.M1.ComboCooldown
    end

    local tool = info.Character:FindFirstChildOfClass("Tool")
    local styleKey = getStyleKeyFromTool(tool)
    local animSet = AnimationData.M1[styleKey]
    local animId = animSet and animSet.Combo and animSet.Combo[comboIndex]
    if animId then
        playAnimation(info.Humanoid, animId)
    end
end

-- Processes confirmed hits from client or server casts ----------------------
function M1Service.ProcessM1HitConfirm(attacker, targetPlayers, comboIndex, isFinal, originCF, size, travelDistance)
    if typeof(comboIndex) ~= "number" then return end
    comboIndex = math.floor(comboIndex)
    if comboIndex < 1 or comboIndex > CombatConfig.M1.ComboHits then return end

    if typeof(targetPlayers) ~= "table" then
        targetPlayers = {}
    end

    local info = ActorAdapter.Get(attacker)
    if not info or not info.Character or not info.Humanoid then return end
    local char = info.Character
    local humanoid = info.Humanoid
    local hrp = ActorAdapter.GetRoot(attacker)
    if not hrp then return end

    travelDistance = (typeof(travelDistance) == "number") and travelDistance or 0
    if typeof(originCF) ~= "CFrame" then originCF = nil end
    if typeof(size) ~= "Vector3" then size = nil end

    local serverTargets = sanitizeTargets(targetPlayers)
    if originCF and size then
        local castCF = originCF
        if travelDistance ~= 0 then
            castCF = castCF + castCF.LookVector * travelDistance
        end
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        serverTargets = {}
        local added = {}
        for _, part in ipairs(workspace:GetPartBoundsInBox(castCF, size, params)) do
            local target = resolveTarget(part)
            if target and target.Key ~= info.Key and not added[target.Key] then
                added[target.Key] = true
                table.insert(serverTargets, target)
            end
        end
    end

    local tool = char:FindFirstChildOfClass("Tool")
    local styleKey = getStyleKeyFromTool(tool)
    local damage = ToolConfig.ToolStats[styleKey] and ToolConfig.ToolStats[styleKey].M1Damage or CombatConfig.M1.DefaultM1Damage
    if info.IsPlayer and HakiService.IsActive(info.Player) then
        damage *= 1.025
    end

    local hitLanded = false
    local blockHit = false
    local maxRange = CombatConfig.M1.ServerHitRange or 12
    local attackPos
    if originCF then
        attackPos = originCF.Position
        if travelDistance ~= 0 then
            attackPos = attackPos + originCF.LookVector * travelDistance
        end
    end

    for _, target in ipairs(serverTargets) do
        local enemyPlayer = target.Player
        local enemyHumanoid = target.Humanoid
        if not enemyHumanoid or enemyHumanoid.Health <= 0 then continue end
        if enemyPlayer and EvasiveService and EvasiveService.IsActive(enemyPlayer) then
            continue
        end
        if not StunService:CanBeHitBy(info.Key, target.Key) then continue end
        if not ShouldApplyHit(info.Key, target.Key) then continue end

        local enemyRoot = enemyHumanoid.Parent and enemyHumanoid.Parent:FindFirstChild("HumanoidRootPart")
        if not enemyRoot then continue end

        local distOrigin = hrp.Position
        if attackPos then
            distOrigin = attackPos
        end
        if (enemyRoot.Position - distOrigin).Magnitude > maxRange then
            continue
        end

        local blockResult = BlockService.ApplyBlockDamage(target.Key, damage, false, hrp)
        if blockResult == "Perfect" then
            blockHit = true
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), AnimationData.Stun.PerfectBlock, info.Key)
            local soundId = SoundConfig.Blocking.PerfectBlock
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Damaged" then
            blockHit = true
            local soundId = SoundConfig.Blocking.Block
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Broken" then
            blockHit = true
            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), AnimationData.Stun.BlockBreak, info.Key)
            if enemyPlayer then
                BlockEvent:FireClient(enemyPlayer, false)
            elseif BlockVFXEvent then
                BlockVFXEvent:FireAllClients(enemyHumanoid.Parent, false)
            end
            local soundId = SoundConfig.Blocking.BlockBreak
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            -- fallthrough to apply damage on block break
        end

        enemyHumanoid:TakeDamage(damage)
        DamageText.Show(enemyHumanoid, damage)
        if info.Player then
            PersistentStats.RecordHit(info.Player, enemyHumanoid, damage)
            UltService.RegisterHit(info.Player, enemyHumanoid, UltConfig.M1s)
            XPService.RegisterHit(info.Player, enemyHumanoid, XPConfig.M1)
        end
        hitLanded = true

        local stunDuration = isFinal and CombatConfig.M1.M1_5StunDuration or CombatConfig.M1.M1StunDuration
        local preserve = isFinal and 0.5 or false
        StunService:ApplyStun(enemyHumanoid, stunDuration, isFinal, info.Key, preserve)

        local enemyDied = enemyHumanoid.Health <= 0
        if (isFinal or enemyDied) and enemyRoot then
            RagdollKnockback.ApplyDirectionalKnockback(enemyHumanoid, {
                DirectionType = RagdollKnockback.DirectionType.AttackerFacingDirection,
                AttackerRoot = hrp,
                TargetRoot = enemyRoot,
            })
        end

        task.delay(CombatConfig.M1.HitSoundDelay, function()
            local hitSfx = SoundConfig.Combat[styleKey] and SoundConfig.Combat[styleKey].Hit
            if hitSfx then
                SoundUtils:PlaySpatialSound(hitSfx, hrp)
            end
            HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent, Config.HitEffect.Duration)
        end)
    end

    if not hitLanded and not blockHit then
        task.delay(CombatConfig.M1.MissSoundDelay, function()
            local missSfx = SoundConfig.Combat[styleKey] and SoundConfig.Combat[styleKey].Miss
            if missSfx then
                SoundUtils:PlaySpatialSound(missSfx, hrp)
            end
        end)
    end
end

-- Server-side casting for NPC attackers ------------------------------------
function M1Service.ServerCastM1(attackerActor, comboIndex)
    comboIndex = math.floor(comboIndex)
    if comboIndex < 1 or comboIndex > CombatConfig.M1.ComboHits then return end

    local char = ActorAdapter.GetCharacter(attackerActor)
    local hrp = ActorAdapter.GetRoot(attackerActor)
    if not char or not hrp then return end

    local styleKey = ActorAdapter.GetStyleKey(attackerActor)
    local hitbox = MoveHitboxConfig.M1
    local originCF = hrp.CFrame * (hitbox.Offset or CFrame.new())
    local size = hitbox.Size
    local isFinal = comboIndex == CombatConfig.M1.ComboHits
    M1Service.ProcessM1HitConfirm(attackerActor, {}, comboIndex, isFinal, originCF, size, 0)
end

return M1Service
