local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--[[
    Ensures a Map model exists in Workspace. If a model named "Map" is found in
    ServerStorage or ReplicatedStorage, it will be cloned into Workspace. If no
    map exists, a simple placeholder map is created so that the main menu has a
    visible environment. This allows players to see the world and other players
    fighting before they spawn in.
]]

if not Workspace:FindFirstChild("Map") then
    local source = ServerStorage:FindFirstChild("Map") or ReplicatedStorage:FindFirstChild("Map")
    if source then
        source:Clone().Parent = Workspace
        print("[MapLoader] Loaded map from storage")
    else
        local map = Instance.new("Model")
        map.Name = "Map"
        map.Parent = Workspace

        local base = Instance.new("Part")
        base.Name = "Base"
        base.Anchored = true
        base.Size = Vector3.new(512, 1, 512)
        base.Position = Vector3.new(0, 0, 0)
        base.Parent = map

        local spawns = Instance.new("Folder")
        spawns.Name = "Spawns"
        spawns.Parent = map

        local spawn = Instance.new("Part")
        spawn.Name = "Spawn1"
        spawn.Anchored = true
        spawn.Transparency = 1
        spawn.CanCollide = false
        spawn.Size = Vector3.new(4, 1, 4)
        spawn.Position = Vector3.new(0, 3, 0)
        spawn.Parent = spawns

        print("[MapLoader] Created placeholder map")
    end
end
