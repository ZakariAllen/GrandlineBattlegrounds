--ReplicatedStorage.Modules.Stats.UltService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UltConfig = require(ReplicatedStorage.Modules.Config.UltConfig)

local UltService = {}

UltService.DEFAULT_MAX = UltConfig.UltBarMax

local lastAttacker = {}
local processedDeaths = setmetatable({}, {__mode = "k"})

local function setupPlayer(player)
    local max = player:FindFirstChild("MaxUlt")
    if not max then
        max = Instance.new("NumberValue")
        max.Name = "MaxUlt"
        max.Value = UltService.DEFAULT_MAX
        max.Parent = player
    end

    local cur = player:FindFirstChild("Ult")
    if not cur then
        cur = Instance.new("NumberValue")
        cur.Name = "Ult"
        cur.Value = 0
        cur.Parent = player
    end
end

local function trackHumanoid(hum)
    hum.Died:Connect(function()
        if processedDeaths[hum] then return end
        processedDeaths[hum] = true
        local killer = lastAttacker[hum]
        if killer then
            UltService.AddUlt(killer, UltConfig.Kills)
        end
        lastAttacker[hum] = nil
    end)
end

if RunService:IsServer() then
    Players.PlayerAdded:Connect(function(player)
        setupPlayer(player)
        player.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                trackHumanoid(hum)
            end
        end)
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then trackHumanoid(hum) end
        end
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        setupPlayer(p)
        if p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then trackHumanoid(hum) end
        end
    end
end

function UltService.GetUlt(player)
    local val = player and player:FindFirstChild("Ult")
    return val and val.Value or 0
end

function UltService.GetMaxUlt(player)
    local val = player and player:FindFirstChild("MaxUlt")
    return val and val.Value or UltService.DEFAULT_MAX
end

function UltService.AddUlt(player, amount)
    if not RunService:IsServer() then return end
    local cur = player and player:FindFirstChild("Ult")
    local max = player and player:FindFirstChild("MaxUlt")
    if not cur or not max then return end
    cur.Value = math.clamp(cur.Value + (amount or 0), 0, max.Value)
end

function UltService.ConsumeUlt(player)
    if not RunService:IsServer() then return false end
    local cur = player and player:FindFirstChild("Ult")
    local max = player and player:FindFirstChild("MaxUlt")
    if not cur or not max then return false end
    if cur.Value < max.Value then return false end
    cur.Value = 0
    return true
end

function UltService.RegisterHit(attacker, targetHumanoid, amount)
    if not RunService:IsServer() then return end
    if not attacker or not targetHumanoid then return end
    lastAttacker[targetHumanoid] = attacker
    UltService.AddUlt(attacker, amount)
end

return UltService
