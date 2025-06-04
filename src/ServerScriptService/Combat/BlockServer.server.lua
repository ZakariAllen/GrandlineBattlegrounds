local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)

local function hasValidTool(player)
       local char = player.Character
       if not char then return false end
       local tool = char:FindFirstChildOfClass("Tool")
       if not tool then return false end

       if not ToolConfig.ValidCombatTools[tool.Name] then
               return false
       end

       local styleKey = tool.Name:gsub(" ", "")
       local stats = ToolConfig.ToolStats[styleKey]
       if stats and stats.AllowsBlocking == false then
               return false
       end

       return true
end

BlockEvent.OnServerEvent:Connect(function(player, start)
        if start then
                if hasValidTool(player) and BlockService.StartBlocking(player) then
                        BlockEvent:FireClient(player, true)
                else
                        BlockEvent:FireClient(player, false)
                end
        else
                BlockService.StopBlocking(player)
                BlockEvent:FireClient(player, false)
        end
end)


