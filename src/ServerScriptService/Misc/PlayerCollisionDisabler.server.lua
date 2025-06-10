local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local COLLISION_GROUP = "Players"

-- Ensure the collision group exists once
local groupExists = false
for _, group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
    if group.name == COLLISION_GROUP then
        groupExists = true
        break
    end
end
if not groupExists then
    pcall(function()
        PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
    end)
end

-- ✅ Disable collision within the group
PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)

-- ✅ Recursively set collision group on all BaseParts
local function setPartCollision(part)
    if part:IsA("BasePart") and not part:IsDescendantOf(Workspace.Terrain) then
        pcall(function()
            part.CollisionGroup = COLLISION_GROUP
        end)
    end
end

local function setupCharacter(model)
    for _, part in ipairs(model:GetDescendants()) do
        setPartCollision(part)
    end
    model.DescendantAdded:Connect(setPartCollision)
end

-- ✅ Assign when character spawns
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart", 5)
        setupCharacter(character)
    end)
end)

-- ✅ For any characters already present (e.g., in Studio or on hot reload)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        setupCharacter(player.Character)
    end
end

print("[PlayerCollisionDisabler] Initialized")
