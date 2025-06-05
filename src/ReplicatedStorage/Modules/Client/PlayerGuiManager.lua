--ReplicatedStorage.Modules.Client.PlayerGuiManager

local PlayerGuiManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui
local healthBar
local staminaBar
local baseSize
local staminaBase
local connection
local staminaConnection

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
    staminaBar = guiFrame:WaitForChild("StamBarBGMiddle"):WaitForChild("StamBar")
    if not baseSize then
        baseSize = healthBar.Size
    end
    if not staminaBase then
        staminaBase = staminaBar.Size
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

function PlayerGuiManager.BindStamina(staminaValue)
    if staminaConnection then
        staminaConnection:Disconnect()
        staminaConnection = nil
    end

    if not staminaValue then return end

    ensureGui()

    local parent = staminaValue.Parent
    local maxVal = parent and parent:FindFirstChild("MaxStamina")

    local function update()
        if not staminaBase then return end
        local max = maxVal and maxVal.Value or StaminaService and StaminaService.DEFAULT_MAX or 250
        local ratio = math.clamp(staminaValue.Value / max, 0, 1)
        staminaBar.Size = UDim2.new(
            staminaBase.X.Scale * ratio,
            staminaBase.X.Offset * ratio,
            staminaBase.Y.Scale,
            staminaBase.Y.Offset
        )
    end

    update()
    staminaConnection = staminaValue.Changed:Connect(update)
    if maxVal then
        maxVal.Changed:Connect(update)
    end
end

return PlayerGuiManager

