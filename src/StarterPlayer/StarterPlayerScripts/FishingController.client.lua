--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local Modules = ReplicatedStorage:WaitForChild("Modules")
local FishingRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FishingRemotes"))
local CastConfig = require(Modules.Fishing:WaitForChild("CastConfig"))
local RodConfig = require(Modules.Fishing:WaitForChild("RodConfig"))
local CastUIConfig = require(Modules.Fishing.UI:WaitForChild("CastUIConfig"))

local castMeterConfig = CastUIConfig.CastMeter or {}
local castScreenGuiConfig = castMeterConfig.ScreenGui or {}
local castBarConfig = castMeterConfig.Bar or {}
local castFillConfig = castMeterConfig.Fill or {}
local gradeLabelConfig = castMeterConfig.GradeLabel or {}
local cursorConfig = CastUIConfig.Cursor or {}

local castGrades = CastConfig.Grades
local fallbackFillColor = (castGrades[#castGrades] and castGrades[#castGrades].color) or Color3.fromRGB(91, 211, 255)
local defaultFillColor = castFillConfig.Color or fallbackFillColor

local currentRod: Tool?
local charging = false
local castValue = 0
local castDirection = 1
local castConnection: RBXScriptConnection?
local minigameActive = false
local lineOut = false
local trackedTools: { [Tool]: boolean } = {}
local movementLocked = false
local inputHeld = false
local castingSlow = false
local storedWalkSpeed: number?
local storedJumpPower: number?
local storedJumpHeight: number?

local castInputTypes = {
    [Enum.UserInputType.MouseButton1] = true,
    [Enum.UserInputType.Touch] = true,
}

local castInputKeys = {
    [Enum.KeyCode.ButtonR2] = true,
    [Enum.KeyCode.ButtonR1] = true,
    [Enum.KeyCode.ButtonA] = true,
}

local castGui: ScreenGui?
local castFill: Frame?
local gradeLabel: TextLabel?
local cursorOverride = cursorConfig.EquippedIcon or "rbxasset://SystemCursors/Arrow"
local cursorDefault = cursorConfig.DefaultIcon or ""
local nextCastTime = 0

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

local function isGameplayUnlocked(): boolean
    return player:GetAttribute("GameplayUnlocked") == true
end

local function updateCursorIcon()
    if not mouse then
        return
    end
    if currentRod then
        mouse.Icon = cursorOverride
        UserInputService.MouseIconEnabled = true
    else
        mouse.Icon = cursorDefault
    end
end

local function ensureCastGui()
    if castGui then
        castGui.Enabled = true
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = castScreenGuiConfig.Name or "CastMeter"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = castScreenGuiConfig.DisplayOrder or 40
    gui.Parent = player:WaitForChild("PlayerGui")

    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = castBarConfig.Size or UDim2.fromScale(0.35, 0.04)
    bar.AnchorPoint = castBarConfig.AnchorPoint or Vector2.new(0.5, 1)
    bar.Position = castBarConfig.Position or UDim2.fromScale(0.5, 0.92)
    bar.BackgroundColor3 = castBarConfig.BackgroundColor3 or Color3.fromRGB(24, 34, 54)
    bar.BackgroundTransparency = castBarConfig.BackgroundTransparency or 0
    bar.Parent = gui
    applyCorner(bar, castBarConfig.CornerRadius)

    castFill = Instance.new("Frame")
    castFill.Size = UDim2.fromScale(0, 1)
    castFill.BackgroundColor3 = defaultFillColor
    castFill.BorderSizePixel = 0
    castFill.BackgroundTransparency = castFillConfig.BackgroundTransparency or 0
    castFill.Parent = bar
    applyCorner(castFill, castFillConfig.CornerRadius)

    gradeLabel = Instance.new("TextLabel")
    gradeLabel.Size = gradeLabelConfig.Size or UDim2.fromScale(0.4, 0.05)
    gradeLabel.AnchorPoint = gradeLabelConfig.AnchorPoint or Vector2.new(0.5, 0.5)
    gradeLabel.Position = gradeLabelConfig.Position or UDim2.fromScale(0.5, 0.86)
    gradeLabel.Font = gradeLabelConfig.Font or Enum.Font.GothamBold
    gradeLabel.TextScaled = if gradeLabelConfig.TextScaled == nil then true else gradeLabelConfig.TextScaled
    gradeLabel.TextSize = gradeLabelConfig.TextSize or gradeLabel.TextSize
    gradeLabel.TextColor3 = gradeLabelConfig.TextColor3 or Color3.fromRGB(255, 255, 255)
    gradeLabel.BackgroundTransparency = gradeLabelConfig.BackgroundTransparency or 1
    gradeLabel.Text = ""
    gradeLabel.Parent = gui

    castGui = gui
end

local function hideCastGui()
    if castGui then
        castGui.Enabled = false
    end
end

local function updateCastFill(value: number, color: Color3?)
    if castFill then
        castFill.Size = UDim2.fromScale(math.clamp(value, 0, 1), 1)
        if color then
            castFill.BackgroundColor3 = color
        end
    end
end

local function getHumanoid(): Humanoid?
    local character = player.Character
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local CAST_SLOW_FACTOR = CastConfig.CastingMovementSlowFactor or 0.35
local function setCastingMovementSlow(enabled: boolean)
    if castingSlow == enabled then
        return
    end
    castingSlow = enabled
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    if enabled then
        if not storedWalkSpeed then
            storedWalkSpeed = humanoid.WalkSpeed
        end
        if humanoid.UseJumpPower then
            if not storedJumpPower then
                storedJumpPower = humanoid.JumpPower
            end
            humanoid.JumpPower = math.max(10, (storedJumpPower or humanoid.JumpPower) * CAST_SLOW_FACTOR)
        else
            if not storedJumpHeight then
                storedJumpHeight = humanoid.JumpHeight
            end
            humanoid.JumpHeight = math.max(3, (storedJumpHeight or humanoid.JumpHeight) * CAST_SLOW_FACTOR)
        end
        humanoid.WalkSpeed = math.max(2, (storedWalkSpeed or humanoid.WalkSpeed) * CAST_SLOW_FACTOR)
    else
        if storedWalkSpeed then
            humanoid.WalkSpeed = storedWalkSpeed
            storedWalkSpeed = nil
        end
        if humanoid.UseJumpPower then
            if storedJumpPower then
                humanoid.JumpPower = storedJumpPower
            end
            storedJumpPower = nil
        else
            if storedJumpHeight then
                humanoid.JumpHeight = storedJumpHeight
            end
            storedJumpHeight = nil
        end
    end
end

local function getGrade(value: number)
    local delta = math.abs(1 - value)
    for _, grade in ipairs(CastConfig.Grades) do
        if delta <= (grade.maxDelta or math.huge) then
            return grade
        end
    end
    return CastConfig.Grades[#CastConfig.Grades]
end

local function isCastInput(input: InputObject): boolean
    if castInputTypes[input.UserInputType] then
        return true
    end
    if string.sub(input.UserInputType.Name, 1, 7) == "Gamepad" then
        return castInputKeys[input.KeyCode] == true
    end
    return false
end

local function resolveCastTarget(rodId: string, power: number): Vector3?
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local rod = RodConfig[rodId]
    if not hrp or not rod then
        return nil
    end

    local minPower = CastConfig.Meter.MinimumPower or 0.2
    local clampedPower = math.clamp(power, minPower, 1)
    local maxDistance = (rod.castRange or 150) * clampedPower

    local forward = hrp.CFrame.LookVector
    local flat = Vector3.new(forward.X, 0, forward.Z)
    if flat.Magnitude < 1e-3 then
        flat = Vector3.new(0, 0, -1)
    else
        flat = flat.Unit
    end

    local horizontalTarget = hrp.Position + flat * maxDistance
    local rayOrigin = horizontalTarget + Vector3.new(0, 60, 0)
    local rayDirection = Vector3.new(0, -300, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    params.IgnoreWater = false

    local result = Workspace:Raycast(rayOrigin, rayDirection, params)
    if result then
        return result.Position
    end

    return horizontalTarget
end

local function showGrade(grade)
    if not gradeLabel then
        return
    end
    gradeLabel.Text = grade.label or ""
    gradeLabel.TextColor3 = grade.color or Color3.fromRGB(255, 255, 255)
    task.delay(CastConfig.Meter.GradeDisplayDuration or 1, function()
        if gradeLabel then
            gradeLabel.Text = ""
        end
        hideCastGui()
    end)
end

local function stopCharging(sendCast: boolean)
    if castConnection then
        castConnection:Disconnect()
        castConnection = nil
    end
    if not charging then
        hideCastGui()
        return
    end
    charging = false
    setCastingMovementSlow(false)

    local rodId = currentRod and currentRod:GetAttribute("RodId")
    if not rodId then
        hideCastGui()
        return
    end

    if os.clock() < nextCastTime then
        hideCastGui()
        return
    end

    if not sendCast then
        hideCastGui()
        return
    end

    local grade = getGrade(castValue)
    showGrade(grade)

    local targetPos = resolveCastTarget(rodId, castValue)
    if not targetPos then
        hideCastGui()
        return
    end

    local payload = {
        castPower = castValue,
        luckBonus = math.clamp(grade.luckBonus or 0, 0, CastConfig.MaxLuckBonus or 0.1),
        gradeLabel = grade.label,
    }
    FishingRemotes.RequestCast:FireServer(rodId, targetPos, payload)
end

local function startCharging(tool: Tool?)
    if charging or minigameActive or lineOut or not isGameplayUnlocked() then
        return
    end
    if os.clock() < nextCastTime then
        return
    end
    local activeRod = tool or currentRod
    local rodId = activeRod and activeRod:GetAttribute("RodId")
    if not rodId then
        return
    end
    currentRod = activeRod

    charging = true
    castValue = 0
    castDirection = 1
    ensureCastGui()
    setCastingMovementSlow(true)
    updateCastFill(0, defaultFillColor)
    if gradeLabel then
        gradeLabel.Text = ""
    end

    local cycle = CastConfig.Meter.CycleDuration or 1
    castConnection = RunService.RenderStepped:Connect(function(dt)
        local delta = dt / cycle
        castValue += castDirection * delta
        if castValue >= 1 then
            castValue = 1
            castDirection = -1
        elseif castValue <= 0 then
            castValue = 0
            castDirection = 1
        end
        local currentGrade = getGrade(castValue)
        updateCastFill(castValue, currentGrade.color)
    end)
end

local function cancelCharging()
    stopCharging(false)
end

local function setMovementLocked(lock: boolean)
    if movementLocked == lock then
        return
    end
    movementLocked = lock
    if lock then
        Controls:Disable()
    else
        Controls:Enable()
    end
end

local function updateMovementLock()
    setMovementLocked(lineOut or minigameActive)
end

local function updateLineOutState()
    lineOut = player:GetAttribute("FishingLineOut") == true
    if lineOut then
        cancelCharging()
        setCastingMovementSlow(false)
    end
    updateMovementLock()
end

player:GetAttributeChangedSignal("FishingLineOut"):Connect(updateLineOutState)
updateLineOutState()

local function updateCooldownState()
    nextCastTime = player:GetAttribute("NextCastTime") or 0
end

player:GetAttributeChangedSignal("NextCastTime"):Connect(updateCooldownState)
updateCooldownState()

local function trackTool(tool: Tool)
    if not tool:GetAttribute("RodId") or trackedTools[tool] then
        return
    end
    trackedTools[tool] = true
    tool.ManualActivationOnly = true

    tool.Equipped:Connect(function()
        currentRod = tool
        tool.Enabled = not minigameActive
        updateCursorIcon()
    end)

    tool.Unequipped:Connect(function()
        if minigameActive then
            -- Prevent putting the rod away mid-minigame; immediately re-equip.
            task.defer(function()
                if player.Character and tool.Parent ~= player.Character then
                    tool.Parent = player.Character
                end
                if player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:EquipTool(tool)
                    end
                end
            end)
            return
        end
        if lineOut then
            FishingRemotes.RequestReel:FireServer()
        end
        if currentRod == tool then
            currentRod = nil
            updateCursorIcon()
        end
        cancelCharging()
        setCastingMovementSlow(false)
        inputHeld = false
    end)
end

local function watchCharacter(character: Model)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            trackTool(child)
        end
    end
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            trackTool(child)
        end
    end)
end

if player.Character then
    watchCharacter(player.Character)
end
player.CharacterAdded:Connect(function(character)
    trackedTools = {}
    setCastingMovementSlow(false)
    watchCharacter(character)
end)
player.CharacterRemoving:Connect(function()
    currentRod = nil
    updateCursorIcon()
    cancelCharging()
    setCastingMovementSlow(false)
    inputHeld = false
end)

updateCursorIcon()

local function handleInputBegan(input: InputObject, processed: boolean)
    if processed or not currentRod then
        return
    end
    if not isCastInput(input) or inputHeld then
        return
    end
    inputHeld = true
    if minigameActive then
        return
    end
    if lineOut then
        FishingRemotes.RequestReel:FireServer()
        return
    end
    startCharging(currentRod)
end

local function handleInputEnded(input: InputObject)
    if not isCastInput(input) or not inputHeld then
        return
    end
    inputHeld = false
    if not currentRod then
        return
    end
    if lineOut then
        return
    end
    if minigameActive then
        cancelCharging()
        return
    end
    stopCharging(true)
end

UserInputService.InputBegan:Connect(handleInputBegan)
UserInputService.InputEnded:Connect(handleInputEnded)

FishingRemotes.BeginMinigame.OnClientEvent:Connect(function()
    minigameActive = true
    cancelCharging()
    if currentRod then
        currentRod.Enabled = false
    end
    updateMovementLock()
end)

FishingRemotes.CatchResult.OnClientEvent:Connect(function()
    minigameActive = false
    if currentRod then
        currentRod.Enabled = true
    end
    updateMovementLock()
end)
