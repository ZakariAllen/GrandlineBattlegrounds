--ReplicatedStorage.Modules.Client.PlayerGuiManager

local PlayerGuiManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui
local healthBar
local staminaBar
local hakiBar
local ultBar
local evasiveBar
local healthText
local staminaText
local hakiText
local baseSize
local staminaBase
local hakiBase
local ultBase
local evasiveBase
local ultColor
local connection
local staminaConnection
local hakiConnection
local ultConnection
local evasiveConnection
local rainbowConnection

-- Clone the existing PlayerGUI from ReplicatedFirst.Assets
local function ensureGui()
    if screenGui then return end

    local assets = ReplicatedFirst
        :WaitForChild("Assets")
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
    local ultFrame = screenGui:FindFirstChild("Ult")
    local evasiveObj = screenGui:FindFirstChild("EvasiveBar", true)

    healthBar = hpFrame:WaitForChild("Middle"):WaitForChild("HealthBar")
    staminaBar = stamFrame:WaitForChild("Middle"):WaitForChild("StamBar")
    if hakiFrame then
        hakiBar = hakiFrame:WaitForChild("Middle"):WaitForChild("HakiBar")
    end
    if ultFrame then
        local middle = ultFrame:WaitForChild("Middle", 5)
        if middle then
            ultBar = middle:FindFirstChild("Ultbar") or middle:FindFirstChild("UltBar")
        end
    end
    if evasiveObj then
        evasiveBar = evasiveObj
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
    if ultBar and not ultBase then
        ultBase = ultBar.Size
        if ultBar:IsA("ImageLabel") or ultBar:IsA("ImageButton") then
            ultColor = ultBar.ImageColor3
        else
            ultColor = ultBar.BackgroundColor3
        end
    end
    if evasiveBar and not evasiveBase then
        evasiveBase = evasiveBar.Size
    end
end

function PlayerGuiManager.Show()
    ensureGui()
    screenGui.Enabled = true
end

function PlayerGuiManager.Hide()
    -- Ensure the GUI exists so it can be hidden immediately when the
    -- menu script starts. This preloads the interface upfront instead
    -- of waiting until the player selects a style.
    ensureGui()
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

function PlayerGuiManager.BindUlt(ultValue)
    if ultConnection then
        ultConnection:Disconnect()
        ultConnection = nil
    end
    if rainbowConnection then
        rainbowConnection:Disconnect()
        rainbowConnection = nil
    end

    if not ultValue then return end

    ensureGui()

    local parent = ultValue.Parent
    local maxVal = parent and parent:FindFirstChild("MaxUlt")
    local hue = 0

    local function update()
        if not ultBase or not ultBar then return end
        local max = maxVal and maxVal.Value or 100
        local ratio = math.clamp(ultValue.Value / max, 0, 1)
        ultBar.Size = UDim2.new(
            ultBase.X.Scale * ratio,
            ultBase.X.Offset * ratio,
            ultBase.Y.Scale,
            ultBase.Y.Offset
        )

        if ratio >= 1 then
            if not rainbowConnection then
                rainbowConnection = RunService.RenderStepped:Connect(function(dt)
                    hue = (hue + dt * 0.3) % 1
                    local col = Color3.fromHSV(hue, 1, 1)
                    if ultBar:IsA("ImageLabel") or ultBar:IsA("ImageButton") then
                        ultBar.ImageColor3 = col
                    else
                        ultBar.BackgroundColor3 = col
                    end
                end)
            end
        else
            if rainbowConnection then
                rainbowConnection:Disconnect()
                rainbowConnection = nil
                if ultBar:IsA("ImageLabel") or ultBar:IsA("ImageButton") then
                    ultBar.ImageColor3 = ultColor
                else
                    ultBar.BackgroundColor3 = ultColor
                end
            end
        end
    end

    update()
    ultConnection = ultValue.Changed:Connect(update)
    if maxVal then
        maxVal.Changed:Connect(update)
    end
end

function PlayerGuiManager.BindEvasive(evasiveValue)
    if evasiveConnection then
        evasiveConnection:Disconnect()
        evasiveConnection = nil
    end

    if not evasiveValue then return end

    ensureGui()

    local parent = evasiveValue.Parent
    local maxVal = parent and parent:FindFirstChild("MaxEvasive")

    local function update()
        if not evasiveBar or not evasiveBase then return end
        local max = maxVal and maxVal.Value or 100
        local ratio = math.clamp(evasiveValue.Value / max, 0, 1)
        evasiveBar.Size = UDim2.new(
            evasiveBase.X.Scale * ratio,
            evasiveBase.X.Offset * ratio,
            evasiveBase.Y.Scale,
            evasiveBase.Y.Offset
        )
    end

    update()
    evasiveConnection = evasiveValue.Changed:Connect(update)
    if maxVal then
        maxVal.Changed:Connect(update)
    end
end

-- Preload the GUI once on module load to avoid delays
ensureGui()

return PlayerGuiManager

