-- ReplicatedStorage.Modules.Movement.EvasiveClient
local EvasiveClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MovementFolder = Remotes:WaitForChild("Movement")
local EvasiveEvent = MovementFolder:WaitForChild("EvasiveEvent")

local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local DashVFX = require(ReplicatedStorage.Modules.Effects.DashVFX)
local SoundServiceUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local DashConfig = require(ReplicatedStorage.Modules.Movement.DashConfig)

local KEY_L = Enum.KeyCode.LeftControl
local KEY_R = Enum.KeyCode.RightControl

local function getCharacterComponents()
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, hrp
end

local function getDashInputAndVector()
    local keys = MovementClient.GetMovementKeys and MovementClient.GetMovementKeys() or {}
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local camLook = camera.CFrame.LookVector
    local camRight = camera.CFrame.RightVector

    camLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
    camRight = Vector3.new(camRight.X, 0, camRight.Z).Unit

    if keys.W and keys.A then
        return "ForwardLeft", (camLook - camRight).Unit
    elseif keys.W and keys.D then
        return "ForwardRight", (camLook + camRight).Unit
    elseif keys.S and keys.A then
        return "BackwardLeft", ((-camLook) - camRight).Unit
    elseif keys.S and keys.D then
        return "BackwardRight", ((-camLook) + camRight).Unit
    elseif keys.W then
        return "Forward", camLook
    elseif keys.A then
        return "Left", (-camRight).Unit
    elseif keys.D then
        return "Right", camRight
    elseif keys.S then
        return "Backward", (-camLook).Unit
    end
    return nil
end

function EvasiveClient.OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= KEY_L and input.KeyCode ~= KEY_R then return end

    if BlockClient.IsBlocking() then return end

    local evasiveVal = player:FindFirstChild("Evasive")
    local maxVal = player:FindFirstChild("MaxEvasive")
    if not evasiveVal or not maxVal or evasiveVal.Value < maxVal.Value then return end

    local direction, dashVector = getDashInputAndVector()
    if not direction or not dashVector then return end

    StunStatusClient.ReduceLockTo(0)
    StunStatusClient.LockFor(1.5)

    local _, _, hrp = getCharacterComponents()
    if hrp and DashConfig.Sound then
        SoundServiceUtils:PlaySpatialSound(DashConfig.Sound, hrp)
        DashVFX:PlayDashEffect(direction, hrp)
    end

    EvasiveEvent:FireServer(direction, dashVector)
end

function EvasiveClient.OnInputEnded() end

return EvasiveClient
