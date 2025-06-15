--ReplicatedStorage.Modules.Combat.BlockService

local BlockService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PersistentStats = require(ReplicatedStorage.Modules.Stats.PersistentStatsService)
local Players = game:GetService("Players")

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local OverheadBarService = require(ReplicatedStorage.Modules.UI.OverheadBarService)
local TekkaiService = require(ReplicatedStorage.Modules.Combat.TekkaiService)

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatFolder = remotes:WaitForChild("Combat")
local VFXEvent = combatFolder:WaitForChild("BlockVFX")
local BlockEvent = combatFolder:WaitForChild("BlockEvent")

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
       if TekkaiService.IsActive(player) then
               return TekkaiService.GetHP(player)
       end
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
       if BlockEvent and hadBlock then
               BlockEvent:FireClient(player, false)
       end
       OverheadBarService.SetBlockActive(player, false)
       OverheadBarService.UpdateBlock(player, 0)
end

-- ⚔️ Handles damage application to a blocking player
-- Returns: "Perfect", "Damaged", "Broken", or nil (not blocking)
-- @param isBlockBreaker boolean? whether the attack ignores blocking
-- @param attackerRoot Instance? HumanoidRootPart of the attacking player
function BlockService.ApplyBlockDamage(player, damage, isBlockBreaker, attackerRoot)
       if TekkaiService.IsActive(player) then
               if isBlockBreaker then
                       -- Guard break moves should not deplete Tekkai HP
                       return "Damaged"
               end
               return TekkaiService.ApplyDamage(player, damage)
       end

       if not BlockingPlayers[player] then return nil end

       local defenderRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
       if attackerRoot and defenderRoot then
               local relative = attackerRoot.Position - defenderRoot.Position
               relative = Vector3.new(relative.X, 0, relative.Z)
               local look = defenderRoot.CFrame.LookVector
               look = Vector3.new(look.X, 0, look.Z)
               if relative.Magnitude > 0 and look.Magnitude > 0 then
                       local dir = relative.Unit
                       local facing = look.Unit
                       -- Cancel blocking when struck from behind, do not trigger a break
                       if dir:Dot(facing) <= -0.7 then
                               BlockService.StopBlocking(player)
                               return nil
                       end
               end
       end

       local hp = BlockHP[player] or 0
       local timeSinceStart = tick() - (PerfectBlockTimers[player] or 0)

       -- 🌀 Perfect block window takes priority even against block breakers
       if timeSinceStart <= CombatConfig.Blocking.PerfectBlockWindow then
               -- Reflect to attacker happens in CombatService
               -- Do not stop blocking on a perfect block so the player remains
               -- in a blocking state
               PersistentStats.RecordBlockedDamage(player, 0, true)
               return "Perfect"
       end

       if isBlockBreaker then
               BlockService.StopBlocking(player)
               return "Broken"
       end

	-- 🩸 Block damage
        hp -= damage
        PersistentStats.RecordBlockedDamage(player, damage, false)
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
        if TekkaiService.IsActive(player) then
                TekkaiService.Stop(player)
        end
end

Players.PlayerRemoving:Connect(cleanup)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		cleanup(player)
	end)
end)

return BlockService
