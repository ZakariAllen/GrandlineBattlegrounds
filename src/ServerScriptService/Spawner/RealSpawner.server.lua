-- ServerScriptService > RealSpawner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HealthService = require(ReplicatedStorage.Modules.Stats.HealthService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)

-- ✅ Updated remote path
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SystemRemotes = Remotes:WaitForChild("System")
local SpawnRequestEvent = SystemRemotes:WaitForChild("SpawnRequestEvent")

local TOOLS_FOLDER = ReplicatedStorage:WaitForChild("Tools")
local hasSpawned = require(script.Parent:WaitForChild("SpawnRegistry"))

-- Cache spawn points so we do not traverse the map on every spawn
local spawnPoints = {}

local function refreshSpawnPoints()
    table.clear(spawnPoints)

    local map = Workspace:FindFirstChild("Map")
    if not map then
        warn("[RealSpawner] Map not found in Workspace!")
        return
    end

    local spawnsFolder = map:FindFirstChild("Spawns")
    if not spawnsFolder then
        warn("[RealSpawner] No Spawns folder found under Map!")
        return
    end

    for _, obj in ipairs(spawnsFolder:GetChildren()) do
        if obj:IsA("BasePart") then
            table.insert(spawnPoints, obj)
        end
    end

    if #spawnPoints == 0 then
        warn("[RealSpawner] No spawn points found in Spawns folder!")
    end
end

refreshSpawnPoints()

local function getRandomSpawnPoint()
    if #spawnPoints == 0 then
        return CFrame.new(0, 10, 0)
    end
    local chosen = spawnPoints[math.random(#spawnPoints)]
    return chosen.CFrame
end

local function spawnPlayerWithTool(player, toolName)
    if hasSpawned[player] then
        return
    end

    if type(toolName) ~= "string" or not ToolConfig.ValidCombatTools[toolName] then
        warn("[RealSpawner] Invalid tool requested:", toolName)
        return
    end

    local tool = TOOLS_FOLDER:FindFirstChild(toolName)
    if not tool then
        warn("[RealSpawner] Tool not found:", toolName)
        return
    end

    print("[RealSpawner] Spawn request from:", player.Name, "Tool:", toolName)

    player:LoadCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        HealthService.SetupHumanoid(humanoid)
    end
    StaminaService.ResetStamina(player)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)

    if hrp then
        hrp.Anchored = false
        hrp.CFrame = getRandomSpawnPoint()
    end

    local clone = tool:Clone()
    clone.Parent = player:WaitForChild("Backpack")

    hasSpawned[player] = true
end

SpawnRequestEvent.OnServerEvent:Connect(spawnPlayerWithTool)

print("[RealSpawner] Initialized")
