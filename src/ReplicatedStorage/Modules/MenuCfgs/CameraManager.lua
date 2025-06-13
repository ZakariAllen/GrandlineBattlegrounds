--ReplicatedStorage.Modules.MenuCfgs.CameraManager

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Camera = workspace.CurrentCamera
local MenuGlobalCfg = require(ReplicatedStorage.Modules.MenuCfgs.MenuGlobalCfg)

local CameraManager = {}

local applied = false
local rotationConnection
local blurWatchdogConnection

local BLUR_NAME = "MainMenuBlur"

local function ensureBlur()
	if not Lighting:FindFirstChild(BLUR_NAME) then
		local blur = Instance.new("BlurEffect")
		blur.Name = BLUR_NAME
		blur.Size = 20
		blur.Parent = Lighting
	end
end

function CameraManager.ApplyMenuCamera()
	if applied then return end
	applied = true

        task.delay(0.05, function() -- allow camera to be ready
                local camCfg = MenuGlobalCfg.Camera
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = camCfg.StartCFrame

                if Workspace.StreamingEnabled then
                        local pos = camCfg.StartCFrame.Position
                        pcall(function()
                                Workspace:RequestStreamAroundAsync(pos)
                        end)
                end

                ensureBlur()

                blurWatchdogConnection = RunService.Heartbeat:Connect(function()
                        ensureBlur()
                end)

		if camCfg.Rotate then
			local focus = camCfg.FocusPoint
			local speed = camCfg.RotationSpeed
			local startPos = camCfg.StartCFrame.Position
			local radius = (startPos - focus).Magnitude
			local y = startPos.Y

			rotationConnection = RunService.RenderStepped:Connect(function()
				local t = tick() * speed
				local x = math.cos(t) * radius
				local z = math.sin(t) * radius
				local pos = Vector3.new(x, y, z)
				Camera.CFrame = CFrame.new(pos, focus)
			end)
		end
	end)
end

function CameraManager.ClearMenuCamera()
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end

	if blurWatchdogConnection then
		blurWatchdogConnection:Disconnect()
		blurWatchdogConnection = nil
	end

	local blur = Lighting:FindFirstChild(BLUR_NAME)
	if blur then blur:Destroy() end

	Camera.CameraType = Enum.CameraType.Custom
	applied = false
end

function CameraManager.GetMenuStartCFrame()
	return MenuGlobalCfg.Camera.StartCFrame
end

return CameraManager
