local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local COLLISION_GROUP = "Players"

local groupExists = false
for _, group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
        if group.name == COLLISION_GROUP then
                groupExists = true
                break
        end
end
if not groupExists then
        PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
end

-- ✅ Disable collision within the group
PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)

-- ✅ Recursively set collision group on all BaseParts
local function setCollisionGroupRecursive(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part:IsDescendantOf(Workspace.Terrain) then
			-- Avoid errors on locked or non-editable parts
			pcall(function()
				part.CollisionGroup = COLLISION_GROUP
			end)
		end
	end
end

-- ✅ Assign when character spawns
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 5)
		setCollisionGroupRecursive(character)
	end)
end)

-- ✅ For any characters already present (e.g., in Studio or on hot reload)
for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
                setCollisionGroupRecursive(player.Character)
        end
end

print("[PlayerCollisionDisabler] Initialized")
