local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local configFolder = ReplicatedStorage:WaitForChild("Config")
local CombatConfig = require(configFolder:WaitForChild("Combat"))
local UIConfig = require(configFolder:WaitForChild("UI"))
local BillboardConfig = require(configFolder:WaitForChild("Billboard"))

local combatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")

local currentTargetHumanoid
local hud = nil
local stamina = CombatConfig.Stamina.Max
local smoothedStamina = stamina
local blocking = false
local lastAttackTime = 0
local comboIndex = 1
local lastComboTime = 0
local comboVisibleUntil = 0

local billboards = {}

local function createHud()
    local playerGui = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatHUD"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local baseFrame = Instance.new("Frame")
    baseFrame.Name = "Base"
    baseFrame.BackgroundColor3 = UIConfig.Theme.Primary
    baseFrame.BackgroundTransparency = 0.15
    baseFrame.BorderSizePixel = 0
    baseFrame.Size = UDim2.new(1, -(UIConfig.Hud.Padding * 2), 0, UIConfig.Hud.Height)
    baseFrame.Position = UDim2.new(0, UIConfig.Hud.Padding, 1, -(UIConfig.Hud.Height + UIConfig.Hud.Padding))
    baseFrame.Parent = screenGui

    local baseCorner = Instance.new("UICorner")
    baseCorner.CornerRadius = UIConfig.Hud.CornerRadius
    baseCorner.Parent = baseFrame

    local baseStroke = Instance.new("UIStroke")
    baseStroke.Thickness = 2
    baseStroke.Color = UIConfig.Theme.Secondary
    baseStroke.Transparency = 0.35
    baseStroke.Parent = baseFrame

    local staminaBar = Instance.new("Frame")
    staminaBar.Name = "StaminaBar"
    staminaBar.AnchorPoint = Vector2.new(0, 0.5)
    staminaBar.Position = UDim2.new(0, UIConfig.Hud.Padding, 0.5, 0)
    staminaBar.Size = UIConfig.Hud.StaminaBarSize
    staminaBar.BackgroundColor3 = UIConfig.Theme.Secondary
    staminaBar.BorderSizePixel = 0
    staminaBar.Parent = baseFrame

    local staminaCorner = Instance.new("UICorner")
    staminaCorner.CornerRadius = UIConfig.Hud.CornerRadius
    staminaCorner.Parent = staminaBar

    local staminaFill = Instance.new("Frame")
    staminaFill.Name = "Fill"
    staminaFill.AnchorPoint = Vector2.new(0, 0.5)
    staminaFill.Position = UDim2.new(0, 0, 0.5, 0)
    staminaFill.Size = UDim2.new(1, 0, 1, 0)
    staminaFill.BackgroundColor3 = UIConfig.Hud.StaminaHighColor or UIConfig.Theme.Accent
    staminaFill.BorderSizePixel = 0
    staminaFill.Parent = staminaBar

    local staminaFillCorner = Instance.new("UICorner")
    staminaFillCorner.CornerRadius = UIConfig.Hud.CornerRadius
    staminaFillCorner.Parent = staminaFill

    local staminaLabel = Instance.new("TextLabel")
    staminaLabel.Name = "StaminaLabel"
    staminaLabel.BackgroundTransparency = 1
    staminaLabel.Font = UIConfig.Fonts.Body
    staminaLabel.TextSize = 18
    staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
    staminaLabel.AnchorPoint = Vector2.new(0, 0.5)
    staminaLabel.Position = UDim2.new(0, UIConfig.Hud.Padding + UIConfig.Hud.StaminaBarSize.X.Offset + 12, 0.5, 0)
    staminaLabel.Size = UDim2.new(0, 200, 0, 24)
    staminaLabel.TextColor3 = UIConfig.Theme.Text
    staminaLabel.Parent = baseFrame

    local comboLabel = Instance.new("TextLabel")
    comboLabel.Name = "ComboLabel"
    comboLabel.BackgroundTransparency = 1
    comboLabel.Font = UIConfig.Fonts.Header
    comboLabel.TextSize = 18
    comboLabel.TextXAlignment = Enum.TextXAlignment.Left
    comboLabel.TextColor3 = UIConfig.Hud.ComboInactiveColor or UIConfig.Theme.TextMuted
    comboLabel.AnchorPoint = Vector2.new(0, 0)
    comboLabel.Position = UDim2.new(0, UIConfig.Hud.Padding + UIConfig.Hud.ComboLabelOffset.X, 0, UIConfig.Hud.ComboLabelOffset.Y)
    comboLabel.Size = UIConfig.Hud.ComboLabelSize
    comboLabel.Visible = false
    comboLabel.Parent = baseFrame

    local stateLabel = Instance.new("TextLabel")
    stateLabel.Name = "StateLabel"
    stateLabel.AnchorPoint = Vector2.new(1, 0.5)
    stateLabel.Position = UDim2.new(1, -UIConfig.Hud.Padding, 0.5, 0)
    stateLabel.Size = UDim2.new(0, 180, 0, 28)
    stateLabel.BackgroundTransparency = 1
    stateLabel.Font = UIConfig.Fonts.Header
    stateLabel.TextSize = 20
    stateLabel.TextXAlignment = Enum.TextXAlignment.Right
    stateLabel.TextColor3 = UIConfig.Theme.Success
    stateLabel.Text = "Ready"
    stateLabel.Parent = baseFrame

    local targetFrame = Instance.new("Frame")
    targetFrame.Name = "TargetPanel"
    targetFrame.Size = UDim2.new(0, UIConfig.TargetPanel.Width, 0, UIConfig.TargetPanel.Height)
    targetFrame.Position = UDim2.new(0.5, -UIConfig.TargetPanel.Width / 2, 0.14, 0)
    targetFrame.BackgroundColor3 = UIConfig.Theme.Primary
    targetFrame.BackgroundTransparency = 0.1
    targetFrame.BorderSizePixel = 0
    targetFrame.Parent = screenGui

    local targetCorner = Instance.new("UICorner")
    targetCorner.CornerRadius = UIConfig.TargetPanel.CornerRadius
    targetCorner.Parent = targetFrame

    local targetStroke = Instance.new("UIStroke")
    targetStroke.Thickness = 2
    targetStroke.Color = UIConfig.Theme.Secondary
    targetStroke.Transparency = 0.3
    targetStroke.Parent = targetFrame

    local targetName = Instance.new("TextLabel")
    targetName.Name = "Name"
    targetName.BackgroundTransparency = 1
    targetName.Position = UDim2.new(0, 12, 0, 10)
    targetName.Size = UDim2.new(1, -24, 0, 28)
    targetName.Font = UIConfig.Fonts.Header
    targetName.TextSize = 20
    targetName.TextXAlignment = Enum.TextXAlignment.Left
    targetName.TextColor3 = UIConfig.Theme.Text
    targetName.Text = "No Target"
    targetName.Parent = targetFrame

    local targetHealth = Instance.new("TextLabel")
    targetHealth.Name = "Health"
    targetHealth.BackgroundTransparency = 1
    targetHealth.Position = UDim2.new(0, 12, 0, 40)
    targetHealth.Size = UDim2.new(1, -24, 0, 24)
    targetHealth.Font = UIConfig.Fonts.Body
    targetHealth.TextSize = 18
    targetHealth.TextXAlignment = Enum.TextXAlignment.Left
    targetHealth.TextColor3 = UIConfig.Theme.TextMuted
    targetHealth.Text = "-- / --"
    targetHealth.Parent = targetFrame

    local targetHealthBar = Instance.new("Frame")
    targetHealthBar.Name = "HealthBar"
    targetHealthBar.BackgroundColor3 = UIConfig.TargetPanel.HealthBarBackgroundColor
    targetHealthBar.BackgroundTransparency = 0.3
    targetHealthBar.BorderSizePixel = 0
    targetHealthBar.Size = UIConfig.TargetPanel.HealthBarSize
    targetHealthBar.Position = UIConfig.TargetPanel.HealthBarPosition
    targetHealthBar.Parent = targetFrame

    local targetHealthBarCorner = Instance.new("UICorner")
    targetHealthBarCorner.CornerRadius = UIConfig.TargetPanel.CornerRadius
    targetHealthBarCorner.Parent = targetHealthBar

    local targetHealthFill = Instance.new("Frame")
    targetHealthFill.Name = "Fill"
    targetHealthFill.AnchorPoint = Vector2.new(0, 0.5)
    targetHealthFill.Position = UDim2.new(0, 0, 0.5, 0)
    targetHealthFill.Size = UDim2.new(0, 0, 1, 0)
    targetHealthFill.BackgroundColor3 = UIConfig.TargetPanel.HealthBarFillColor
    targetHealthFill.BorderSizePixel = 0
    targetHealthFill.Parent = targetHealthBar

    local targetHealthFillCorner = Instance.new("UICorner")
    targetHealthFillCorner.CornerRadius = UIConfig.TargetPanel.CornerRadius
    targetHealthFillCorner.Parent = targetHealthFill

    targetFrame.Visible = false

    return {
        ScreenGui = screenGui,
        BaseFrame = baseFrame,
        StaminaFill = staminaFill,
        StaminaLabel = staminaLabel,
        ComboLabel = comboLabel,
        StateLabel = stateLabel,
        TargetFrame = targetFrame,
        TargetName = targetName,
        TargetHealth = targetHealth,
        TargetHealthFill = targetHealthFill,
    }
end

local function updateHud()
    if not hud then
        return
    end

    local staminaMax = CombatConfig.Stamina.Max
    smoothedStamina += (stamina - smoothedStamina) * UIConfig.Hud.SmoothFillAlpha
    local staminaPercent = staminaMax > 0 and math.clamp(smoothedStamina / staminaMax, 0, 1) or 0
    hud.StaminaFill.Size = UDim2.new(staminaPercent, 0, 1, 0)
    hud.StaminaLabel.Text = string.format("Stamina: %d%%", math.floor(staminaPercent * 100 + 0.5))

    if staminaPercent <= UIConfig.Hud.LowStaminaThreshold then
        hud.StaminaFill.BackgroundColor3 = UIConfig.Hud.StaminaLowColor or UIConfig.Theme.AccentDim
        hud.StaminaLabel.TextColor3 = UIConfig.Hud.StaminaLowColor or UIConfig.Theme.AccentDim
    else
        hud.StaminaFill.BackgroundColor3 = UIConfig.Hud.StaminaHighColor or UIConfig.Theme.Accent
        hud.StaminaLabel.TextColor3 = UIConfig.Theme.Text
    end

    if comboIndex > 1 and os.clock() <= comboVisibleUntil then
        hud.ComboLabel.Visible = true
        hud.ComboLabel.Text = string.format(UIConfig.Hud.ComboTextFormat, comboIndex)
        hud.ComboLabel.TextColor3 = UIConfig.Hud.ComboActiveColor or UIConfig.Theme.Accent
    else
        hud.ComboLabel.Visible = false
        hud.ComboLabel.TextColor3 = UIConfig.Hud.ComboInactiveColor or UIConfig.Theme.TextMuted
    end

    if blocking then
        hud.StateLabel.Text = "Blocking"
        hud.StateLabel.TextColor3 = UIConfig.Theme.Accent
    else
        local cooldownLeft = math.max(0, CombatConfig.AttackCooldown - (os.clock() - lastAttackTime))
        if cooldownLeft > 0 then
            hud.StateLabel.Text = string.format("Cooling (%.1fs)", cooldownLeft)
            hud.StateLabel.TextColor3 = UIConfig.Hud.CooldownColor or UIConfig.Theme.TextMuted
        else
            hud.StateLabel.Text = "Ready"
            hud.StateLabel.TextColor3 = UIConfig.Theme.Success
        end
    end
end

local function updateTargetPanel()
    if not hud then
        return
    end

    local target = currentTargetHumanoid
    if target and target.Parent then
        hud.TargetFrame.Visible = true
        hud.TargetName.Text = target.Parent.Name
        local maxHealth = math.max(1, math.floor(target.MaxHealth + 0.5))
        local currentHealth = math.max(0, math.floor(target.Health + 0.5))
        local ratio = math.clamp(currentHealth / maxHealth, 0, 1)
        hud.TargetHealth.Text = string.format("%d / %d", currentHealth, maxHealth)
        hud.TargetHealthFill.Size = ratio > 0 and UDim2.new(ratio, 0, 1, 0) or UDim2.new(0, 0, 1, 0)

        if ratio <= UIConfig.TargetPanel.HealthCriticalThreshold then
            hud.TargetHealth.TextColor3 = UIConfig.Theme.Warning
            hud.TargetHealthFill.BackgroundColor3 = UIConfig.Theme.Warning
        else
            hud.TargetHealth.TextColor3 = UIConfig.Theme.Text
            hud.TargetHealthFill.BackgroundColor3 = UIConfig.TargetPanel.HealthBarFillColor
        end
    else
        hud.TargetFrame.Visible = false
    end
end

local function findHumanoidFromPart(part)
    if not part then
        return nil
    end

    local model = part:FindFirstAncestorWhichIsA("Model")
    if not model or model == player.Character then
        return nil
    end

    return model:FindFirstChildOfClass("Humanoid")
end

local function getBillboardAttachment(model)
    return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

local function removeBillboard(model)
    local data = billboards[model]
    if not data then
        return
    end

    billboards[model] = nil
    if data.Connections then
        for _, conn in ipairs(data.Connections) do
            conn:Disconnect()
        end
    end

    if data.Billboard then
        data.Billboard:Destroy()
    end
end

local function createBillboard(model, humanoid)
    local attachment = getBillboardAttachment(model)
    if not attachment then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CombatBillboard"
    billboard.Size = BillboardConfig.Size
    billboard.StudsOffset = BillboardConfig.StudsOffset
    billboard.MaxDistance = BillboardConfig.MaxDistance
    billboard.AlwaysOnTop = true
    billboard.Adornee = attachment
    billboard.Parent = attachment

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = BillboardConfig.BackgroundColor
    background.BackgroundTransparency = 0.25
    background.BorderSizePixel = 0
    background.Parent = billboard

    local backgroundCorner = Instance.new("UICorner")
    backgroundCorner.CornerRadius = UIConfig.Billboard.CornerRadius
    backgroundCorner.Parent = background

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = UIConfig.Billboard.StrokeThickness
    stroke.Color = BillboardConfig.StrokeColor
    stroke.Transparency = 0.1
    stroke.Parent = background

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.AnchorPoint = Vector2.new(0, 0.5)
    fill.Position = UDim2.new(0, 4, 0.5, 0)
    fill.Size = UDim2.new(1, 0, 0, 12)
    fill.BackgroundColor3 = BillboardConfig.FillColor
    fill.BorderSizePixel = 0
    fill.Parent = background

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UIConfig.Billboard.CornerRadius
    fillCorner.Parent = fill

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Label"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.Size = UDim2.new(1, -24, 0, 26)
    nameLabel.Font = BillboardConfig.Font
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = BillboardConfig.TextColor
    nameLabel.Text = string.format(BillboardConfig.HealthFormat, model.Name, 100)
    nameLabel.Parent = background

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.AnchorPoint = Vector2.new(1, 0.5)
    statusLabel.Position = UDim2.new(1, -8, 0.5, 0)
    statusLabel.Size = UDim2.new(0, 70, 0, 20)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = UIConfig.Fonts.Mono
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.TextColor3 = BillboardConfig.SecondaryTextColor
    statusLabel.Text = ""
    statusLabel.Parent = background

    local data = {
        Billboard = billboard,
        Background = background,
        Fill = fill,
        Label = nameLabel,
        Status = statusLabel,
        Stroke = stroke,
        Humanoid = humanoid,
        Connections = {},
    }

    local ancestryConn = model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeBillboard(model)
        end
    end)

    local diedConn = humanoid.Died:Connect(function()
        statusLabel.Text = "DOWN"
        statusLabel.TextColor3 = BillboardConfig.SecondaryTextColor
        fill.Size = UDim2.new(0, 0, 0, 12)
    end)

    table.insert(data.Connections, ancestryConn)
    table.insert(data.Connections, diedConn)

    billboards[model] = data
end

local function ensureBillboard(character)
    if not character or character == player.Character or billboards[character] then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    createBillboard(character, humanoid)
end

local function updateBillboards(dt)
    for model, data in pairs(billboards) do
        local humanoid = data.Humanoid
        if not humanoid or not humanoid.Parent then
            removeBillboard(model)
        else
            local ratio = 0
            if humanoid.MaxHealth > 0 then
                ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            end

            data.Fill.Size = UDim2.new(ratio, -8, 0, 12)
            data.Label.Text = string.format(BillboardConfig.HealthFormat, model.Name, math.floor(ratio * 100 + 0.5))

            if humanoid == currentTargetHumanoid and humanoid.Health > 0 then
                data.Status.Text = "TARGET"
                data.Status.TextColor3 = UIConfig.Theme.Accent
                data.Stroke.Color = UIConfig.Theme.Accent
                data.Background.BackgroundTransparency = 0.15
            elseif humanoid.Health <= 0 then
                data.Status.Text = "DEFEATED"
                data.Status.TextColor3 = BillboardConfig.SecondaryTextColor
                data.Stroke.Color = BillboardConfig.StrokeColor
                data.Background.BackgroundTransparency = 0.35
            else
                data.Status.Text = ""
                data.Status.TextColor3 = BillboardConfig.SecondaryTextColor
                data.Stroke.Color = BillboardConfig.StrokeColor
                data.Background.BackgroundTransparency = 0.25
            end
        end
    end
end

local function sendAttack(attackType, targetHumanoid)
    combatRemote:FireServer("Attack", {
        AttackType = attackType,
        Target = targetHumanoid,
    })
end

local function performAttack(attackType)
    local now = os.clock()
    if now - lastAttackTime < CombatConfig.AttackCooldown then
        return
    end

    local cost = CombatConfig.Stamina.AttackCost[attackType] or 0
    if stamina < cost then
        return
    end

    local targetHumanoid = currentTargetHumanoid
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        targetHumanoid = findHumanoidFromPart(mouse.Target)
    end

    stamina = math.max(0, stamina - cost)
    smoothedStamina = math.min(smoothedStamina, stamina)

    local comboDelta = now - lastComboTime
    if comboDelta <= CombatConfig.Combo.MaximumWindow and comboDelta >= CombatConfig.Combo.MinimumWindow then
        comboIndex += 1
    else
        comboIndex = 1
    end
    lastComboTime = now
    comboVisibleUntil = now + CombatConfig.Combo.MaximumWindow

    lastAttackTime = now
    sendAttack(attackType, targetHumanoid)
end

local function lightAttackAction(_, inputState)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    performAttack("Light")
    return Enum.ContextActionResult.Sink
end

local function heavyAttackAction(_, inputState)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    performAttack("Heavy")
    return Enum.ContextActionResult.Sink
end

local function blockAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        if blocking then
            return Enum.ContextActionResult.Sink
        end
        if stamina < CombatConfig.Block.StartCost then
            return Enum.ContextActionResult.Sink
        end
        blocking = true
        stamina = math.max(0, stamina - CombatConfig.Block.StartCost)
        smoothedStamina = math.min(smoothedStamina, stamina)
        combatRemote:FireServer("Block", {
            IsBlocking = true,
        })
    elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
        if blocking then
            blocking = false
            combatRemote:FireServer("Block", {
                IsBlocking = false,
            })
        end
    end

    return Enum.ContextActionResult.Sink
end

local function onCharacterAdded(character)
    if character == player.Character then
        stamina = CombatConfig.Stamina.Max
        smoothedStamina = stamina
        blocking = false
        lastAttackTime = 0
        comboIndex = 1
        lastComboTime = 0
    else
        ensureBillboard(character)
    end
end

local function observeExistingCharacters()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            ensureBillboard(otherPlayer.Character)
        end
    end

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Model") then
            ensureBillboard(descendant)
        end
    end
end

hud = createHud()
observeExistingCharacters()

player.CharacterAdded:Connect(onCharacterAdded)

Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer == player then
        return
    end

    newPlayer.CharacterAdded:Connect(onCharacterAdded)
    if newPlayer.Character then
        ensureBillboard(newPlayer.Character)
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        return
    end

    if leavingPlayer.Character then
        removeBillboard(leavingPlayer.Character)
    end
end)

Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        task.defer(function()
            ensureBillboard(child)
        end)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if blocking then
        stamina -= CombatConfig.Block.StaminaDrainPerSecond * dt
    else
        stamina += CombatConfig.Stamina.RegenPerSecond * dt
    end

    stamina = math.clamp(stamina, 0, CombatConfig.Stamina.Max)

    if blocking and stamina <= 0 then
        blocking = false
        combatRemote:FireServer("Block", {
            IsBlocking = false,
        })
    end

    currentTargetHumanoid = findHumanoidFromPart(mouse.Target)

    if comboIndex > 1 and lastComboTime > 0 then
        local elapsed = os.clock() - lastComboTime
        if elapsed > CombatConfig.Combo.MaximumWindow then
            comboIndex = 1
            lastComboTime = 0
        end
    end

    updateHud()
    updateTargetPanel()
    updateBillboards()
end)

ContextActionService:BindAction("LightAttack", lightAttackAction, false, Enum.UserInputType.MouseButton1)
ContextActionService:BindAction("HeavyAttack", heavyAttackAction, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.Q)
ContextActionService:BindAction("Block", blockAction, false, Enum.KeyCode.F)

return {}
