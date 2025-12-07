local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage.Modules.Config.WorldConfig)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishingHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.fromOffset(0, 12)
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextStrokeTransparency = 0.5
title.TextStrokeColor3 = Color3.fromRGB(40, 40, 40)
title.TextSize = 32
title.Text = "Grandline: Tides of Serenity"
title.Parent = screenGui

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, 0, 0, 24)
subtitle.Position = UDim2.fromOffset(0, 44)
subtitle.Font = Enum.Font.Gotham
subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitle.TextStrokeTransparency = 0.7
subtitle.TextStrokeColor3 = Color3.fromRGB(30, 30, 30)
subtitle.TextSize = 20
subtitle.Text = "Prototype: explore the islands and look for glowing fishing hotspots"
subtitle.Parent = screenGui

local controls = Instance.new("TextLabel")
controls.BackgroundTransparency = 1
controls.Size = UDim2.new(0, 360, 0, 60)
controls.Position = UDim2.new(0, 12, 1, -72)
controls.Font = Enum.Font.Gotham
controls.TextColor3 = Color3.fromRGB(255, 255, 255)
controls.TextStrokeTransparency = 0.7
controls.TextStrokeColor3 = Color3.fromRGB(30, 30, 30)
controls.TextSize = 16
controls.TextWrapped = true
controls.TextXAlignment = Enum.TextXAlignment.Left
controls.TextYAlignment = Enum.TextYAlignment.Top
controls.Text = table.concat({
    "WASD/Thumbstick: roam the isometric islands",
    "",
    "Fishing hotspots glow amber; future updates will let you cast lines and haul in the catch!",
}, "\n")
controls.Parent = screenGui

local function heartbeat()
    subtitle.Text = string.format(
        "Camera: %.0f deg pitch, %.0f deg yaw | Loaded tiles: %dx%d",
        WorldConfig.Camera.PitchDeg,
        WorldConfig.Camera.YawDeg,
        WorldConfig.Tiles.ActiveRadius * 2 + 1,
        WorldConfig.Tiles.ActiveRadius * 2 + 1
    )
end

game:GetService("RunService").Heartbeat:Connect(heartbeat)
