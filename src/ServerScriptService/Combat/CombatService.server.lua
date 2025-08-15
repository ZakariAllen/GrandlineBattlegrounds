local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local M1Service = require(script.Parent.M1Service)
local comboTimestamps = M1Service.ComboTimestamps

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local M1Event = CombatRemotes:WaitForChild("M1Event")
local HitConfirmEvent = CombatRemotes:WaitForChild("HitConfirmEvent")

local function cleanup(player)
    comboTimestamps[player] = nil
end

Players.PlayerRemoving:Connect(cleanup)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        cleanup(player)
    end)
end)

M1Event.OnServerEvent:Connect(function(player, payload)
    M1Service.ProcessM1Request(player, payload)
end)

HitConfirmEvent.OnServerEvent:Connect(function(player, targetPlayers, comboIndex, isFinal, originCF, size, travelDistance)
    M1Service.ProcessM1HitConfirm(player, targetPlayers, comboIndex, isFinal, originCF, size, travelDistance)
end)

return nil
