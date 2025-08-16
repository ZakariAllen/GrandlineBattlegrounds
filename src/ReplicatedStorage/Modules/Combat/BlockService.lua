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
local ActorAdapter = require(ReplicatedStorage.Modules.AI.ActorAdapter)

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatFolder = remotes:WaitForChild("Combat")
local VFXEvent = combatFolder:WaitForChild("BlockVFX")
local BlockEvent = combatFolder:WaitForChild("BlockEvent")

-- 🧠 Block state
local BlockingPlayers = {}    -- [char] = true/false
local BlockHP = {}            -- [char] = number
local PerfectBlockTimers = {} -- [char] = tick()
local BlockCooldowns = {}     -- [char] = time
local BlockStartup = {}       -- [char] = true

-- ✅ Public access
local function resolve(actor)
       local info = ActorAdapter.Get(actor)
       return info and info.Character, info
end

function BlockService.IsBlocking(actor)
       local key = resolve(actor)
       return key and BlockingPlayers[key] == true
end

function BlockService.IsInStartup(actor)
       local key = resolve(actor)
       return key and BlockStartup[key] == true
end

function BlockService.GetBlockHP(actor)
       local key, info = resolve(actor)
       if not key then
               return PlayerStats.BlockHP
       end
       if info.IsPlayer and TekkaiService.IsActive(info.Player) then
               return TekkaiService.GetHP(info.Player)
       end
       return BlockHP[key] or PlayerStats.BlockHP
end

function BlockService.SetBlockHP(actor, value)
       local key, info = resolve(actor)
       if not key then
               return
       end
       BlockHP[key] = value
       if info and info.IsPlayer then
               OverheadBarService.UpdateBlock(info.Player, value)
       end
end

function BlockService.GetPerfectBlockStunDuration()
	return CombatConfig.Blocking.PerfectBlockStunDuration or 6
end

function BlockService.GetBlockBreakStunDuration()
        return CombatConfig.Blocking.BlockBreakStunDuration or 4
end

function BlockService.IsOnCooldown(actor)
       local key = resolve(actor)
       local t = key and BlockCooldowns[key]
       return t and tick() < t
end

-- 🛡️ Called when player starts blocking
function BlockService.StartBlocking(actor)
       local key, info = resolve(actor)
       if not key then
               return false
       end
       if BlockService.IsOnCooldown(actor) then
               return false
       end
       if BlockingPlayers[key] or BlockStartup[key] then
               return false
       end

       BlockStartup[key] = true
       local startup = CombatConfig.Blocking.StartupTime or 0.1
       task.delay(startup, function()
               if BlockStartup[key] then
                       BlockStartup[key] = nil
                       BlockHP[key] = PlayerStats.BlockHP
                       BlockingPlayers[key] = true
                       PerfectBlockTimers[key] = tick()
                       if info and info.IsPlayer then
                               OverheadBarService.SetBlockActive(info.Player, true)
                               OverheadBarService.UpdateBlock(info.Player, PlayerStats.BlockHP)
                       elseif VFXEvent then
                               VFXEvent:FireAllClients(info.Character, true)
                       end
               end
       end)
       return true
end

-- ❌ Called when player releases block or is stunned out
function BlockService.StopBlocking(actor)
       local key, info = resolve(actor)
       if not key then
               return
       end
       local hadBlock = BlockingPlayers[key] or BlockStartup[key]

       if hadBlock and BlockingPlayers[key] then
               BlockCooldowns[key] = tick() + (CombatConfig.Blocking.BlockCooldown or 2)
       end

       BlockingPlayers[key] = nil
       BlockStartup[key] = nil
       BlockHP[key] = nil
       PerfectBlockTimers[key] = nil

       if VFXEvent then
               VFXEvent:FireAllClients(info.Player or info.Character, false)
       end
       if info and info.IsPlayer and BlockEvent and hadBlock then
               BlockEvent:FireClient(info.Player, false)
       end
       if info and info.IsPlayer then
               OverheadBarService.SetBlockActive(info.Player, false)
               OverheadBarService.UpdateBlock(info.Player, 0)
       end
end

-- ⚔️ Handles damage application to a blocking player
-- Returns: "Perfect", "Damaged", "Broken", or nil (not blocking)
-- @param isBlockBreaker boolean? whether the attack ignores blocking
-- @param attackerRoot Instance? HumanoidRootPart of the attacking player
function BlockService.ApplyBlockDamage(actor, damage, isBlockBreaker, attackerRoot)
       local key, info = resolve(actor)
       if not key then
               return nil
       end
       if info.IsPlayer and TekkaiService.IsActive(info.Player) then
               if isBlockBreaker then
                       return "Damaged"
               end
               return TekkaiService.ApplyDamage(info.Player, damage)
       end

       if not BlockingPlayers[key] then return nil end

       local defenderRoot = info.Character and info.Character:FindFirstChild("HumanoidRootPart")
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
                                 BlockService.StopBlocking(actor)
                                 return nil
                         end
               end
       end

       local hp = BlockHP[key] or 0
       local timeSinceStart = tick() - (PerfectBlockTimers[key] or 0)

       -- 🌀 Perfect block window takes priority even against block breakers
       if timeSinceStart <= CombatConfig.Blocking.PerfectBlockWindow then
               -- Reflect to attacker happens in CombatService
               -- Do not stop blocking on a perfect block so the player remains
               -- in a blocking state
               if info.Player then
                       PersistentStats.RecordBlockedDamage(info.Player, 0, true)
               end
               return "Perfect"
       end

       if isBlockBreaker then
               BlockService.StopBlocking(actor)
               return "Broken"
       end

	-- 🩸 Block damage
         hp -= damage
         if info.Player then
                 PersistentStats.RecordBlockedDamage(info.Player, damage, false)
         end
       if hp <= 0 then
               BlockService.StopBlocking(actor)
               return "Broken"
       else
               BlockHP[key] = hp
               if info.IsPlayer then
                       OverheadBarService.UpdateBlock(info.Player, hp)
               end
               return "Damaged"
       end
end

-- 🧹 Cleanup if player leaves or dies
local function cleanup(actor)
       BlockService.StopBlocking(actor)
       local key = ActorAdapter.GetCharacter(actor)
       if key then
               BlockCooldowns[key] = nil
       end
       if ActorAdapter.IsPlayer(actor) and TekkaiService.IsActive(actor) then
               TekkaiService.Stop(actor)
       end
end

Players.PlayerRemoving:Connect(cleanup)
Players.PlayerAdded:Connect(function(player)
       player.CharacterAdded:Connect(function()
               cleanup(player)
       end)
end)

return BlockService
