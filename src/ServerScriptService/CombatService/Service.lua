local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local combatFolder = ReplicatedStorage:WaitForChild("Combat")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotesFolder:WaitForChild("Combat")

local CombatConstants = require(combatFolder:WaitForChild("CombatConstants"))
local CharacterState = require(combatFolder:WaitForChild("CharacterState"))
local DamageCalculator = require(combatFolder:WaitForChild("DamageCalculator"))

local CombatService = {}

local statesByCharacter = {}
local statesByHumanoid = {}
local connections = {}

local function cleanupState(character)
    local state = statesByCharacter[character]
    if not state then
        return
    end

    statesByCharacter[character] = nil

    local humanoid = state:GetHumanoid()
    if humanoid then
        statesByHumanoid[humanoid] = nil
    end

    state:Destroy()
end

local function trackState(state)
    local character = state:GetCharacter()
    if not character then
        return
    end

    local humanoid = state:GetHumanoid()

    local ancestryConn
    ancestryConn = character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanupState(character)
            if ancestryConn.Connected then
                ancestryConn:Disconnect()
            end
        end
    end)
    table.insert(state.Connections, ancestryConn)

    if humanoid then
        local humanoidConn
        humanoidConn = humanoid.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanupState(character)
                if humanoidConn.Connected then
                    humanoidConn:Disconnect()
                end
            end
        end)
        table.insert(state.Connections, humanoidConn)
    end
end

function CombatService.GetStateFromCharacter(character)
    return statesByCharacter[character]
end

function CombatService.GetStateFromHumanoid(humanoid)
    return statesByHumanoid[humanoid]
end

function CombatService.GetOrCreateState(character)
    if typeof(character) ~= "Instance" or not character:IsA("Model") then
        return nil
    end

    local state = statesByCharacter[character]
    if state and not state.Destroyed then
        return state
    end

    state = CharacterState.new(character)
    if not state then
        return nil
    end

    statesByCharacter[character] = state
    statesByHumanoid[state:GetHumanoid()] = state

    trackState(state)

    return state
end

local function resolveCharacterFromInstance(instance)
    if typeof(instance) ~= "Instance" then
        return nil
    end

    if instance:IsA("Model") then
        if instance:FindFirstChildOfClass("Humanoid") then
            return instance
        end
    end

    if instance:IsA("Humanoid") then
        return instance.Parent
    end

    local parent = instance.Parent
    while parent do
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
            return parent
        end
        parent = parent.Parent
    end

    return nil
end

local function isInRange(attackerState, defenderState, attackType)
    local range = CombatConstants.RANGE[attackType]
    if not range then
        range = CombatConstants.RANGE.Light or 10
    end

    local attackerRoot = attackerState and attackerState:GetRootPart()
    local defenderRoot = defenderState and defenderState:GetRootPart()

    if not attackerRoot or not defenderRoot then
        return false
    end

    local distance = (attackerRoot.Position - defenderRoot.Position).Magnitude
    return distance <= range
end

local function processAttack(attackerCharacter, attackType, targetCharacter, metadata)
    metadata = metadata or {}

    local attackerState = CombatService.GetOrCreateState(attackerCharacter)
    if not attackerState then
        return false, "NoAttacker"
    end

    local canAttack, reason = attackerState:CanAttack(attackType)
    if not canAttack then
        return false, reason
    end

    local defenderState = CombatService.GetOrCreateState(targetCharacter)
    if not defenderState or not defenderState:IsAlive() then
        return false, "InvalidTarget"
    end

    if not isInRange(attackerState, defenderState, attackType) then
        return false, "OutOfRange"
    end

    local damage = DamageCalculator.Calculate(attackerState, defenderState, attackType, metadata)
    if damage <= 0 then
        return false, "NoDamage"
    end

    attackerState:RecordAttack(attackType)
    defenderState:ApplyDamage(damage)

    return true
end

local function handlePlayerAttack(player, payload)
    payload = payload or {}
    local character = player.Character
    if not character then
        return
    end

    local attackType = payload.AttackType or "Light"
    local targetInstance = payload.Target
    local targetCharacter = resolveCharacterFromInstance(targetInstance)
    if not targetCharacter then
        return
    end

    processAttack(character, attackType, targetCharacter, payload.Metadata)
end

local function handlePlayerBlock(player, payload)
    payload = payload or {}
    local character = player.Character
    if not character then
        return
    end

    local state = CombatService.GetOrCreateState(character)
    if not state then
        return
    end

    if payload.IsBlocking == true then
        state:SetBlocking(true)
    elseif payload.IsBlocking == false then
        state:SetBlocking(false)
    end
end

local function onRemoteEvent(player, action, payload)
    if action == "Attack" then
        handlePlayerAttack(player, payload)
    elseif action == "Block" then
        handlePlayerBlock(player, payload)
    end
end

local function onPlayerAdded(player)
    local function onCharacterAdded(character)
        CombatService.GetOrCreateState(character)
    end

    table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))

    if player.Character then
        onCharacterAdded(player.Character)
    end
end

local function onPlayerRemoving(player)
    local character = player.Character
    if character then
        cleanupState(character)
    end
end

function CombatService.Start()
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
    table.insert(connections, Players.PlayerRemoving:Connect(onPlayerRemoving))

    table.insert(connections, combatRemote.OnServerEvent:Connect(onRemoteEvent))

    table.insert(connections, RunService.Heartbeat:Connect(function(dt)
        for character, state in pairs(statesByCharacter) do
            if state.Destroyed or not state:IsAlive() then
                cleanupState(character)
            else
                state:RegenerateStamina(dt)
            end
        end
    end))
end

function CombatService.ProcessAttack(attackerCharacter, targetCharacter, attackType, metadata)
    attackType = attackType or "Light"
    return processAttack(attackerCharacter, attackType, targetCharacter, metadata)
end

function CombatService.Cleanup()
    for character in pairs(statesByCharacter) do
        cleanupState(character)
    end

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end

return CombatService
