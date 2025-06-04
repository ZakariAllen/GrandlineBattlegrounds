--ReplicatedStorage.Modules.Client.JumpController

local JumpController = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config.Config)
local player = Players.LocalPlayer

local JUMP_COOLDOWN = Config.GameSettings.JumpCooldown
local DEBUG = Config.GameSettings.DebugEnabled

local jumpBlockedUntil = 0
local character, humanoid
local heartbeatConn

-- 🔒 Forcefully disable jumping
local function blockJump()
	if humanoid and humanoid:IsDescendantOf(workspace) then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid.Jump = false
	end
end

-- 🔓 Re-enable jumping
local function restoreJump()
	if humanoid and humanoid:IsDescendantOf(workspace) then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end

-- ⏱ Begin jump cooldown
function JumpController.StartCooldown(duration)
	local time = duration or JUMP_COOLDOWN
	jumpBlockedUntil = tick() + time
	if DEBUG then print("[JumpController] Jump cooldown started:", time, "s") end

	if heartbeatConn then
		heartbeatConn:Disconnect()
	end

	heartbeatConn = RunService.Heartbeat:Connect(function()
		if tick() < jumpBlockedUntil then
			blockJump()
		else
			restoreJump()
			if heartbeatConn then
				heartbeatConn:Disconnect()
				heartbeatConn = nil
			end
		end
	end)
end

-- 📦 Handle jump input
local function onJumpRequest()
	if not humanoid then return end
	if tick() < jumpBlockedUntil then
		if DEBUG then print("[JumpController] Jump blocked. Time left:", jumpBlockedUntil - tick()) end
		blockJump()
	else
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		JumpController.StartCooldown()
	end
end

-- 🔁 Character added
local function onCharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	restoreJump()
	if DEBUG then print("[JumpController] Humanoid ready") end
end

-- 🔧 Setup
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

UserInputService.JumpRequest:Connect(onJumpRequest)

if DEBUG then print("[JumpController] Initialized with cooldown:", JUMP_COOLDOWN) end

return JumpController
