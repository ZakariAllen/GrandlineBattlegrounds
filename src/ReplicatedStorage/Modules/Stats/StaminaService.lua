--ReplicatedStorage.Modules.Stats.StaminaService

local StaminaService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)

StaminaService.DEFAULT_MAX = PlayerStats.Stamina
StaminaService.REGEN_RATE = PlayerStats.StaminaRegen
StaminaService._regenPaused = {}

local function setupPlayer(player)
    local max = player:FindFirstChild("MaxStamina")
    if not max then
        max = Instance.new("NumberValue")
        max.Name = "MaxStamina"
        max.Value = StaminaService.DEFAULT_MAX
        max.Parent = player
    end

    local cur = player:FindFirstChild("Stamina")
    if not cur then
        cur = Instance.new("NumberValue")
        cur.Name = "Stamina"
        cur.Value = max.Value
        cur.Parent = player
    end
end

function StaminaService.PauseRegen(player)
    StaminaService._regenPaused[player] = true
end

function StaminaService.ResumeRegen(player)
    StaminaService._regenPaused[player] = nil
end

if RunService:IsServer() then
    Players.PlayerAdded:Connect(setupPlayer)
    for _, p in ipairs(Players:GetPlayers()) do
        setupPlayer(p)
    end

    Players.PlayerRemoving:Connect(function(player)
        StaminaService._regenPaused[player] = nil
    end)

    RunService.Heartbeat:Connect(function(dt)
        for _, player in ipairs(Players:GetPlayers()) do
            if StaminaService._regenPaused[player] then
                continue
            end
            local max = player:FindFirstChild("MaxStamina")
            local cur = player:FindFirstChild("Stamina")
            if max and cur then
                cur.Value = math.min(cur.Value + StaminaService.REGEN_RATE * dt, max.Value)
            end
        end
    end)
end

function StaminaService.GetStamina(player)
    local val = player and player:FindFirstChild("Stamina")
    return val and val.Value or 0
end

function StaminaService.GetMaxStamina(player)
    local val = player and player:FindFirstChild("MaxStamina")
    return val and val.Value or StaminaService.DEFAULT_MAX
end

function StaminaService.Consume(player, amount)
    if not RunService:IsServer() then return false end
    local cur = player:FindFirstChild("Stamina")
    local max = player:FindFirstChild("MaxStamina")
    if not cur or not max then return false end
    if cur.Value < amount then return false end
    cur.Value -= amount
    return true
end

return StaminaService

