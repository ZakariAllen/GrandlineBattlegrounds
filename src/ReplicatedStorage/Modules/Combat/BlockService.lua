--ReplicatedStorage.Modules.Combat.BlockService

local BlockService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local OverheadBarService = require(ReplicatedStorage.Modules.UI.OverheadBarService)

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatFolder = remotes:WaitForChild("Combat")
local VFXEvent = combatFolder:WaitForChild("BlockVFX")

-- 🧠 Block state
local BlockingPlayers = {}    -- [player] = true/false
local BlockHP = {}            -- [player] = number
local PerfectBlockTimers = {} -- [player] = tick()
local BlockCooldowns = {}     -- [player] = time
local BlockStartup = {}       -- [player] = true

-- ✅ Public access
function BlockService.IsBlocking(player)
        return BlockingPlayers[player] == true
end

function BlockService.IsInStartup(player)
       return BlockStartup[player] == true
end

function BlockService.GetBlockHP(player)
        return BlockHP[player] or PlayerStats.BlockHP
end

function BlockService.GetPerfectBlockStunDuration()
	return CombatConfig.Blocking.PerfectBlockStunDuration or 6
end

function BlockService.GetBlockBreakStunDuration()
        return CombatConfig.Blocking.BlockBreakStunDuration or 4
end

function BlockService.IsOnCooldown(player)
        local t = BlockCooldowns[player]
        return t and tick() < t
end

-- 🛡️ Called when player starts blocking
function BlockService.StartBlocking(player)
       if BlockService.IsOnCooldown(player) then
               return false
       end
       if BlockingPlayers[player] or BlockStartup[player] then
               return false
       end

       BlockStartup[player] = true
       local startup = CombatConfig.Blocking.StartupTime or 0.1
       task.delay(startup, function()
               if BlockStartup[player] then
                       BlockStartup[player] = nil
                       BlockHP[player] = PlayerStats.BlockHP
                       BlockingPlayers[player] = true
                       PerfectBlockTimers[player] = tick()
                       OverheadBarService.SetBlockActive(player, true)
                       OverheadBarService.UpdateBlock(player, PlayerStats.BlockHP)
               end
       end)
       return true
end

-- ❌ Called when player releases block or is stunned out
function BlockService.StopBlocking(player)
       local hadBlock = BlockingPlayers[player] or BlockStartup[player]

       if hadBlock then
               if BlockingPlayers[player] then
                       BlockCooldowns[player] = tick() + (CombatConfig.Blocking.BlockCooldown or 2)
               end
       end

       BlockingPlayers[player] = nil
       BlockStartup[player] = nil
       BlockHP[player] = nil
       PerfectBlockTimers[player] = nil

       if VFXEvent then
               VFXEvent:FireAllClients(player, false)
       end
       OverheadBarService.SetBlockActive(player, false)
       OverheadBarService.UpdateBlock(player, 0)
end

-- ⚔️ Handles damage application to a blocking player
-- Returns: "Perfect", "Damaged", "Broken", or nil (not blocking)
-- @param isBlockBreaker boolean? whether the attack ignores blocking
function BlockService.ApplyBlockDamage(player, damage, isBlockBreaker)
       if not BlockingPlayers[player] then return nil end

       if isBlockBreaker then
               BlockService.StopBlocking(player)
               return "Broken"
       end

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
                OverheadBarService.UpdateBlock(player, hp)
                return "Damaged"
        end
end

-- 🧹 Cleanup if player leaves or dies
local function cleanup(player)
        BlockService.StopBlocking(player)
        BlockCooldowns[player] = nil
end

Players.PlayerRemoving:Connect(cleanup)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		cleanup(player)
	end)
end)

return BlockService
