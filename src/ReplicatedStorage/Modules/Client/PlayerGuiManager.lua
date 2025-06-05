--ReplicatedStorage.Modules.Client.PlayerGuiManager

local PlayerGuiManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui
local healthBar
local baseSize
local connection

-- Clone the existing PlayerGUI from ReplicatedStorage.Assets
local function ensureGui()
    if screenGui then return end

    local assets = ReplicatedStorage:WaitForChild("Assets")
    local template = assets:WaitForChild("PlayerGUI")

    screenGui = PlayerGui:FindFirstChild("PlayerGUI")
    if not screenGui then
        screenGui = template:Clone()
        screenGui.Name = "PlayerGUI"
        screenGui.Parent = PlayerGui
    end
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false

    local guiFrame = screenGui:WaitForChild("GUI")
    healthBar = guiFrame:WaitForChild("HealthBarBGMiddle"):WaitForChild("HealthBar")
    if not baseSize then
        baseSize = healthBar.Size
    end
end

function PlayerGuiManager.Show()
    ensureGui()
    screenGui.Enabled = true
end

function PlayerGuiManager.Hide()
    if screenGui then
        screenGui.Enabled = false
    end
end

function PlayerGuiManager.BindHumanoid(humanoid)
    if connection then
        connection:Disconnect()
        connection = nil
    end

    if not humanoid then return end

    ensureGui()

    local function update()
        if not baseSize then return end

        local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        healthBar.Size = UDim2.new(
            baseSize.X.Scale * ratio,
            baseSize.X.Offset * ratio,
            baseSize.Y.Scale,
            baseSize.Y.Offset
        )
    end

    update()
    connection = humanoid.HealthChanged:Connect(update)
end

return PlayerGuiManager

