-- ReplicatedStorage.Modules.Movement.DashClient

local DashClient = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local DashEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement"):WaitForChild("DashEvent")
local DashConfig = require(ReplicatedStorage.Modules.Movement.DashConfig)
local MovementAnimations = require(ReplicatedStorage.Modules.Animations.Movement)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)

local lastDashTime = 0
local DASH_KEY = Enum.KeyCode.Q
local currentTrack = nil
local dashConn = nil

local function getCharacterComponents()
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, animator, hrp
end

-- 🚨 CAMERA-RELATIVE DASHING!
local function getDashInputAndVector()
	local keys = MovementClient.GetMovementKeys and MovementClient.GetMovementKeys() or {}
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	local camLook = camera.CFrame.LookVector
	local camRight = camera.CFrame.RightVector

	camLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
	camRight = Vector3.new(camRight.X, 0, camRight.Z).Unit

	if keys.W and keys.A then
		return "ForwardLeft", (camLook - camRight).Unit
	elseif keys.W and keys.D then
		return "ForwardRight", (camLook + camRight).Unit
	elseif keys.S and keys.A then
		return "BackwardLeft", ((-camLook) - camRight).Unit
	elseif keys.S and keys.D then
		return "BackwardRight", ((-camLook) + camRight).Unit
	elseif keys.W then
		return "Forward", camLook
	elseif keys.A then
		return "Left", (-camRight).Unit
	elseif keys.D then
		return "Right", camRight
	elseif keys.S then
		return "Backward", (-camLook).Unit
	end
	return nil
end

local function playDashAnimation(direction)
	local _, _, animator = getCharacterComponents()
	if not animator then return end

	local animId = MovementAnimations.Dash[direction] or MovementAnimations.Dash["Forward"]
	if not animId then return end

	if currentTrack and currentTrack.IsPlaying then
		currentTrack:Stop()
		currentTrack:Destroy()
		currentTrack = nil
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animId

	local track = animator:LoadAnimation(anim)
	track:Play()
	currentTrack = track
end

function DashClient.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode ~= DASH_KEY then return end

	if tick() - lastDashTime < DashConfig.Cooldown then return end
	if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

	local direction, dashVector = getDashInputAndVector()
	if not direction or not dashVector then return end

	lastDashTime = tick()
	playDashAnimation(direction)

	local _, humanoid, _, hrp = getCharacterComponents()
	local dashSettings = DashConfig.Settings[direction] or DashConfig.Settings["Forward"]
	local duration = dashSettings.Duration
	local distance = dashSettings.Distance

	local dashSpeed = distance / duration

	-- Stop any ongoing dash update
	if dashConn then dashConn:Disconnect() dashConn = nil end

	-- The only dashes that are steerable (dynamic) are the "Forward" and "ForwardLeft/Right" ones.
	if direction == "Forward" or direction == "ForwardLeft" or direction == "ForwardRight" then
		local start = tick()
		dashConn = RunService.RenderStepped:Connect(function()
			if not hrp or not humanoid then return end
			if tick() - start > duration then
				if dashConn then dashConn:Disconnect() dashConn = nil end
				return
			end

			local camera = Workspace.CurrentCamera
			local camLook = camera.CFrame.LookVector
			local camRight = camera.CFrame.RightVector
			camLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
			camRight = Vector3.new(camRight.X, 0, camRight.Z).Unit

			local liveDashDir =
				(direction == "Forward" and camLook)
				or (direction == "ForwardLeft" and (camLook - camRight).Unit)
				or (direction == "ForwardRight" and (camLook + camRight).Unit)
				or dashVector

			local curVel = hrp.AssemblyLinearVelocity
			local dashVel = Vector3.new(liveDashDir.X * dashSpeed, curVel.Y, liveDashDir.Z * dashSpeed)
			hrp.AssemblyLinearVelocity = dashVel
		end)

		task.delay(duration, function()
			if dashConn then dashConn:Disconnect() dashConn = nil end
		end)
	else
		-- For left, right, backward, backwardleft, backwardright: one-time velocity, lock rotation
		local curVel = hrp.AssemblyLinearVelocity
		local dashVel = Vector3.new(dashVector.X * dashSpeed, curVel.Y, dashVector.Z * dashSpeed)
		hrp.AssemblyLinearVelocity = dashVel
		humanoid.AutoRotate = false
		task.delay(duration, function()
			humanoid.AutoRotate = true
		end)
	end

	-- Notify server for validation (state only)
	DashEvent:FireServer(direction, dashVector)
end

function DashClient.OnInputEnded() end

return DashClient
