local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local combatFolder = ReplicatedStorage:WaitForChild("Combat")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local combatRemote = remotesFolder:FindFirstChild("Combat")
if not combatRemote then
    combatRemote = Instance.new("RemoteEvent")
    combatRemote.Name = "Combat"
    combatRemote.Parent = remotesFolder
end

local configFolder = ReplicatedStorage:WaitForChild("Config")

local CombatConfig = require(configFolder:WaitForChild("Combat"))
local CharacterState = require(combatFolder:WaitForChild("CharacterState"))
local DamageCalculator = require(combatFolder:WaitForChild("DamageCalculator"))

local CombatService = {}

local statesByCharacter = {}
local statesByHumanoid = {}
local connections = {}

local function getPlayerFromCharacter(character)
    if not character then
        return nil
    end

    return Players:GetPlayerFromCharacter(character)
end

local function sendStateUpdate(state)
    if not state then
        return
    end

    local character = state:GetCharacter()
    local player = getPlayerFromCharacter(character)
    if not player then
        return
    end

    combatRemote:FireClient(player, "StateUpdate", state:GetPublicState())
end

local function sendFeedback(character, feedbackType, payload)
    payload = payload or {}

    local player = getPlayerFromCharacter(character)
    if not player then
        return
    end

    combatRemote:FireClient(player, "Feedback", {
        Type = feedbackType,
        Data = payload,
    })
end

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

    sendStateUpdate(state)

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
    local range = CombatConfig.Range[attackType]
    if not range then
        range = CombatConfig.Range.Default or CombatConfig.Range.Light or 10
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

    local attackTime = os.clock()
    local comboIndex = attackerState:GetNextComboIndex(attackTime)
    metadata.ComboIndex = comboIndex
    metadata.ComboMultiplier = attackerState:GetComboMultiplier(comboIndex)

    local blocked = defenderState:IsBlocking()
    local perfectBlock = blocked and defenderState:IsPerfectBlock(attackTime)
    metadata.PerfectBlock = perfectBlock

    local damage = DamageCalculator.Calculate(attackerState, defenderState, attackType, metadata)
    if damage <= 0 and not perfectBlock and not blocked then
        return false, "NoDamage"
    end

    attackerState:RecordAttack(attackType, attackTime, comboIndex)
    if damage > 0 then
        defenderState:ApplyDamage(damage)
    end

    local guardBroken = false
    if blocked then
        guardBroken = defenderState:HandleBlockedHit(damage, perfectBlock)
    end

    if perfectBlock then
        if CombatConfig.Block.PerfectCounterDamage and CombatConfig.Block.PerfectCounterDamage > 0 then
            attackerState:ApplyDamage(CombatConfig.Block.PerfectCounterDamage)
            if attackerState:ConsumeDirtyFlag() then
                sendStateUpdate(attackerState)
            end
        end
        sendFeedback(targetCharacter, "PerfectBlock", {
            AttackType = attackType,
            ComboIndex = comboIndex,
        })
    end

    if guardBroken then
        sendFeedback(targetCharacter, "GuardBreak", {
            Cooldown = CombatConfig.Block.GuardBreakCooldown,
        })

        sendFeedback(attackerCharacter, "GuardBreakInflicted", {
            Target = targetCharacter,
        })
    elseif blocked and not perfectBlock then
        sendFeedback(targetCharacter, "BlockedHit", {
            Damage = damage,
            AttackType = attackType,
        })
    end

    if attackerState:ConsumeDirtyFlag() then
        sendStateUpdate(attackerState)
    end

    if defenderState:ConsumeDirtyFlag() then
        sendStateUpdate(defenderState)
    end

    return true, {
        Damage = damage,
        Blocked = blocked,
        PerfectBlock = perfectBlock,
        GuardBreak = guardBroken,
        ComboIndex = comboIndex,
    }
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

    processAttack(character, attackType, targetCharacter)
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

    local desiredState = payload.IsBlocking
    if desiredState == true then
        if state:SetBlocking(true) then
            -- already handled
        else
            sendStateUpdate(state)
        end
    elseif desiredState == false then
        state:SetBlocking(false)
    end

    if state:ConsumeDirtyFlag() then
        sendStateUpdate(state)
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
                if state:ConsumeDirtyFlag() then
                    sendStateUpdate(state)
                end
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
