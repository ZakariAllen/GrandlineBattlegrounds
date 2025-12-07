local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local WorldGenerator = require(ReplicatedStorage.Modules.World.WorldGenerator)
local WorldConfig = require(ReplicatedStorage.Modules.Config.WorldConfig)

Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.EnvironmentDiffuseScale = 1.2
Lighting.EnvironmentSpecularScale = 0.5

WorldGenerator.BuildWorld()
workspace:WaitForChild("IsometricWorld")
workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

local spawnLocation = workspace.IsometricWorld:FindFirstChild("Spawn")
if spawnLocation then
    local baseHeight = WorldConfig.Tiles.BaseHeight or 0
    spawnLocation.Position = Vector3.new(
        WorldConfig.Spawn.X,
        baseHeight + spawnLocation.Size.Y / 2,
        WorldConfig.Spawn.Z
    )
end
