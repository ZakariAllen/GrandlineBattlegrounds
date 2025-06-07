--ReplicatedStorage.Modules.Stats.HakiService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HakiService = {}

HakiService.DEFAULT_MAX = 240
HakiService.DRAIN_RATE = 1      -- per second
HakiService.REGEN_RATE = 5       -- per second

local function setupPlayer(player)
    local max = player:FindFirstChild("MaxHaki")
    if not max then
        max = Instance.new("NumberValue")
        max.Name = "MaxHaki"
        max.Value = HakiService.DEFAULT_MAX
        max.Parent = player
    end

    local cur = player:FindFirstChild("Haki")
    if not cur then
        cur = Instance.new("NumberValue")
        cur.Name = "Haki"
        cur.Value = max.Value
        cur.Parent = player
    end

    local active = player:FindFirstChild("HakiActive")
    if not active then
        active = Instance.new("BoolValue")
        active.Name = "HakiActive"
        active.Value = false
        active.Parent = player
    end
end

function HakiService.IsActive(player)
    local flag = player and player:FindFirstChild("HakiActive")
    return flag and flag.Value or false
end

function HakiService.GetHaki(player)
    local val = player and player:FindFirstChild("Haki")
    return val and val.Value or 0
end

function HakiService.GetMaxHaki(player)
    local val = player and player:FindFirstChild("MaxHaki")
    return val and val.Value or HakiService.DEFAULT_MAX
end

function HakiService.Toggle(player, on)
    if not RunService:IsServer() then return false end
    local active = player:FindFirstChild("HakiActive")
    local cur = player:FindFirstChild("Haki")
    if not active or not cur then return false end
    if on then
        if cur.Value <= 0 then return false end
        active.Value = true
    else
        active.Value = false
    end
    return true
end

if RunService:IsServer() then
    Players.PlayerAdded:Connect(setupPlayer)
    for _, p in ipairs(Players:GetPlayers()) do
        setupPlayer(p)
    end

    RunService.Heartbeat:Connect(function(dt)
        for _, player in ipairs(Players:GetPlayers()) do
            local max = player:FindFirstChild("MaxHaki")
            local cur = player:FindFirstChild("Haki")
            local active = player:FindFirstChild("HakiActive")
            if not max or not cur or not active then
                continue
            end

            if active.Value then
                cur.Value = math.max(cur.Value - HakiService.DRAIN_RATE * dt, 0)
                if cur.Value <= 0 then
                    active.Value = false
                end
            else
                cur.Value = math.min(cur.Value + HakiService.REGEN_RATE * dt, max.Value)
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(p)
        -- cleanup placeholder (not strictly necessary)
    end)
end

return HakiService

