--ReplicatedStorage.Modules.Combat.Moves.TeleportClient
local Teleport = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement")
local TeleportEvent = MovementRemotes:WaitForChild("TeleportEvent")

local RokushikiConfig = require(ReplicatedStorage.Modules.Config.Tools.Rokushiki)
local TeleportConfig = RokushikiConfig.Teleport
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local SoundServiceUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local TeleportVFX = require(ReplicatedStorage.Modules.Effects.TeleportVFX)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

local KEY = Enum.KeyCode.T
local active = false
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
    if active then return end
    if tick() - lastUse < (TeleportConfig.Cooldown or 0) then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() or BlockClient.IsBlocking() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "Rokushiki" then return end
    if not ToolController.IsValidCombatTool() then return end

    if StaminaService.GetStamina(Players.LocalPlayer) < (TeleportConfig.StaminaCost or 0) then return end

    local _, humanoid, hrp = getCharacter()
    if not hrp or not humanoid then return end

    active = true
    lastUse = tick()
    MoveListManager.StartCooldown(KEY.Name, TeleportConfig.Cooldown or 0)

    MovementClient.StopSprint()
    local lockTime = (TeleportConfig.Startup or 0) + (TeleportConfig.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(function()
        task.wait(TeleportConfig.Startup or 0)

        local startCF = hrp.CFrame
        local pos = mouse.Hit and mouse.Hit.Position or hrp.Position
        local delta = pos - hrp.Position
        local maxDist = TeleportConfig.MaxDistance or 20
        if delta.Magnitude > maxDist then
            delta = delta.Unit * maxDist
            pos = hrp.Position + delta
        end

        TeleportVFX.Play(startCF)

        hrp.CFrame = CFrame.new(pos)
        local vel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)

        TeleportEvent:FireServer(pos)

        TeleportVFX.Play(CFrame.new(pos))

        local sfx = SoundConfig.Combat.Rokushiki.TeleportUse
        SoundServiceUtils:PlaySpatialSound(sfx, hrp)

        task.wait(TeleportConfig.Endlag or 0)
        active = false
    end)
end

function Teleport.OnInputEnded() end

return Teleport
