local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UI = Remotes:WaitForChild("UI") -- ✅ Correct folder reference

-- Ensure the remote events exist or create them
local PlayerEnteredMenu = UI:FindFirstChild("PlayerEnteredMenu") or Instance.new("RemoteEvent")
PlayerEnteredMenu.Name = "PlayerEnteredMenu"
PlayerEnteredMenu.Parent = UI

local PlayerLeftMenu = UI:FindFirstChild("PlayerLeftMenu") or Instance.new("RemoteEvent")
PlayerLeftMenu.Name = "PlayerLeftMenu"
PlayerLeftMenu.Parent = UI

local lobbySpawn
task.defer(function()
    -- Wait for lobby spawn to exist
    local ok, result = pcall(function()
        lobbySpawn = Workspace:WaitForChild("Map", 10)
        if lobbySpawn then
            lobbySpawn = lobbySpawn:WaitForChild("Lobby", 10)
        end
        if lobbySpawn then
            lobbySpawn = lobbySpawn:WaitForChild("SpawnLocation", 10)
        end
    end)
    if not ok or not lobbySpawn then
        warn("[ServerMenuVisibility] Lobby spawn not found")
    end
end)

-- Move character to the lobby spawn and prevent movement
local function placeCharacterInLobby(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and lobbySpawn then
        hrp.CFrame = lobbySpawn.CFrame
        hrp.Anchored = true
    elseif hrp then
        hrp.Anchored = true
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = false
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
end

-- Track character respawns while the player is in the menu
local menuConns = {}

PlayerEnteredMenu.OnServerEvent:Connect(function(player)
        if player.Character then
                placeCharacterInLobby(player.Character)
        end
	if menuConns[player] then
		menuConns[player]:Disconnect()
	end
        menuConns[player] = player.CharacterAdded:Connect(function(char)
                placeCharacterInLobby(char)
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
