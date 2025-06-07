--ReplicatedStorage.Modules.Client.PlayerGuiManager

local PlayerGuiManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui
local healthBar
local staminaBar
local hakiBar
local healthText
local staminaText
local hakiText
local baseSize
local staminaBase
local hakiBase
local connection
local staminaConnection
local hakiConnection

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

    -- The HP and stamina frames are now direct children of PlayerGUI rather than
    -- being contained under an extra "GUI" frame
    local hpFrame = screenGui:WaitForChild("HP")
    local stamFrame = screenGui:WaitForChild("Stam")
    local hakiFrame = screenGui:FindFirstChild("Haki")

    healthBar = hpFrame:WaitForChild("Middle"):WaitForChild("HealthBar")
    staminaBar = stamFrame:WaitForChild("Middle"):WaitForChild("StamBar")
    if hakiFrame then
        hakiBar = hakiFrame:WaitForChild("Middle"):WaitForChild("HakiBar")
    end

    healthText = hpFrame:FindFirstChild("Value")
    staminaText = stamFrame:FindFirstChild("Value")
    if hakiFrame then
        hakiText = hakiFrame:FindFirstChild("Value")
    end
    if not baseSize then
        baseSize = healthBar.Size
    end
    if not staminaBase then
        staminaBase = staminaBar.Size
    end
    if hakiBar and not hakiBase then
        hakiBase = hakiBar.Size
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

        if healthText then
            healthText.Text = string.format("%d / %d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
        end
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
        local max = maxVal and maxVal.Value or StaminaService and StaminaService.DEFAULT_MAX or PlayerStats.Stamina
        local ratio = math.clamp(staminaValue.Value / max, 0, 1)
        staminaBar.Size = UDim2.new(
            staminaBase.X.Scale * ratio,
            staminaBase.X.Offset * ratio,
            staminaBase.Y.Scale,
            staminaBase.Y.Offset
        )

        if staminaText then
            staminaText.Text = string.format("%d / %d", math.floor(staminaValue.Value), math.floor(max))
        end
    end

    update()
    staminaConnection = staminaValue.Changed:Connect(update)
    if maxVal then
        maxVal.Changed:Connect(update)
    end
end

function PlayerGuiManager.BindHaki(hakiValue)
    if hakiConnection then
        hakiConnection:Disconnect()
        hakiConnection = nil
    end

    if not hakiValue then return end

    ensureGui()

    local parent = hakiValue.Parent
    local maxVal = parent and parent:FindFirstChild("MaxHaki")

    local function update()
        if not hakiBase or not hakiBar then return end
        local max = maxVal and maxVal.Value or HakiService and HakiService.DEFAULT_MAX or 240
        local ratio = math.clamp(hakiValue.Value / max, 0, 1)
        hakiBar.Size = UDim2.new(
            hakiBase.X.Scale * ratio,
            hakiBase.X.Offset * ratio,
            hakiBase.Y.Scale,
            hakiBase.Y.Offset
        )

        if hakiText then
            hakiText.Text = string.format("%d / %d", math.floor(hakiValue.Value), math.floor(max))
        end
    end

    update()
    hakiConnection = hakiValue.Changed:Connect(update)
    if maxVal then
        maxVal.Changed:Connect(update)
    end
end

return PlayerGuiManager

