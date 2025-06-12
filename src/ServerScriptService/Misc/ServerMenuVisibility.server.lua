local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UI = Remotes:WaitForChild("UI") -- ✅ Correct folder reference

-- Ensure the remote events exist or create them
local PlayerEnteredMenu = UI:FindFirstChild("PlayerEnteredMenu") or Instance.new("RemoteEvent")
PlayerEnteredMenu.Name = "PlayerEnteredMenu"
PlayerEnteredMenu.Parent = UI

local PlayerLeftMenu = UI:FindFirstChild("PlayerLeftMenu") or Instance.new("RemoteEvent")
PlayerLeftMenu.Name = "PlayerLeftMenu"
PlayerLeftMenu.Parent = UI

-- Hide character visually for menu
local function hideCharacterForMenu(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(0, 300, 0)
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.Transparency = 1 end
		if part:IsA("Decal") then part.Transparency = 1 end
		if part:IsA("ParticleEmitter") or part:IsA("Trail") then part.Enabled = false end
	end
end

-- Restore character appearance and unanchor
local function restoreCharacter(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.Transparency = 0 end
		if part:IsA("Decal") then part.Transparency = 0 end
		if part:IsA("ParticleEmitter") or part:IsA("Trail") then part.Enabled = true end
	end
end

-- Track player character connections for menu hiding
local menuConns = {}

PlayerEnteredMenu.OnServerEvent:Connect(function(player)
	if player.Character then
		hideCharacterForMenu(player.Character)
	end
	if menuConns[player] then
		menuConns[player]:Disconnect()
	end
	menuConns[player] = player.CharacterAdded:Connect(function(char)
		hideCharacterForMenu(char)
	end)
end)

PlayerLeftMenu.OnServerEvent:Connect(function(player)
	-- Cleanup connections
	if menuConns[player] then
		menuConns[player]:Disconnect()
		menuConns[player] = nil
	end
        -- Character spawning is now handled entirely by RealSpawner when the
        -- client requests to play.  Loading the character here caused players
        -- to momentarily appear at the default spawn position before being
        -- teleported.  Simply remove the old character connection and let
        -- RealSpawner spawn a fresh character.
        if player.Character then
                player.Character:BreakJoints()
        end
end)

Players.PlayerRemoving:Connect(function(player)
        if menuConns[player] then
                menuConns[player]:Disconnect()
                menuConns[player] = nil
        end
end)

print("[ServerMenuVisibility] Initialized")
