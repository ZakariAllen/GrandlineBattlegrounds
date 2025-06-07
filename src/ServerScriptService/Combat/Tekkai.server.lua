local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local TekkaiEvent = CombatRemotes:WaitForChild("TekkaiEvent")

local TekkaiService = require(ReplicatedStorage.Modules.Combat.TekkaiService)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)

TekkaiEvent.OnServerEvent:Connect(function(player, start)
    if start then
        if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) or BlockService.IsBlocking(player) then
            TekkaiEvent:FireClient(player, false)
            return
        end
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool or tool.Name ~= "Rokushiki" or not ToolConfig.ValidCombatTools[tool.Name] then
            TekkaiEvent:FireClient(player, false)
            return
        end
        if TekkaiService.Start(player) then
            TekkaiEvent:FireAllClients(player, true)
        else
            TekkaiEvent:FireClient(player, false)
        end
    else
        TekkaiService.Stop(player)
        TekkaiEvent:FireAllClients(player, false)
    end
end)

