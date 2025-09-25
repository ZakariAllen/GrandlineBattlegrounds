local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local combatFolder = ReplicatedStorage:WaitForChild("Combat")
local CombatConstants = require(combatFolder:WaitForChild("CombatConstants"))
local CombatService = require(script.Parent:WaitForChild("CombatService"):WaitForChild("Service"))

local NPCService = {}

local npcs = {}

local function createNPCModel(position)
    local model = Instance.new("Model")
    model.Name = "CombatNPC"

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 5, 2)
    root.CFrame = CFrame.new(position)
    root.Anchored = false
    root.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 2)
    head.CFrame = root.CFrame * CFrame.new(0, 3, 0)
    head.Anchored = false
    head.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = head
    weld.Parent = root

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.MaxHealth = 150
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = 14
    humanoid.JumpPower = 0
    humanoid.Parent = model

    model.PrimaryPart = root
    model:SetAttribute("IsNPC", true)
    model.Parent = Workspace

    return model, humanoid
end

local function findTarget(position)
    local closestCharacter
    local closestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local state = CombatService.GetOrCreateState(character)
        if state and state:IsAlive() then
            local rootPart = state:GetRootPart()
            if rootPart then
                local distance = (rootPart.Position - position).Magnitude
                if distance < closestDistance and distance <= CombatConstants.NPC_DETECTION_RADIUS then
                    closestCharacter = character
                    closestDistance = distance
                end
            end
        end
    end

    return closestCharacter
end

function NPCService.SpawnNPC(position)
    local model, humanoid = createNPCModel(position)
    local state = CombatService.GetOrCreateState(model)
    if not state then
        model:Destroy()
        return nil
    end

    local npcData = {
        Model = model,
        Humanoid = humanoid,
        NextAttack = CombatConstants.NPC_ATTACK_INTERVAL,
        Target = nil,
    }

    npcs[model] = npcData

    humanoid.Died:Connect(function()
        npcs[model] = nil
    end)

    return model
end

local function updateNPC(npcData, dt)
    local model = npcData.Model
    local state = CombatService.GetOrCreateState(model)
    if not state or state.Destroyed or not state:IsAlive() then
        npcs[model] = nil
        return
    end

    local rootPart = state:GetRootPart()
    if not rootPart then
        return
    end

    if not npcData.Target or not CombatService.GetOrCreateState(npcData.Target) then
        npcData.Target = findTarget(rootPart.Position)
    end

    local targetCharacter = npcData.Target
    if not targetCharacter then
        return
    end

    local targetState = CombatService.GetOrCreateState(targetCharacter)
    if not targetState or not targetState:IsAlive() then
        npcData.Target = nil
        return
    end

    local targetRoot = targetState:GetRootPart()
    if not targetRoot then
        npcData.Target = nil
        return
    end

    local distance = (targetRoot.Position - rootPart.Position).Magnitude

    if distance > CombatConstants.RANGE.Light then
        npcData.Humanoid:MoveTo(targetRoot.Position)
    else
        npcData.Humanoid:Move(Vector3.zero, true)
    end

    npcData.NextAttack -= dt
    if npcData.NextAttack <= 0 then
        local success = CombatService.ProcessAttack(model, targetCharacter, "Light")
        if success then
            npcData.NextAttack = CombatConstants.NPC_ATTACK_INTERVAL
        else
            npcData.NextAttack = 0.5
        end
    end
end

local spawnPositions = {
    Vector3.new(0, 5, 0),
    Vector3.new(12, 5, 8),
    Vector3.new(-14, 5, -6),
}

for _, position in ipairs(spawnPositions) do
    NPCService.SpawnNPC(position)
end

RunService.Heartbeat:Connect(function(dt)
    for _, npcData in pairs(npcs) do
        updateNPC(npcData, dt)
    end
end)

return NPCService
