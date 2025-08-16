--ReplicatedStorage.Modules.Combat.HakiClient
local HakiClient = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

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
local assetsFolder = ReplicatedFirst:FindFirstChild("Assets")
local hakiTemplate = assetsFolder and assetsFolder:FindFirstChild("HakiEnabled")
local addedTextures = {}

local function resolveChar(actor)
       if typeof(actor) ~= "Instance" then return nil end
       if actor:IsA("Player") then return actor.Character end
       if actor:IsA("Model") then return actor end
       if actor:IsA("Humanoid") then return actor.Parent end
       return nil
end

local function applyColor(char, style)
    local names
    if style == "BlackLeg" then
        names = {"LeftFoot","LeftLowerLeg","RightFoot","RightLowerLeg"}
    else
        names = {"LeftHand","LeftLowerArm","RightHand","RightLowerArm"}
    end
    coloredParts[char] = {}
    originalColors[char] = {}
    for _, partName in ipairs(names) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            originalColors[char][part] = part.Color
            table.insert(coloredParts[char], part)
            part.Color = Color3.new(0,0,0)
        end
    end
end

local function clearColor(char)
    for _, part in ipairs(coloredParts[char] or {}) do
        local col = originalColors[char] and originalColors[char][part]
        if part and col then
            part.Color = col
        end
    end
    coloredParts[char] = nil
    originalColors[char] = nil
end

local function applyTextures(char)
    if not hakiTemplate then return end
    addedTextures[char] = {}
    for _, src in ipairs(hakiTemplate:GetDescendants()) do
        if src:IsA("BasePart") then
            local target = char:FindFirstChild(src.Name)
            if target then
                for _, child in ipairs(src:GetChildren()) do
                    if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then
                        local clone = child:Clone()
                        clone.Parent = target
                        table.insert(addedTextures[char], clone)
                    end
                end
            end
        end
    end
end

local function clearTextures(char)
    for _, obj in ipairs(addedTextures[char] or {}) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    addedTextures[char] = nil
end

HakiEvent.OnClientEvent:Connect(function(hakiActor, state)
    if typeof(state) ~= "boolean" then return end

    local char = resolveChar(hakiActor)
    if not char then return end

    active[char] = state

    if state then
        local style
        if hakiActor == player then
            style = ToolController.GetEquippedStyleKey()
        else
            local tool = char and char:FindFirstChildOfClass("Tool")
            style = tool and tool.Name
        end
        applyColor(char, style)
        applyTextures(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local soundId = SoundConfig.Haki and SoundConfig.Haki.Activate
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
        end
        char.AncestryChanged:Once(function(_, parent)
            if parent == nil then
                clearColor(char)
                clearTextures(char)
                active[char] = nil
            end
        end)
    else
        clearColor(char)
        clearTextures(char)
    end
end)

function HakiClient.OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= KEY then return end

    if HakiService.GetHaki(player) <= 0 then return end
    local char = resolveChar(player)
    if not char then return end
    local newState = not active[char]
    HakiEvent:FireServer(newState)
    MoveListManager.StartCooldown(KEY.Name, TOGGLE_COOLDOWN)
end

function HakiClient.OnInputEnded() end

return HakiClient

