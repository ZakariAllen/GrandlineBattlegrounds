-- ServerScriptService > RealSpawner

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ✅ Updated remote path
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SystemRemotes = Remotes:WaitForChild("System")
local SpawnRequestEvent = SystemRemotes:WaitForChild("SpawnRequestEvent")

local TOOLS_FOLDER = ReplicatedStorage:WaitForChild("Tools")
local hasSpawned = require(script.Parent:WaitForChild("SpawnRegistry"))

local function stripPrefix(name)
	-- Removes "1 - " or "2 - " etc. from button name
	return name:match("^%d+%s*%-[%s]*(.+)$") or name
end

local function getRandomSpawnPoint()
	local map = Workspace:FindFirstChild("Map")
	if not map then
		warn("[RealSpawner] Map not found in Workspace!")
		return CFrame.new(0, 10, 0)
	end

	local spawnsFolder = map:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("[RealSpawner] No Spawns folder found under Map!")
		return CFrame.new(0, 10, 0)
	end

	local spawnPoints = {}
	for _, obj in ipairs(spawnsFolder:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(spawnPoints, obj)
		end
	end

	if #spawnPoints == 0 then
		warn("[RealSpawner] No spawn points found in Spawns folder!")
		return CFrame.new(0, 10, 0)
	end

	local chosen = spawnPoints[math.random(1, #spawnPoints)]
	return chosen.CFrame
end

local function spawnPlayerWithTool(player, toolName)
	print("[RealSpawner] Spawn request from:", player.Name, "Tool:", toolName)

	-- Remove prefix if present
	local cleanedToolName = stripPrefix(toolName)
	print("[RealSpawner] Cleaned tool name:", cleanedToolName)

	local tool = TOOLS_FOLDER:FindFirstChild(cleanedToolName)
	if not tool then
		warn("[RealSpawner] Tool not found:", cleanedToolName)
		return
	end

	player:LoadCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
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
