--ReplicatedStorage.Modules.Client.MovementClient

local MovementClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local Config = require(ReplicatedStorage.Modules.Config.Config)
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Stun = Remotes:WaitForChild("Stun")
local MovementFolder = Remotes:WaitForChild("Movement")

local SprintEvent = MovementFolder:WaitForChild("SprintStateEvent")
local StunStatusEvent = Stun:WaitForChild("StunStatusRequestEvent")

-- Local state
local movementKeys = {
	W = false, A = false, S = false, D = false
}

local sprinting = false
local lastWPress = 0
local isStunned = false
local isLocked = false

-- Sync stun/lock status from server
StunStatusEvent.OnClientEvent:Connect(function(data)
        isStunned = data.Stunned
        isLocked = data.AttackerLock
        if typeof(data.LockRemaining) == "number" and data.LockRemaining > 0 then
                StunStatusClient.LockFor(data.LockRemaining)
        end
end)

local function beginSprint()
       if not sprinting
               and not isStunned
               and not isLocked
               and not StunStatusClient.IsStunned()
               and not StunStatusClient.IsAttackerLocked()
               and not BlockClient.IsBlocking() then
               sprinting = true
               humanoid.WalkSpeed = Config.GameSettings.DefaultSprintSpeed
               SprintEvent:FireServer(true)
       end
end

local function stopSprint()
	if sprinting then
		sprinting = false
		humanoid.WalkSpeed = Config.GameSettings.DefaultWalkSpeed
		SprintEvent:FireServer(false)
	end
end

function MovementClient.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end
	local key = input.KeyCode.Name

	if movementKeys[key] ~= nil then
		movementKeys[key] = true
	end

	if key == "W" then
		local now = tick()
		if now - lastWPress <= 0.3 and not sprinting then
			beginSprint()
		end
		lastWPress = now
	end

	if key == "S" then
		stopSprint()
	end
end

function MovementClient.OnInputEnded(input, gameProcessed)
        if gameProcessed then return end
        local key = input.KeyCode.Name

	if movementKeys[key] ~= nil then
		movementKeys[key] = false
	end

	if key == "W" then
		stopSprint()
	end
end

-- Expose movement key state to other modules (like DashClient)
function MovementClient.GetMovementKeys()
        return movementKeys
end

function MovementClient.StopSprint()
       stopSprint()
end

-- Reset on respawn
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	stopSprint()
end)

return MovementClient
