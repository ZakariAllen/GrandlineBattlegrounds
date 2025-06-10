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
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

local KEY = Enum.KeyCode.J
local TOGGLE_COOLDOWN = 1
local active = {}
local coloredParts = {}
local originalColors = {}
local hakiTemplate = ReplicatedStorage:FindFirstChild("Assets") and
    ReplicatedStorage.Assets:FindFirstChild("HakiEnabled")
local addedTextures = {}

local function applyColor(char, style, hakiPlayer)
    local names
    if style == "BlackLeg" then
        names = {"LeftFoot","LeftLowerLeg","RightFoot","RightLowerLeg"}
    else
        names = {"LeftHand","LeftLowerArm","RightHand","RightLowerArm"}
    end
    coloredParts[hakiPlayer] = {}
    originalColors[hakiPlayer] = {}
    for _, partName in ipairs(names) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            originalColors[hakiPlayer][part] = part.Color
            table.insert(coloredParts[hakiPlayer], part)
            part.Color = Color3.new(0,0,0)
        end
    end
end

local function clearColor(hakiPlayer)
    for _, part in ipairs(coloredParts[hakiPlayer] or {}) do
        local col = originalColors[hakiPlayer] and originalColors[hakiPlayer][part]
        if part and col then
            part.Color = col
        end
    end
    coloredParts[hakiPlayer] = nil
    originalColors[hakiPlayer] = nil
end

local function applyTextures(char, hakiPlayer)
    if not hakiTemplate then return end
    addedTextures[hakiPlayer] = {}
    for _, src in ipairs(hakiTemplate:GetDescendants()) do
        if src:IsA("BasePart") then
            local target = char:FindFirstChild(src.Name)
            if target then
                for _, child in ipairs(src:GetChildren()) do
                    if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then
                        local clone = child:Clone()
                        clone.Parent = target
                        table.insert(addedTextures[hakiPlayer], clone)
                    end
                end
            end
        end
    end
end

local function clearTextures(hakiPlayer)
    for _, obj in ipairs(addedTextures[hakiPlayer] or {}) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    addedTextures[hakiPlayer] = nil
end

HakiEvent.OnClientEvent:Connect(function(hakiPlayer, state)
    if typeof(state) ~= "boolean" then return end

    local char = hakiPlayer.Character
    if not char then return end

    active[hakiPlayer] = state

    if state then
        local style
        if hakiPlayer == player then
            style = ToolController.GetEquippedStyleKey()
        else
            local tool = hakiPlayer.Character and hakiPlayer.Character:FindFirstChildOfClass("Tool")
            style = tool and tool.Name
        end
        applyColor(char, style, hakiPlayer)
        applyTextures(char, hakiPlayer)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local soundId = SoundConfig.Haki and SoundConfig.Haki.Activate
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
        end
    else
        clearColor(hakiPlayer)
        clearTextures(hakiPlayer)
    end
end)

function HakiClient.OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= KEY then return end

    if HakiService.GetHaki(player) <= 0 then return end
    local newState = not active[player]
    HakiEvent:FireServer(newState)
    MoveListManager.StartCooldown(KEY.Name, TOGGLE_COOLDOWN)
end

function HakiClient.OnInputEnded() end

return HakiClient

