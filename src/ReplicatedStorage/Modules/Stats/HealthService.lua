--ReplicatedStorage.Modules.Stats.HealthService

local HealthService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)

HealthService.DEFAULT_MAX = PlayerStats.HP
HealthService.REGEN_RATE = PlayerStats.HPRegen

function HealthService.SetupHumanoid(humanoid)
    if humanoid then
        humanoid.MaxHealth = HealthService.DEFAULT_MAX
        humanoid.Health = HealthService.DEFAULT_MAX
    end
end

if RunService:IsServer() then
    local function onCharacterAdded(char)
        local hum = char:WaitForChild("Humanoid", 5)
        HealthService.SetupHumanoid(hum)
    end

    local function onPlayer(player)
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then
            onCharacterAdded(player.Character)
        end
    end

    Players.PlayerAdded:Connect(onPlayer)
    for _, p in ipairs(Players:GetPlayers()) do
        onPlayer(p)
    end

    RunService.Heartbeat:Connect(function(dt)
        for _, player in ipairs(Players:GetPlayers()) do
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum.Health = math.min(hum.Health + HealthService.REGEN_RATE * dt, hum.MaxHealth)
            end
        end
    end)
end

return HealthService
