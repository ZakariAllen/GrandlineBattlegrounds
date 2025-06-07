--ReplicatedStorage.Modules.Combat.Moves.TeleportClient
local Teleport = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement")
local TeleportEvent = MovementRemotes:WaitForChild("TeleportEvent")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local TeleportConfig = AbilityConfig.Rokushiki.Teleport
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local SoundServiceUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)

local KEY = Enum.KeyCode.T
local lastUse = 0

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local function getCharacter()
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    return char, humanoid, hrp
end

function Teleport.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if tick() - lastUse < (TeleportConfig.Cooldown or 0) then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() or BlockClient.IsBlocking() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "Rokushiki" then return end
    if not ToolController.IsValidCombatTool() then return end

    local _, _, hrp = getCharacter()
    if not hrp then return end

    lastUse = tick()

    local pos = mouse.Hit and mouse.Hit.Position or hrp.Position
    local delta = pos - hrp.Position
    local maxDist = TeleportConfig.MaxDistance or 20
    if delta.Magnitude > maxDist then
        delta = delta.Unit * maxDist
        pos = hrp.Position + delta
    end

    -- Move the character locally first so the server update isn't overwritten
    -- by client-side physics when the player is in motion. The server will
    -- validate the request and replicate the same position back to all clients.
    hrp.CFrame = CFrame.new(pos)
    local vel = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)

    TeleportEvent:FireServer(pos)

    local sfx = TeleportConfig.Sound and TeleportConfig.Sound.Use
    if sfx then
        SoundServiceUtils:PlaySpatialSound(sfx, hrp)
    end
end

function Teleport.OnInputEnded() end

return Teleport
