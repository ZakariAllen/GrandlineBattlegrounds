--ReplicatedStorage.Modules.Stats.PersistentStatsService

local PersistentStatsService = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEFAULT_DATA = {
    Kills = 0,
    Deaths = 0,
    DamageDealt = 0,
    DamageTaken = 0,
    BlockedDamage = 0,
    PerfectBlocks = 0,
    UltimatesUsed = 0,
    -- Total playtime in hours across all sessions
    PlaytimeHours = 0,
    Currency = 0,
    XP = 0,
    Level = 1,
}

local dataStore = DataStoreService:GetDataStore("PersistentPlayerStats")
local cache = {} -- [player] = data table
local lastAttacker = {} -- [Humanoid] = player
local joinTimes = {} -- [player] = tick() when they joined

local function loadPlayer(player)
    local data
    local ok, err = pcall(function()
        data = dataStore:GetAsync(player.UserId)
    end)
    if not ok or typeof(data) ~= "table" then
        data = table.clone(DEFAULT_DATA)
    else
        for k, v in pairs(DEFAULT_DATA) do
            if data[k] == nil then
                data[k] = v
            end
        end
    end
    cache[player] = data
end

local function savePlayer(player)
    local data = cache[player]
    if not data then return end
    pcall(function()
        dataStore:SetAsync(player.UserId, data)
    end)
end

local function onHumanoidDied(hum)
    local victim = Players:GetPlayerFromCharacter(hum.Parent)
    if victim then
        PersistentStatsService.AddStat(victim, "Deaths", 1)
    end
    local killer = lastAttacker[hum]
    if killer then
        PersistentStatsService.AddStat(killer, "Kills", 1)
        local ExperienceService = require(script.Parent.ExperienceService)
        local XPConfig = require(ReplicatedStorage.Modules.Config.XPConfig)
        ExperienceService.AddXP(killer, XPConfig.Kill)
    end
    lastAttacker[hum] = nil
end

local function trackCharacter(player, char)
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            onHumanoidDied(hum)
        end)
    end
end

if RunService:IsServer() then
    Players.PlayerAdded:Connect(function(player)
        loadPlayer(player)
        joinTimes[player] = tick()
        player.CharacterAdded:Connect(function(char)
            trackCharacter(player, char)
        end)
        if player.Character then
            trackCharacter(player, player.Character)
        end
    end)

    for _, p in ipairs(Players:GetPlayers()) do
        loadPlayer(p)
        joinTimes[p] = tick()
        if p.Character then
            trackCharacter(p, p.Character)
        end
    end

    Players.PlayerRemoving:Connect(function(player)
        local join = joinTimes[player]
        if join then
            local delta = tick() - join
            PersistentStatsService.AddStat(player, "PlaytimeHours", delta / 3600)
        end
        joinTimes[player] = nil
        savePlayer(player)
        cache[player] = nil
    end)
end

function PersistentStatsService.Get(player)
    return cache[player]
end

function PersistentStatsService.AddStat(player, key, amount)
    if not RunService:IsServer() then return end
    local data = cache[player]
    if data then
        data[key] = (data[key] or 0) + (amount or 0)
    end
end

function PersistentStatsService.RecordHit(attacker, targetHumanoid, damage)
    if not RunService:IsServer() then return end
    if attacker and damage then
        PersistentStatsService.AddStat(attacker, "DamageDealt", damage)
    end
    local defender = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
    if defender and damage then
        PersistentStatsService.AddStat(defender, "DamageTaken", damage)
    end
    if targetHumanoid then
        lastAttacker[targetHumanoid] = attacker
    end
end

function PersistentStatsService.RecordBlockedDamage(player, amount, perfect)
    if not RunService:IsServer() then return end
    if perfect then
        PersistentStatsService.AddStat(player, "PerfectBlocks", 1)
    end
    if amount and amount > 0 then
        PersistentStatsService.AddStat(player, "BlockedDamage", amount)
    end
end

function PersistentStatsService.RecordUltimateUse(player)
    if not RunService:IsServer() then return end
    PersistentStatsService.AddStat(player, "UltimatesUsed", 1)
end

return PersistentStatsService

