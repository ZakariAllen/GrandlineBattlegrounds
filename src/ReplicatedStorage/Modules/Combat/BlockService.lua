--ReplicatedStorage.Modules.Combat.BlockService

local BlockService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local Config = require(ReplicatedStorage.Modules.Config.Config)

-- 🧠 Block state
local BlockingPlayers = {}   -- [player] = true/false
local BlockHP = {}           -- [player] = number
local PerfectBlockTimers = {} -- [player] = tick()

-- ✅ Public access
function BlockService.IsBlocking(player)
	return BlockingPlayers[player] == true
end

function BlockService.GetBlockHP(player)
	return BlockHP[player] or CombatConfig.Blocking.BlockHP
end

function BlockService.GetPerfectBlockStunDuration()
	return CombatConfig.Blocking.PerfectBlockStunDuration or 6
end

function BlockService.GetBlockBreakStunDuration()
	return CombatConfig.Blocking.BlockBreakStunDuration or 4
end

-- 🛡️ Called when player starts blocking
function BlockService.StartBlocking(player)
	BlockHP[player] = CombatConfig.Blocking.BlockHP
	BlockingPlayers[player] = true
	PerfectBlockTimers[player] = tick()
end

-- ❌ Called when player releases block or is stunned out
function BlockService.StopBlocking(player)
	BlockingPlayers[player] = nil
	BlockHP[player] = nil
	PerfectBlockTimers[player] = nil
end

-- ⚔️ Handles damage application to a blocking player
-- Returns: "Perfect", "Damaged", "Broken", or nil (not blocking)
function BlockService.ApplyBlockDamage(player, damage)
	if not BlockingPlayers[player] then return nil end

	local hp = BlockHP[player] or 0
	local timeSinceStart = tick() - (PerfectBlockTimers[player] or 0)

	-- 🌀 Perfect block window
	if timeSinceStart <= CombatConfig.Blocking.PerfectBlockWindow then
		-- Reflect to attacker happens in CombatService
		BlockService.StopBlocking(player)
		return "Perfect"
	end

	-- 🩸 Block damage
	hp -= damage
	if hp <= 0 then
		BlockService.StopBlocking(player)
		return "Broken"
	else
		BlockHP[player] = hp
		return "Damaged"
	end
end

-- 🧹 Cleanup if player leaves or dies
local function cleanup(player)
	BlockService.StopBlocking(player)
end

Players.PlayerRemoving:Connect(cleanup)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		cleanup(player)
	end)
end)

return BlockService
