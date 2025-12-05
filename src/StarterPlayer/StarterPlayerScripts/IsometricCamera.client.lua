local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WorldConfig = require(ReplicatedStorage.Modules.Config.WorldConfig)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 50

local function updateCamera()
    local character = player.Character
    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local focus = root.Position + Vector3.new(0, WorldConfig.Camera.FocusHeight, 0)
    local pitch = math.rad(WorldConfig.Camera.PitchDeg)
    local yaw = math.rad(WorldConfig.Camera.YawDeg)

    local horizontal = WorldConfig.Camera.Distance * math.cos(pitch)
    local vertical = WorldConfig.Camera.Distance * math.sin(pitch)

    local offset = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(Vector3.new(0, vertical, horizontal))
    local cameraPosition = focus + offset

    camera.CFrame = CFrame.new(cameraPosition, focus)
end

RunService:BindToRenderStep("IsometricCamera", Enum.RenderPriority.Camera.Value, updateCamera)

player.CharacterAdded:Connect(function()
    camera.CameraType = Enum.CameraType.Scriptable
end)
