local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local HakiEvent = CombatRemotes:WaitForChild("HakiEvent")

local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)

local function broadcastState(player)
    local active = HakiService.IsActive(player)
    HakiEvent:FireAllClients(player, active)
end

local pending = {}

HakiEvent.OnServerEvent:Connect(function(player, enable)
    if typeof(enable) ~= "boolean" then return end
    if pending[player] then return end
    pending[player] = true

    if enable then
        if not HakiService.Toggle(player, true) then
            HakiEvent:FireClient(player, false)
            pending[player] = nil
            return
        end
    else
        HakiService.Toggle(player, false)
    end

    broadcastState(player)

    task.delay(1, function()
        pending[player] = nil
    end)
end)

RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if HakiService.IsActive(player) and HakiService.GetHaki(player) <= 0 then
            HakiService.Toggle(player, false)
            broadcastState(player)
        end
    end
end)

print("[HakiServer] Ready")

