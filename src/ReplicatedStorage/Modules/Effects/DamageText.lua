--ReplicatedStorage.Modules.Effects.DamageText

local DamageText = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local template
local function getTemplate()
    if template then return template end
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if assets then
        template = assets:FindFirstChild("DamageText")
    end
    return template
end

function DamageText.Show(target: Instance, amount: number)
    if typeof(amount) ~= "number" or not target then return end

    local char = target
    if target:IsA("Humanoid") then
        char = target.Parent
    end

    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local gui
    local tmpl = getTemplate()
    if tmpl then
        gui = tmpl:Clone()
    else
        gui = Instance.new("BillboardGui")
        gui.Size = UDim2.fromScale(2, 1)
        gui.AlwaysOnTop = true
        local label = Instance.new("TextLabel")
        label.Name = "TextLabel"
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.TextColor3 = Color3.new(1, 0, 0)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextScaled = true
        label.Parent = gui
    end

    gui.Name = "DamageText"
    gui.Adornee = root
    local label = gui:FindFirstChildOfClass("TextLabel")
    if label then
        label.Text = tostring(math.floor(amount))
        label.TextTransparency = 0
        label.TextStrokeTransparency = 0
    end

    -- \u{1F4A5} Tween upward movement and fade out
    local startOffset = gui.StudsOffset
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(gui, tweenInfo, {StudsOffset = startOffset + Vector3.new(0, 2, 0)}):Play()
    if label then
        TweenService:Create(label, tweenInfo, {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        }):Play()
    end

    gui.Parent = char

    Debris:AddItem(gui, 1.05)
end

return DamageText
