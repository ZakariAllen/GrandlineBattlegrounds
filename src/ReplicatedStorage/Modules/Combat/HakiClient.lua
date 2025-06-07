--ReplicatedStorage.Modules.Combat.HakiClient
local HakiClient = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local HakiEvent = CombatRemotes:WaitForChild("HakiEvent")

local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)

local KEY = Enum.KeyCode.J
local active = false
local coloredParts = {}
local originalColors = {}

local function applyColor(char, style)
    local names
    if style == "BlackLeg" then
        names = {"LeftFoot","LeftLowerLeg","RightFoot","RightLowerLeg"}
    else
        names = {"LeftHand","LeftLowerArm","RightHand","RightLowerArm"}
    end
    for _, partName in ipairs(names) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            originalColors[part] = part.Color
            table.insert(coloredParts, part)
            part.Color = Color3.new(0,0,0)
        end
    end
end

local function clearColor()
    for _, part in ipairs(coloredParts) do
        local col = originalColors[part]
        if part and col then
            part.Color = col
        end
    end
    coloredParts = {}
    originalColors = {}
end

HakiEvent.OnClientEvent:Connect(function(hakiPlayer, state)
    if hakiPlayer ~= player then return end
    if typeof(state) ~= "boolean" then return end
    local char = player.Character
    if not char then return end

    active = state

    if state then
        local style = ToolController.GetEquippedStyleKey()
        applyColor(char, style)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local soundId = SoundConfig.Haki and SoundConfig.Haki.Activate
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
        end
    else
        clearColor()
    end
end)

function HakiClient.OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= KEY then return end

    if HakiService.GetHaki(player) <= 0 then return end
    local newState = not active
    HakiEvent:FireServer(newState)
end

function HakiClient.OnInputEnded() end

return HakiClient

