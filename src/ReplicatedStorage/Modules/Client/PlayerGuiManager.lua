--ReplicatedStorage.Modules.Client.PlayerGuiManager

local PlayerGuiManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local ExperienceService = require(ReplicatedStorage.Modules.Stats.ExperienceService)
local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui
local healthBar
local staminaBar
local hakiBar
local ultBar
local evasiveBar
local xpBar
local healthText
local staminaText
local hakiText
local xpText
local levelText
local baseSize
local staminaBase
local hakiBase
local ultBase
local evasiveBase
local xpBase
local ultColor
local connection
local staminaConnection
local hakiConnection
local ultConnection
local evasiveConnection
local xpConnection
local levelConnection
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

    -- Search for the evasive bar using the new container structure
    local evasiveObj
    local evasiveFrame = screenGui:FindFirstChild("Evasive")
    if evasiveFrame then
        local evasiveBG = evasiveFrame:FindFirstChild("BG")
        if evasiveBG then
            evasiveObj = evasiveBG:FindFirstChild("Bar")
        end
    end
    -- Fallback to the legacy name for compatibility
    if not evasiveObj then
        evasiveObj = screenGui:FindFirstChild("EvasiveBar", true)
    end
    -- The XP frame was previously named "Level".  Support both names.
    local xpFrame = screenGui:FindFirstChild("XP") or screenGui:FindFirstChild("Level")

    healthBar = hpFrame:WaitForChild("BG"):WaitForChild("Bar")
    staminaBar = stamFrame:WaitForChild("BG"):WaitForChild("Bar")
    if hakiFrame then
        hakiBar = hakiFrame:WaitForChild("BG"):WaitForChild("Bar")
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
    local xpBG
    if xpFrame then
        xpBG = xpFrame:FindFirstChild("BG") or xpFrame
        xpBar = xpBG:FindFirstChild("Bar")
        -- The XP label and level text are direct children of the XP frame
        -- rather than inside the BG container
        xpText = xpFrame:FindFirstChild("XPLabel") or (xpBG and xpBG:FindFirstChild("XPLabel"))
        levelText = xpFrame:FindFirstChild("Level") or (xpBG and xpBG:FindFirstChild("Level"))
    end

    healthText = hpFrame:FindFirstChild("Value")
    staminaText = stamFrame:FindFirstChild("Value")
    if hakiFrame then
        hakiText = hakiFrame:FindFirstChild("Value")
    end
    if not levelText then
        levelText = hpFrame:FindFirstChild("Level")
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
    if xpBar and not xpBase then
        xpBase = xpBar.Size
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

function PlayerGuiManager.BindXP(xpValue)
    if xpConnection then
        xpConnection:Disconnect()
        xpConnection = nil
    end

    if not xpValue then return end

    ensureGui()

    local parent = xpValue.Parent
    local levelVal = parent and parent:FindFirstChild("Level")

    local function update()
        local level = levelVal and levelVal.Value or 1
        local needed = ExperienceService.XPForLevel(level)

        if xpBar and xpBase then
            local ratio = math.clamp(xpValue.Value / needed, 0, 1)
            xpBar.Size = UDim2.new(
                xpBase.X.Scale * ratio,
                xpBase.X.Offset * ratio,
                xpBase.Y.Scale,
                xpBase.Y.Offset
            )
        end

        if xpText then
            xpText.Text = string.format("%d / %d", xpValue.Value, needed)
        end
    end

    update()
    xpConnection = xpValue.Changed:Connect(update)
    if levelVal then
        levelVal.Changed:Connect(update)
    end
end

function PlayerGuiManager.BindLevel(levelValue)
    if levelConnection then
        levelConnection:Disconnect()
        levelConnection = nil
    end

    if not levelValue then return end

    ensureGui()

    local function update()
        if levelText then
            levelText.Text = string.format("Level %d", levelValue.Value)
        end
    end

    update()
    levelConnection = levelValue.Changed:Connect(update)
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

