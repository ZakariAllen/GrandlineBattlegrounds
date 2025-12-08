--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local rng = Random.new()

local Modules = ReplicatedStorage:WaitForChild("Modules")
local FishingRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FishingRemotes"))
local MiniGameConfig = require(Modules.Fishing:WaitForChild("MiniGameConfig"))
local FishCatalog = require(Modules.Fishing:WaitForChild("FishCatalog"))
local uiFolder = Modules.Fishing:WaitForChild("UI")
local MinigameUIConfig = require(uiFolder:WaitForChild("MinigameUIConfig"))
local NotificationConfig = require(uiFolder:WaitForChild("NotificationConfig"))

local RarityDefinitions = FishCatalog.Rarities or {}

local screenGuiConfig = MinigameUIConfig.ScreenGui or {}
local rootConfig = MinigameUIConfig.Root or {}
local containerConfig = MinigameUIConfig.Container or {}
local captureTrackConfig = MinigameUIConfig.CaptureTrack or {}
local captureZoneConfig = MinigameUIConfig.CaptureZone or {}
local fishMarkerConfig = MinigameUIConfig.FishMarker or {}
local progressMeterConfig = MinigameUIConfig.ProgressMeter or {}
local progressFillConfig = MinigameUIConfig.ProgressFill or {}
local progressLabelConfig = MinigameUIConfig.ProgressLabel or {}
local debugPanelConfig = MinigameUIConfig.DebugPanel or {}
local notificationGui: ScreenGui?
local notificationContainer: Frame?

local function applyCorner(guiObject: GuiObject, radius: UDim?)
    if not radius then
        return
    end
    local existing = guiObject:FindFirstChildOfClass("UICorner")
    if existing then
        existing.CornerRadius = radius
        return
    end
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius
    corner.Parent = guiObject
end

local function ensureNotificationGui()
    if notificationGui and notificationGui.Parent then
        return
    end
    local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
    notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "FishingNotifications"
    notificationGui.ResetOnSpawn = false
    notificationGui.Parent = playerGui

    notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "NotificationContainer"
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.AnchorPoint = Vector2.new(1, 0)
    notificationContainer.Position = UDim2.fromScale(0.98, 0.17)
    notificationContainer.Size = UDim2.fromScale(0.28, 0.65)
    notificationContainer.Parent = notificationGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = notificationContainer
end

local function applyStroke(guiObject: GuiObject, strokeConfig: any?): UIStroke?
    if not strokeConfig then
        return nil
    end
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = strokeConfig.Thickness or 1
    stroke.Color = strokeConfig.Color or Color3.fromRGB(255, 255, 255)
    stroke.Transparency = strokeConfig.Transparency or 0
    stroke.ApplyStrokeMode = strokeConfig.ApplyStrokeMode or Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = strokeConfig.LineJoinMode or Enum.LineJoinMode.Round
    stroke.Parent = guiObject
    return stroke
end

local function applyTextProperties(label: TextLabel, props: any?)
    if not props then
        return
    end
    if props.Font then
        label.Font = props.Font
    end
    if props.TextColor3 then
        label.TextColor3 = props.TextColor3
    end
    if props.TextScaled ~= nil then
        label.TextScaled = props.TextScaled
    end
    if props.TextSize then
        label.TextSize = props.TextSize
    end
    if props.BackgroundTransparency ~= nil then
        label.BackgroundTransparency = props.BackgroundTransparency
    end
end

local function sign(num: number): number
    if num > 0 then
        return 1
    elseif num < 0 then
        return -1
    end
    return 0
end

type MovementState = {
    totalDistance: number,
    duration: number,
    elapsed: number,
    lastOffset: number,
    easingStyle: Enum.EasingStyle,
    easingDirection: Enum.EasingDirection,
}

local ui: ScreenGui?
local captureFrame: Frame?
local fishFrame: Frame?
local meterFill: Frame?
local captureStroke: UIStroke?
local fishStroke: UIStroke?
local trackStroke: UIStroke?
local debugPanel: Frame?
local debugLabel: TextLabel?
local minigameActive = false
local hotbarSuppressed = false
local hotbarPrevEnabled = true
local connection: RBXScriptConnection?

local function destroyUI()
    if ui then
        ui:Destroy()
    end
    ui = nil
    captureFrame = nil
    fishFrame = nil
    meterFill = nil
    captureStroke = nil
    fishStroke = nil
    trackStroke = nil
    debugPanel = nil
    debugLabel = nil
end

local function suppressHotbar()
    if hotbarSuppressed then
        return
    end
    local ok, current = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack)
    if ok then
        hotbarPrevEnabled = current
    else
        hotbarPrevEnabled = true
    end
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    hotbarSuppressed = true
end

local function restoreHotbar()
    if not hotbarSuppressed then
        return
    end
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, hotbarPrevEnabled ~= false)
    hotbarSuppressed = false
end

local function buildUI()
    destroyUI()
    ui = Instance.new("ScreenGui")
    ui.Name = screenGuiConfig.Name or "FishingMinigame"
    ui.DisplayOrder = screenGuiConfig.DisplayOrder or 50
    ui.ResetOnSpawn = false
    ui.Parent = player:WaitForChild("PlayerGui")

    local container = Instance.new("Frame")
    container.Size = containerConfig.Size or UDim2.fromScale(0.55, 0.2)
    container.AnchorPoint = containerConfig.AnchorPoint or Vector2.new(0.5, 1)
    container.Position = containerConfig.Position or UDim2.fromScale(0.5, 0.9)
    container.BackgroundColor3 = containerConfig.BackgroundColor3 or Color3.fromRGB(10, 16, 26)
    container.BackgroundTransparency = containerConfig.BackgroundTransparency or 0.15

    local containerParent: Frame | ScreenGui = ui
    if rootConfig.Enabled then
        local rootFrame = Instance.new("Frame")
        rootFrame.Name = "MinigameRoot"
        rootFrame.Size = UDim2.fromScale(1, 1)
        rootFrame.Position = UDim2.fromScale(0.5, 0.5)
        rootFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        rootFrame.BackgroundColor3 = rootConfig.BackgroundColor3 or Color3.fromRGB(0, 0, 0)
        rootFrame.BackgroundTransparency = rootConfig.BackgroundTransparency or 1
        rootFrame.Parent = ui

        if rootConfig.AspectRatio then
            local aspect = Instance.new("UIAspectRatioConstraint")
            aspect.AspectRatio = rootConfig.AspectRatio
            aspect.Parent = rootFrame
        end

        containerParent = rootFrame
    end

    container.Parent = containerParent

    applyCorner(container, containerConfig.CornerRadius)
    if containerConfig.Padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = containerConfig.Padding
        padding.PaddingBottom = containerConfig.Padding
        padding.PaddingLeft = containerConfig.Padding
        padding.PaddingRight = containerConfig.Padding
        padding.Parent = container
    end

    local bar = Instance.new("Frame")
    bar.Size = captureTrackConfig.Size or UDim2.fromScale(0.8, 0.4)
    bar.AnchorPoint = captureTrackConfig.AnchorPoint or Vector2.new(0.5, 0.5)
    bar.Position = captureTrackConfig.Position or UDim2.fromScale(0.43, 0.5)
    bar.BackgroundColor3 = captureTrackConfig.BackgroundColor3 or Color3.fromRGB(21, 33, 49)
    bar.BackgroundTransparency = captureTrackConfig.BackgroundTransparency or 0
    bar.Parent = container
    applyCorner(bar, captureTrackConfig.CornerRadius)
    trackStroke = applyStroke(bar, captureTrackConfig.Stroke)

    captureFrame = Instance.new("Frame")
    captureFrame.Size = UDim2.fromScale(captureZoneConfig.WidthScale or 0.25, captureZoneConfig.HeightScale or 0.85)
    captureFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    captureFrame.Position = UDim2.new(0.5, 0, 0.5, captureZoneConfig.VerticalOffset or 0)
    captureFrame.BackgroundColor3 = captureZoneConfig.BackgroundColor3 or Color3.fromRGB(95, 179, 122)
    captureFrame.BackgroundTransparency = captureZoneConfig.BackgroundTransparency or 0.1
    captureFrame.Parent = bar
    applyCorner(captureFrame, captureZoneConfig.CornerRadius)
    captureStroke = applyStroke(captureFrame, captureZoneConfig.Stroke)

    fishFrame = Instance.new("Frame")
    fishFrame.Size = UDim2.fromScale(fishMarkerConfig.WidthScale or 0.05, fishMarkerConfig.HeightScale or 0.85)
    fishFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fishFrame.Position = UDim2.new(0.5, 0, 0.5, fishMarkerConfig.VerticalOffset or 0)
    fishFrame.BackgroundColor3 = fishMarkerConfig.BackgroundColor3 or Color3.fromRGB(255, 200, 64)
    fishFrame.BackgroundTransparency = fishMarkerConfig.BackgroundTransparency or 0
    fishFrame.Parent = bar
    applyCorner(fishFrame, fishMarkerConfig.CornerRadius)
    fishStroke = applyStroke(fishFrame, fishMarkerConfig.Stroke)

    local meter = Instance.new("Frame")
    meter.Size = progressMeterConfig.Size or UDim2.fromScale(0.55, 0.08)
    meter.AnchorPoint = progressMeterConfig.AnchorPoint or Vector2.new(0.5, 0.5)
    meter.Position = progressMeterConfig.Position or UDim2.fromScale(0.5, 0.15)
    meter.BackgroundColor3 = progressMeterConfig.BackgroundColor3 or Color3.fromRGB(20, 30, 48)
    meter.BackgroundTransparency = progressMeterConfig.BackgroundTransparency or 0
    meter.Parent = container
    applyCorner(meter, progressMeterConfig.CornerRadius)

    meterFill = Instance.new("Frame")
    meterFill.Size = UDim2.new(0, 0, progressFillConfig.HeightScale or 0.7, 0)
    meterFill.AnchorPoint = progressFillConfig.AnchorPoint or Vector2.new(0, 0.5)
    meterFill.Position = progressFillConfig.Position or UDim2.fromScale(0.05, 0.5)
    meterFill.BackgroundColor3 = progressFillConfig.BackgroundColor3 or Color3.fromRGB(91, 211, 255)
    meterFill.BackgroundTransparency = progressFillConfig.BackgroundTransparency or 0
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meter
    applyCorner(meterFill, progressFillConfig.CornerRadius)

    if progressLabelConfig and progressLabelConfig.Enabled then
        local label = Instance.new("TextLabel")
        label.Size = progressLabelConfig.Size or UDim2.fromScale(0.3, 0.06)
        label.AnchorPoint = progressLabelConfig.AnchorPoint or Vector2.new(0.5, 0.5)
        label.Position = progressLabelConfig.Position or UDim2.fromScale(0.87, 0.48)
        label.BackgroundTransparency = progressLabelConfig.BackgroundTransparency or 1
        label.Text = progressLabelConfig.Text or ""
        applyTextProperties(label, progressLabelConfig)
        label.Parent = container
    end

    if debugPanelConfig and debugPanelConfig.Enabled then
        debugPanel = Instance.new("Frame")
        debugPanel.Size = debugPanelConfig.Size or UDim2.fromScale(0.22, 0.12)
        debugPanel.AnchorPoint = debugPanelConfig.AnchorPoint or Vector2.new(0, 0)
        debugPanel.Position = debugPanelConfig.Position or UDim2.fromScale(0.02, 0.15)
        debugPanel.BackgroundColor3 = debugPanelConfig.BackgroundColor3 or Color3.fromRGB(15, 20, 30)
        debugPanel.BackgroundTransparency = debugPanelConfig.BackgroundTransparency or 0.2
        debugPanel.Parent = rootConfig.Enabled and containerParent or container
        applyCorner(debugPanel, debugPanelConfig.CornerRadius)

        if debugPanelConfig.Padding then
            local paddingValue = debugPanelConfig.Padding
            local function toUDim(value)
                if typeof(value) == "UDim" then
                    return value
                elseif typeof(value) == "number" then
                    return UDim.new(0, value)
                end
                return UDim.new(0, 0)
            end
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = toUDim(paddingValue)
            padding.PaddingBottom = toUDim(paddingValue)
            padding.PaddingLeft = toUDim(paddingValue)
            padding.PaddingRight = toUDim(paddingValue)
            padding.Parent = debugPanel
        end
        debugPanel.ZIndex = 10

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = (debugPanelConfig.Title and debugPanelConfig.Title.Text) or "Hooked Fish"
        titleLabel.ZIndex = 11
        applyTextProperties(titleLabel, debugPanelConfig.Title)
        titleLabel.Parent = debugPanel

        debugLabel = Instance.new("TextLabel")
        debugLabel.Size = UDim2.new(1, 0, 0.6, 0)
        debugLabel.Position = UDim2.new(0, 0, 0.4, 0)
        debugLabel.BackgroundTransparency = 1
        debugLabel.TextWrapped = true
        debugLabel.Text = "--"
        debugLabel.ZIndex = 11
        applyTextProperties(debugLabel, debugPanelConfig.Body)
        debugLabel.Parent = debugPanel
    else
        debugPanel = nil
        debugLabel = nil
    end

end

local function notify(text: string, isSuccess: boolean?)
    ensureNotificationGui()
    if not notificationContainer then
        return
    end

    local frame = Instance.new("Frame")
    local successColor = NotificationConfig.SuccessColor or Color3.fromRGB(92, 184, 143)
    local failureColor = NotificationConfig.FailureColor or Color3.fromRGB(206, 93, 93)
    frame.BackgroundColor3 = (isSuccess ~= false) and successColor or failureColor
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ClipsDescendants = true
    frame.Parent = notificationContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Font = Enum.Font.GothamMedium
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.TextTransparency = 1
    label.Parent = frame

    local tweenIn = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(frame, tweenIn, { BackgroundTransparency = 0.1 }):Play()
    TweenService:Create(label, tweenIn, { TextTransparency = 0 }):Play()

    local duration = NotificationConfig.Duration or 3
    task.delay(duration, function()
        if not frame.Parent then
            return
        end
        local tweenOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local fadeFrame = TweenService:Create(frame, tweenOut, { BackgroundTransparency = 1 })
        local fadeLabel = TweenService:Create(label, tweenOut, { TextTransparency = 1 })
        fadeFrame.Completed:Connect(function()
            frame:Destroy()
        end)
        fadeFrame:Play()
        fadeLabel:Play()
    end)
end

local function endMinigame(connection: RBXScriptConnection?, success: boolean)
    if connection then
        connection:Disconnect()
    end
    destroyUI()
    restoreHotbar()
    FishingRemotes.MinigameResult:FireServer({ success = success })
    minigameActive = false
end

local function playMinigame(data)
    if minigameActive then
        return
    end
    minigameActive = true
    suppressHotbar()
    buildUI()

    local fish = data.fish
    if debugLabel and fish then
        local rarityLabel = fish.rarity or data.rarity or "Unknown"
        debugLabel.Text = string.format("%s\n(%s)", fish.displayName or fish.id or "??", rarityLabel)
    elseif debugLabel then
        debugLabel.Text = "--"
    end

    local captureConfig = MiniGameConfig.Capture or {}
    local baseWidth = captureConfig.BaseWidth or captureZoneConfig.WidthScale or 0.25
    local controlStat = data.rod.control
    if controlStat == nil then
        controlStat = data.rod.captureControlBonus or 0
    end
    local widthMultiplier = math.max(0, 1 + (controlStat or 0))
    local captureWidth = baseWidth * widthMultiplier
    captureWidth = math.clamp(captureWidth, 0.05, 0.9)
    captureFrame.Size = UDim2.fromScale(captureWidth, captureZoneConfig.HeightScale or 0.85)
    local clampMin = captureWidth / 2
    local clampMax = math.max(clampMin, 1 - clampMin)
    local capturePos = 0.5
    local captureVel = 0

    local fishPos = 0.5

    local goal = data.captureGoal or captureConfig.Goal or MiniGameConfig.CaptureGoal
    local initialFillPercent = math.clamp(MiniGameConfig.InitialFillPercent or 0, 0, 1)
    local fill = goal * initialFillPercent
    local initialFillAmount = fill
    if meterFill then
        meterFill.Size = UDim2.new(math.clamp(fill / goal, 0, 1), 0, meterFill.Size.Y.Scale, 0)
    end
    local elapsed = 0
    local lockElapsed = 0
    local locked = true
    local unlockProgress = MiniGameConfig.UnlockProgressThreshold or 0.2
    local lockDuration = MiniGameConfig.LockDuration or 0

    local accelBase = MiniGameConfig.InputPower or 1.4
    local maxBarSpeed = MiniGameConfig.ControlMaxSpeed or 1
    local damping = MiniGameConfig.CaptureDamping or 6
    local bounceFactor = math.clamp(MiniGameConfig.CaptureBounceFactor or 0, 0, 1)
    local decayRate = captureConfig.Decay or MiniGameConfig.CaptureDecay or 0.5
    local riseRate = captureConfig.Rise or MiniGameConfig.CaptureRise or 1
    local markerMax = MiniGameConfig.MarkerMaxSpeed or 0.65
    local movementConfig = MiniGameConfig.Movement or {}
    local minorConfig = movementConfig.Minor or {}
    local majorConfig = movementConfig.Major or {}
    local rarityId = (fish and fish.rarity) or data.rarity
    local rarityMultipliers = {}
    if rarityId and RarityDefinitions then
        local rarityDef = RarityDefinitions[rarityId]
        if rarityDef then
            rarityMultipliers = rarityDef.Multipliers or {}
        end
    end

    local function getFishMultiplier(fieldName: string): number
        local value = (fish and fish[fieldName]) or 1
        if typeof(value) ~= "number" then
            return 1
        end
        return math.clamp(value, 0, 2)
    end

    local function applyRarityMultiplier(multiplier: number, fieldName: string): number
        local rarityValue = rarityMultipliers[fieldName]
        if typeof(rarityValue) == "number" then
            return multiplier * rarityValue
        end
        return multiplier
    end

    local minorFreq = applyRarityMultiplier(getFishMultiplier("MinorFreq"), "MinorFreq")
    local minorDist = applyRarityMultiplier(getFishMultiplier("MinorDist"), "MinorDist")
    local majorFreq = applyRarityMultiplier(getFishMultiplier("MajorFreq"), "MajorFreq")
    local majorDist = applyRarityMultiplier(getFishMultiplier("MajorDist"), "MajorDist")

    local function sampleRange(value: any, defaultValue: number): number
        if typeof(value) == "NumberRange" then
            return rng:NextNumber(value.Min, value.Max)
        elseif typeof(value) == "number" then
            return value
        end
        return defaultValue
    end

    local function resolveEnumValue(enumType: any, value: any, fallback: EnumItem)
        if typeof(value) == "EnumItem" then
            return value
        end
        if typeof(value) == "string" then
            local ok, enumItem = pcall(function()
                return enumType[value]
            end)
            if ok and enumItem then
                return enumItem
            end
        end
        return fallback
    end

    local minorDistanceRange = minorConfig.Distance or NumberRange.new(0.02, 0.045)
    local minorDurationRange = minorConfig.Duration or NumberRange.new(0.12, 0.22)
    local minorFrequencyRange = minorConfig.Frequency or NumberRange.new(1.2, 2)
    local minorEaseStyle = resolveEnumValue(Enum.EasingStyle, minorConfig.EaseStyle, Enum.EasingStyle.Sine)
    local minorEaseDirection = resolveEnumValue(Enum.EasingDirection, minorConfig.EaseDirection, Enum.EasingDirection.InOut)

    local majorDistanceRange = majorConfig.Distance or NumberRange.new(0.18, 0.4)
    local majorDurationRange = majorConfig.Duration or NumberRange.new(0.35, 0.55)
    local majorFrequencyRange = majorConfig.Frequency or NumberRange.new(0.25, 0.45)
    local majorEaseStyle = resolveEnumValue(Enum.EasingStyle, majorConfig.EaseStyle, Enum.EasingStyle.Cubic)
    local majorEaseDirection = resolveEnumValue(Enum.EasingDirection, majorConfig.EaseDirection, Enum.EasingDirection.Out)

    local activeMinorMove: MovementState? = nil
    local activeMajorMove: MovementState? = nil
    local minorTimer = 0
    local majorTimer = 0
    local minorInterval = math.huge
    local majorInterval = math.huge

    local function clampMovementDistance(distance: number): number
        if distance > 0 then
            local maxRight = math.max(clampMax - fishPos, 0)
            local clamped = math.min(distance, maxRight)
            if clamped <= 1e-4 then
                clamped = math.min(maxRight, 0.025)
            end
            return clamped
        else
            local maxLeft = math.min(clampMin - fishPos, 0)
            local clamped = math.max(distance, maxLeft)
            if math.abs(clamped) <= 1e-4 then
                clamped = math.max(maxLeft, -0.025)
            end
            return clamped
        end
    end

    local function beginMovement(
        distance: number,
        duration: number,
        easingStyle: Enum.EasingStyle,
        easingDirection: Enum.EasingDirection,
        kind: "minor" | "major"
    )
        local clampedDistance = clampMovementDistance(distance)
        if math.abs(clampedDistance) <= 1e-4 or duration <= 1e-4 then
            if kind == "minor" then
                activeMinorMove = nil
            else
                activeMajorMove = nil
            end
            return
        end
        local state: MovementState = {
            totalDistance = clampedDistance,
            duration = duration,
            elapsed = 0,
            lastOffset = 0,
            easingStyle = easingStyle,
            easingDirection = easingDirection,
        }
        if kind == "minor" then
            activeMinorMove = state
        else
            activeMajorMove = state
        end
    end

    local function stepMovement(kind: "minor" | "major", dt: number): number
        local state = (kind == "minor") and activeMinorMove or activeMajorMove
        if not state then
            return 0
        end
        state.elapsed += dt
        local alpha = state.duration > 1e-4 and math.clamp(state.elapsed / state.duration, 0, 1) or 1
        local eased = TweenService:GetValue(alpha, state.easingStyle, state.easingDirection)
        local offset = eased * state.totalDistance
        local delta = offset - state.lastOffset
        state.lastOffset = offset
        if alpha >= 1 - 1e-4 then
            if kind == "minor" then
                activeMinorMove = nil
            else
                activeMajorMove = nil
            end
        end
        return delta
    end

    local function chooseDirection(kind: "minor" | "major"): number
        local leftDistance = math.max(fishPos - clampMin, 0)
        local rightDistance = math.max(clampMax - fishPos, 0)
        local span = clampMax - clampMin
        if span <= 1e-4 then
            return rng:NextNumber(-1, 1) >= 0 and 1 or -1
        end

        local edgeThreshold = span * 0.1
        if kind == "major" then
            if leftDistance <= edgeThreshold and rightDistance > leftDistance then
                return 1
            elseif rightDistance <= edgeThreshold and leftDistance > rightDistance then
                return -1
            end
        end

        local imbalance = (leftDistance - rightDistance) / span
        local biasScale = (kind == "minor") and 0.1 or 0.2
        local threshold = math.clamp(0.5 + imbalance * biasScale, 0.05, 0.95)
        return rng:NextNumber() < threshold and 1 or -1
    end

    local function triggerMinorMove()
        if rng:NextNumber() < 0.25 then
            return
        end
        if minorDist <= 1e-4 then
            return
        end
        local distance = sampleRange(minorDistanceRange, 0.02) * minorDist
        if distance <= 1e-4 then
            return
        end
        local duration = math.max(sampleRange(minorDurationRange, 0.15), 0.05)
        local delta = clampMovementDistance(distance * chooseDirection("minor"))
        if math.abs(delta) <= 1e-4 then
            return
        end
        beginMovement(delta, duration, minorEaseStyle, minorEaseDirection, "minor")
    end

    local function triggerMajorMove()
        if rng:NextNumber() < 0.5 then
            return
        end
        if majorDist <= 1e-4 then
            return
        end
        local distance = sampleRange(majorDistanceRange, 0.25) * majorDist
        if distance <= 1e-4 then
            return
        end
        local duration = math.max(sampleRange(majorDurationRange, 0.4), 0.1)
        local delta = clampMovementDistance(distance * chooseDirection("major"))
        if math.abs(delta) <= 1e-4 then
            return
        end
        beginMovement(delta, duration, majorEaseStyle, majorEaseDirection, "major")
    end

    local function refreshMinorInterval()
        local baseFrequency = sampleRange(minorFrequencyRange, 0)
        local scaledFrequency = baseFrequency * math.max(minorFreq, 0)
        if scaledFrequency <= 1e-4 then
            minorInterval = math.huge
        else
            minorInterval = 1 / scaledFrequency
        end
        minorTimer = 0
    end

    local function refreshMajorInterval()
        local baseFrequency = sampleRange(majorFrequencyRange, 0)
        local scaledFrequency = baseFrequency * math.max(majorFreq, 0)
        if scaledFrequency <= 1e-4 then
            majorInterval = math.huge
        else
            majorInterval = 1 / scaledFrequency
        end
        majorTimer = 0
    end

    refreshMinorInterval()
    refreshMajorInterval()
    triggerMinorMove()

    local emptyTimer = 0
    local allowProgressUnlock = false
    connection = RunService.RenderStepped:Connect(function(dt)
        elapsed += dt
        if locked then
            lockElapsed += dt
            local progressedBeyondInitial = fill > initialFillAmount + 1e-4
            if lockElapsed >= lockDuration then
                locked = false
            elseif allowProgressUnlock and progressedBeyondInitial and fill >= goal * unlockProgress then
                locked = false
            else
                if progressedBeyondInitial then
                    allowProgressUnlock = true
                end
                return
            end
        end

        local holding = UserInputService:IsKeyDown(Enum.KeyCode.Space)
            or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

        local accelDir = holding and 1 or -1
        local accel = accelBase * accelDir
        local directionInertia = MiniGameConfig.DirectionInertia or 1
        if directionInertia > 1 and accelDir ~= 0 and captureVel ~= 0 and sign(captureVel) ~= accelDir then
            local speedFraction = math.abs(captureVel) / math.max(maxBarSpeed, 1e-3)
            local curved = math.pow(math.clamp(speedFraction, 0, 1), 0.5)
            local clampedFraction = math.clamp(curved, 0.35, 1)
            local resistanceFactor = 1 + (directionInertia - 1) * clampedFraction
            accel /= resistanceFactor
        end

        captureVel += accel * dt
        local dampingSpeedFraction = math.abs(captureVel) / math.max(maxBarSpeed, 1e-3)
        local dampingCurved = math.pow(math.clamp(dampingSpeedFraction, 0, 1), 0.5)
        local dampingScale = math.clamp(dampingCurved, 0.35, 1)
        captureVel *= math.clamp(1 - damping * dampingScale * dt, 0, 1)
        captureVel = math.clamp(captureVel, -maxBarSpeed, maxBarSpeed)

        local proposedPos = capturePos + captureVel * dt
        local clampedPos = math.clamp(proposedPos, clampMin, clampMax)
        if math.abs(clampedPos - proposedPos) > 1e-4 then
            capturePos = clampedPos
            if bounceFactor > 0 then
                if clampedPos <= clampMin + 1e-4 and captureVel < 0 then
                    captureVel = math.abs(captureVel) * bounceFactor
                elseif clampedPos >= clampMax - 1e-4 and captureVel > 0 then
                    captureVel = -math.abs(captureVel) * bounceFactor
                else
                    captureVel = 0
                end
            else
                captureVel = 0
            end
        else
            capturePos = clampedPos
        end

        captureFrame.Position = UDim2.fromScale(capturePos, 0.5)

        if minorInterval < math.huge then
            minorTimer += dt
            if minorTimer >= minorInterval then
                minorTimer -= minorInterval
                triggerMinorMove()
                refreshMinorInterval()
            end
        end
        if majorInterval < math.huge then
            majorTimer += dt
            if majorTimer >= majorInterval then
                majorTimer -= majorInterval
                triggerMajorMove()
                refreshMajorInterval()
            end
        end
        local minorDelta = stepMovement("minor", dt)
        local majorDelta = stepMovement("major", dt)
        local totalDelta = minorDelta + majorDelta
        if markerMax > 0 then
            local maxDelta = markerMax * dt
            totalDelta = math.clamp(totalDelta, -maxDelta, maxDelta)
        end
        local nextPos = fishPos + totalDelta
        if nextPos <= clampMin then
            fishPos = clampMin
            activeMinorMove = nil
            activeMajorMove = nil
        elseif nextPos >= clampMax then
            fishPos = clampMax
            activeMinorMove = nil
            activeMajorMove = nil
        else
            fishPos = nextPos
        end
        fishFrame.Position = UDim2.fromScale(fishPos, 0.5)

        local captureLeft = capturePos - captureWidth / 2
        local captureRight = capturePos + captureWidth / 2
        if fishPos >= captureLeft and fishPos <= captureRight then
            fill = math.min(goal, fill + riseRate * dt)
            if locked and fill > initialFillAmount then
                allowProgressUnlock = true
            end
        else
            fill = math.max(0, fill - decayRate * dt)
        end
        if meterFill then
            meterFill.Size = UDim2.new(math.clamp(fill / goal, 0, 1), 0, meterFill.Size.Y.Scale, 0)
        end

        if fill >= goal then
            endMinigame(connection, true)
            return
        end

        if fill <= 0.01 then
            emptyTimer += dt
            if emptyTimer >= (MiniGameConfig.FailGraceTime or 1) then
                endMinigame(connection, false)
                return
            end
        else
            emptyTimer = 0
        end

    end)
end

FishingRemotes.BeginMinigame.OnClientEvent:Connect(playMinigame)

FishingRemotes.CatchResult.OnClientEvent:Connect(function(result)
    if result.success then
        notify(string.format("Caught %s (+%d)", result.fish or "a fish", result.value or 0), true)
    else
        local reason = result.reason or "The fish escaped!"
        notify(reason, false)
    end
end)
