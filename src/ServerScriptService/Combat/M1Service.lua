--[[
    Phase 2 M1Service
    Server authoritative processing for melee (M1) attacks. Handles both
    players and NPCs using ActorAdapter.  Target resolution happens on the
    server and damage is applied without trusting client hit lists.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)

local ActorAdapter = require(ReplicatedStorage.Modules.AI.ActorAdapter)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local RagdollKnockback = require(ReplicatedStorage.Modules.Combat.RagdollKnockback)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatFolder = Remotes:WaitForChild("Combat")
local BlockEvent = CombatFolder:WaitForChild("BlockEvent")
local BlockVFXEvent = CombatFolder:WaitForChild("BlockVFX")

local M1Service = {}

-- Track combo windows per character
local comboState = {} -- [character] = {step, lastTime, cooldownEnd}
M1Service.ComboTimestamps = comboState

-- Debounce table for hit confirms
local hitDebounce = {} -- [attackerChar][targetChar][comboIndex] = true

-- Utility --------------------------------------------------------------------

local function getStyleKey(tool)
    if tool and ToolConfig.ValidCombatTools[tool.Name] then
        return tool.Name
    end
    return "BasicCombat"
end

local function setDebounce(attacker, target, comboIndex)
    hitDebounce[attacker] = hitDebounce[attacker] or {}
    local aTable = hitDebounce[attacker]
    aTable[target] = aTable[target] or {}
    aTable[target][comboIndex] = true
    task.delay(0.5, function()
        local atk = hitDebounce[attacker]
        if atk and atk[target] then
            atk[target][comboIndex] = nil
            if next(atk[target]) == nil then
                atk[target] = nil
            end
        end
        if atk and next(atk) == nil then
            hitDebounce[attacker] = nil
        end
    end)
end

local function wasDebounced(attacker, target, comboIndex)
    local atk = hitDebounce[attacker]
    return atk and atk[target] and atk[target][comboIndex] or false
end

local function collectTargets(attackerChar, targetPlayers, originCF, size)
    local map = {}

    -- Targets supplied by clients (players or models)
    for _, entry in ipairs(targetPlayers) do
        local info = ActorAdapter.Get(entry)
        if info and info.Character and info.Humanoid and info.Humanoid.Health > 0 then
            if info.Character ~= attackerChar then
                map[info.Character] = info
            end
        end
    end

    -- Targets detected by server hitbox
    if originCF and size then
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {attackerChar}
        for _, part in ipairs(workspace:GetPartBoundsInBox(originCF, size, params)) do
            local info = ActorAdapter.Get(part)
            if info and info.Character ~= attackerChar and info.Humanoid and info.Humanoid.Health > 0 then
                map[info.Character] = info
            end
        end
    end

    return map
end

-- Public API -----------------------------------------------------------------

-- Validates combo windows and schedules a server cast of the M1 after the
-- configured hit delay.
function M1Service.ProcessM1Request(actor, payload)
    local comboIndex = typeof(payload) == "table" and (payload.step or payload[1]) or payload
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
    local char = info.Character
    if StunService:IsStunned(char) or StunService:IsAttackerLocked(char) then
        return
    end
    if BlockService.IsBlocking(char) or BlockService.IsInStartup(char) then
        return
    end

    local now = tick()
    comboState[char] = comboState[char] or {step = 0, lastTime = 0, cooldownEnd = 0}
    local state = comboState[char]

    if now < state.cooldownEnd then
        return
    end
    if now - state.lastTime > CombatConfig.M1.ComboResetTime then
        state.step = 0
    end
    if comboIndex ~= state.step + 1 then
        return
    end
    if now - state.lastTime < CombatConfig.M1.DelayBetweenHits then
        return
    end

    state.step = comboIndex
    state.lastTime = now
    if comboIndex == CombatConfig.M1.ComboHits then
        state.cooldownEnd = now + CombatConfig.M1.ComboCooldown
    end

    task.delay(CombatConfig.M1.HitDelay, function()
        M1Service.ServerCastM1(actor, comboIndex)
    end)
end

-- Server authoritative casting of the hitbox for NPCs or scheduled player hits
function M1Service.ServerCastM1(attackerActor, comboIndex)
    comboIndex = math.floor(comboIndex)
    if comboIndex < 1 or comboIndex > CombatConfig.M1.ComboHits then return end

    local info = ActorAdapter.Get(attackerActor)
    if not info or not info.Character or not info.Root then return end

    local hitbox = MoveHitboxConfig.M1
    local origin = info.Root.CFrame * (hitbox.Offset or CFrame.new())
    local size = hitbox.Size
    local isFinal = comboIndex == CombatConfig.M1.ComboHits

    M1Service.ProcessM1HitConfirm(attackerActor, {}, comboIndex, isFinal, origin, size, 0)
end

-- Applies damage based on confirmed hit data. Both player and NPC attackers are
-- supported. TargetPlayers is treated as a hint and unioned with server
-- detection from the hitbox.
function M1Service.ProcessM1HitConfirm(attacker, targetPlayers, comboIndex, isFinal, originCF, size, travelDistance)
    if typeof(comboIndex) ~= "number" then return end
    comboIndex = math.floor(comboIndex)
    if comboIndex < 1 or comboIndex > CombatConfig.M1.ComboHits then return end
    if typeof(targetPlayers) ~= "table" then targetPlayers = {} end

    local info = ActorAdapter.Get(attacker)
    if not info or not info.Character or not info.Humanoid then return end
    local attackerChar = info.Character
    local attackerHum = info.Humanoid
    local attackerRoot = info.Root

    travelDistance = typeof(travelDistance) == "number" and travelDistance or 0
    if typeof(originCF) ~= "CFrame" then originCF = attackerRoot and attackerRoot.CFrame or nil end
    if typeof(size) ~= "Vector3" then size = MoveHitboxConfig.M1.Size end
    if originCF and travelDistance ~= 0 then
        originCF = originCF + originCF.LookVector * travelDistance
    end

    local targets = collectTargets(attackerChar, targetPlayers, originCF, size)

    local styleKey = getStyleKey(attackerChar:FindFirstChildOfClass("Tool"))
    local damage = CombatConfig.M1.DefaultM1Damage
    if ToolConfig.ToolStats[styleKey] and ToolConfig.ToolStats[styleKey].M1Damage then
        damage = ToolConfig.ToolStats[styleKey].M1Damage
    end

    local finalHit = isFinal == true
    for character, tInfo in pairs(targets) do
        local hum = tInfo.Humanoid
        if hum and hum.Health > 0 and not wasDebounced(attackerChar, character, comboIndex) then
            setDebounce(attackerChar, character, comboIndex)
            if BlockService.IsBlocking(character) then
                local result = BlockService.ApplyBlockDamage(character, damage, false, attackerRoot)
                if result == "Broken" then
                    StunService:ApplyStun(hum, BlockService.GetBlockBreakStunDuration(), nil, attackerChar, nil, true)
                    if tInfo.Player then
                        BlockEvent:FireClient(tInfo.Player, false)
                    else
                        BlockVFXEvent:FireAllClients(character, false)
                    end
                elseif result == "Perfect" then
                    StunService:ApplyStun(attackerHum, BlockService.GetPerfectBlockStunDuration(), nil, character)
                end
            else
                hum:TakeDamage(damage)
                local stunDur = finalHit and CombatConfig.M1.M1_5StunDuration or CombatConfig.M1.M1StunDuration
                StunService:ApplyStun(hum, stunDur, nil, attackerChar)
                if finalHit or hum.Health <= 0 then
                    if attackerRoot and tInfo.Root then
                        RagdollKnockback.ApplyDirectionalKnockback(hum, {
                            DirectionType = RagdollKnockback.DirectionType.AttackerFacingDirection,
                            AttackerRoot = attackerRoot,
                            TargetRoot = tInfo.Root,
                        })
                    end
                end
            end
        end
    end
end

return M1Service

