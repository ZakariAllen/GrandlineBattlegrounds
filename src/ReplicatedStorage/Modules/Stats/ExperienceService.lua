--ReplicatedStorage.Modules.Stats.ExperienceService

local ExperienceService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XPConfig = require(ReplicatedStorage.Modules.Config.XPConfig)
local PersistentStats = require(script.Parent.PersistentStatsService)

local function setupPlayer(player)
    local levelVal = player:FindFirstChild("Level")
    if not levelVal then
        levelVal = Instance.new("IntValue")
        levelVal.Name = "Level"
        levelVal.Parent = player
    end

    local xpVal = player:FindFirstChild("XP")
    if not xpVal then
        xpVal = Instance.new("IntValue")
        xpVal.Name = "XP"
        xpVal.Parent = player
    end

    local data = PersistentStats.Get(player)
    if data then
        levelVal.Value = data.Level or 1
        xpVal.Value = data.XP or 0
    else
        levelVal.Value = 1
        xpVal.Value = 0
    end
end

if RunService:IsServer() then
    Players.PlayerAdded:Connect(function(player)
        setupPlayer(player)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        setupPlayer(p)
    end
end

function ExperienceService.XPForLevel(level)
    return XPConfig.XPForLevel(level)
end

function ExperienceService.GetXP(player)
    local val = player and player:FindFirstChild("XP")
    return val and val.Value or 0
end

function ExperienceService.GetLevel(player)
    local val = player and player:FindFirstChild("Level")
    return val and val.Value or 1
end

function ExperienceService.AddXP(player, amount)
    if not RunService:IsServer() then return end
    if not player or not amount or amount <= 0 then return end
    local data = PersistentStats.Get(player)
    if not data then return end
    data.XP = (data.XP or 0) + amount
    local level = data.Level or 1
    local xpNeeded = ExperienceService.XPForLevel(level)
    while data.XP >= xpNeeded do
        data.XP -= xpNeeded
        level += 1
        xpNeeded = ExperienceService.XPForLevel(level)
    end
    data.Level = level

    local xpVal = player:FindFirstChild("XP")
    if xpVal then xpVal.Value = data.XP end
    local levelVal = player:FindFirstChild("Level")
    if levelVal then levelVal.Value = level end
end

function ExperienceService.RegisterHit(attacker, targetHumanoid, amount)
    if not RunService:IsServer() then return end
    if attacker and targetHumanoid then
        ExperienceService.AddXP(attacker, amount or 0)
    end
end

return ExperienceService
