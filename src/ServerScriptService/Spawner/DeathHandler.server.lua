-- ServerScriptService > DeathHandler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- ✅ Correct remote path
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UIRemotes = Remotes:WaitForChild("UI")
local ReturnToMenuEvent = UIRemotes:WaitForChild("ReturnToMenuEvent")

local hasSpawned = require(script.Parent:WaitForChild("SpawnRegistry"))

-- 🔁 Handle respawn/death
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid", 5)
                if humanoid then
                        humanoid.Died:Connect(function()
                                print("[DeathHandler] Player died:", player.Name)
                                hasSpawned[player] = nil
                                ReturnToMenuEvent:FireClient(player)
                                Debris:AddItem(char, math.random(5, 10))
                        end)
                end
	end)
end)

-- 🔁 Clean up on leave
Players.PlayerRemoving:Connect(function(player)
        hasSpawned[player] = nil
end)

print("[DeathHandler] Initialized")
