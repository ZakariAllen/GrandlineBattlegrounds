--ReplicatedStorage.Modules.Combat.BlockClient

local BlockClient = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)

-- ✅ Fixed remote path
local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

-- State
local isBlocking = false
local lastBlockEnd = 0
local blockCooldown = CombatConfig.Blocking.BlockCooldown or 2

-- Checks if the current tool allows blocking
local function HasValidBlockingTool()
	local tool = ToolController.GetEquippedTool()
	if not tool then return false end

	local styleKey = ToolController.GetEquippedStyleKey()
	if not styleKey then return false end

	local stats = CombatConfig.ToolStats[styleKey]
	return stats and stats.AllowsBlocking ~= false
end

-- Input began: handle F key press
function BlockClient.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode ~= Enum.KeyCode.F then return end

	if isBlocking then return end

	local now = tick()
	if now - lastBlockEnd < blockCooldown then
		warn("[BlockClient] Block is on cooldown")
		return
	end

	if not HasValidBlockingTool() then
		warn("[BlockClient] Invalid tool for blocking")
		return
	end

	isBlocking = true
	BlockEvent:FireServer(true)
end

-- Input ended: stop blocking
function BlockClient.OnInputEnded(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode ~= Enum.KeyCode.F then return end

	if not isBlocking then return end

	isBlocking = false
	lastBlockEnd = tick()
	BlockEvent:FireServer(false)
end

function BlockClient.IsBlocking()
	return isBlocking
end

return BlockClient
