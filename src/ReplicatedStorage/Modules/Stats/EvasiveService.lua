--ReplicatedStorage.Modules.Stats.EvasiveService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)

local EvasiveService = {}

EvasiveService.DEFAULT_MAX = 100
EvasiveService.REGEN_TIME = 180 -- seconds to fill from 0 to 100
EvasiveService.REGEN_RATE = EvasiveService.DEFAULT_MAX / EvasiveService.REGEN_TIME
EvasiveService.DAMAGE_FOR_FULL = 500
EvasiveService.DAMAGE_RATIO = EvasiveService.DEFAULT_MAX / EvasiveService.DAMAGE_FOR_FULL

local ACTIVE = {} -- [player] = true while iframe active
local HEALTH_TRACK = {} -- [humanoid] = lastHealth

local function setupPlayer(player)
    local max = player:FindFirstChild("MaxEvasive")
    if not max then
        max = Instance.new("NumberValue")
        max.Name = "MaxEvasive"
        max.Value = EvasiveService.DEFAULT_MAX
        max.Parent = player
    end

    local cur = player:FindFirstChild("Evasive")
    if not cur then
        cur = Instance.new("NumberValue")
        cur.Name = "Evasive"
        cur.Value = EvasiveService.DEFAULT_MAX * 0.5
        cur.Parent = player
    end
end

local function trackHumanoid(player, humanoid)
    if not humanoid then return end
    HEALTH_TRACK[humanoid] = humanoid.Health
    humanoid.HealthChanged:Connect(function(hp)
        local prev = HEALTH_TRACK[humanoid] or hp
        local delta = prev - hp
        HEALTH_TRACK[humanoid] = hp
        if delta > 0 then
            local points = delta * EvasiveService.DAMAGE_RATIO
            EvasiveService.AddEvasive(player, points)
        end
    end)
    humanoid.AncestryChanged:Connect(function(_, parent)
        if not parent then
            HEALTH_TRACK[humanoid] = nil
        end
    end)
end

if RunService:IsServer() then
    Players.PlayerAdded:Connect(function(player)
        setupPlayer(player)
        player.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                trackHumanoid(player, hum)
            end
        end)
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then trackHumanoid(player, hum) end
        end
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        setupPlayer(p)
        if p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then trackHumanoid(p, hum) end
        end
    end

    RunService.Heartbeat:Connect(function(dt)
        for _, player in ipairs(Players:GetPlayers()) do
            local max = player:FindFirstChild("MaxEvasive")
            local cur = player:FindFirstChild("Evasive")
            if max and cur then
                cur.Value = math.min(cur.Value + EvasiveService.REGEN_RATE * dt, max.Value)
            end
        end
    end)
end

function EvasiveService.GetEvasive(player)
    local val = player and player:FindFirstChild("Evasive")
    return val and val.Value or 0
end

function EvasiveService.GetMaxEvasive(player)
    local val = player and player:FindFirstChild("MaxEvasive")
    return val and val.Value or EvasiveService.DEFAULT_MAX
end

function EvasiveService.AddEvasive(player, amount)
    if not RunService:IsServer() then return end
    local cur = player:FindFirstChild("Evasive")
    local max = player:FindFirstChild("MaxEvasive")
    if not cur or not max then return end
    cur.Value = math.clamp(cur.Value + (amount or 0), 0, max.Value)
end

function EvasiveService.Consume(player)
    if not RunService:IsServer() then return false end
    local cur = player:FindFirstChild("Evasive")
    local max = player:FindFirstChild("MaxEvasive")
    if not cur or not max then return false end
    if cur.Value < max.Value then return false end
    cur.Value = 0
    return true
end

function EvasiveService.SetActive(player, on)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetAttribute("EvasiveActive", on or nil)
    end
    if on then
        ACTIVE[player] = true
    else
        ACTIVE[player] = nil
    end
end

function EvasiveService.IsActive(player)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetAttribute("EvasiveActive") then
        return true
    end
    return false
end

-- Performs the evasive action: clear stun, dash and grant iframes
function EvasiveService.Activate(player, direction, dashVector)
    if not RunService:IsServer() then return end
    if not EvasiveService.Consume(player) then return end

    StunService:ClearStun(player)
    StunService.LockAttacker(player, 1.5)

    EvasiveService.SetActive(player, true)
    DashModule.ExecuteDash(player, direction, dashVector)

    task.delay(1.5, function()
        EvasiveService.SetActive(player, false)
    end)
end

return EvasiveService

