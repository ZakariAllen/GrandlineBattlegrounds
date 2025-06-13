local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Modules.Config.Config)

local minutes = Config.GameSettings.DayNightCycleMinutes or 15
local cycleSeconds = minutes * 60

local function computeClockTime()
    local utc = os.date("!*t")
    local secondsToday = utc.hour * 3600 + utc.min * 60 + utc.sec
    local cyclePos = secondsToday % cycleSeconds
    return (cyclePos / cycleSeconds) * 24
end

RunService.Heartbeat:Connect(function()
    Lighting.ClockTime = computeClockTime()
end)

print("[DayNightCycle] Initialized (", minutes, "min cycle)")
