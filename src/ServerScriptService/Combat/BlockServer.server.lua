local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")
local BlockVFXEvent = CombatRemotes:WaitForChild("BlockVFX")

local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)

local function hasValidTool(player)
       local char = player.Character
       if not char then return false end
       local tool = char:FindFirstChildOfClass("Tool")
       if not tool then return false end

       if not ToolConfig.ValidCombatTools[tool.Name] then
               return false
       end

       local styleKey = tool.Name
       local stats = ToolConfig.ToolStats[styleKey]
       if stats and stats.AllowsBlocking == false then
               return false
       end

       return true
end

BlockEvent.OnServerEvent:Connect(function(player, start)
        if start then
                if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then
                        BlockEvent:FireClient(player, false)
                        BlockService.StopBlocking(player)
                        return
                end

                if hasValidTool(player) and BlockService.StartBlocking(player) then
                        local startup = CombatConfig.Blocking.StartupTime or 0
                        task.delay(startup, function()
                                if BlockService.IsBlocking(player) then
                                        BlockEvent:FireClient(player, true)
                                        BlockVFXEvent:FireAllClients(player, true)
                                end
                        end)
                else
                        BlockEvent:FireClient(player, false)
                end
        else
                BlockService.StopBlocking(player)
                BlockEvent:FireClient(player, false)
        end
end)


