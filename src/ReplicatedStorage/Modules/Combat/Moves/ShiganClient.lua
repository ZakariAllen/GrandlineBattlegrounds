--ReplicatedStorage.Modules.Combat.Moves.ShiganClient
local Shigan = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Time = require(ReplicatedStorage.Modules.Util.Time)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("ShiganStart")
local HitEvent = CombatRemotes:WaitForChild("ShiganHit")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local ShiganConfig = AbilityConfig.Rokushiki.Shigan
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)
local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

local KEY = Enum.KeyCode.R
local active = false
local lastUse = 0
local prevWalkSpeed
local prevJumpPower
local currentHumanoid

local function getCharacter()
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return char, humanoid, animator, hrp
end

local function playAnimation(animator, animId)
    if not animator or not animId then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action
    track:Play()
    return track
end

local function performMove()
    local cfg = ShiganConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not humanoid or not hrp then
        active = false
        if DEBUG then print("[ShiganClient] Invalid character state") end
        return
    end

    currentHumanoid = humanoid
    prevWalkSpeed = humanoid.WalkSpeed
    prevJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    playAnimation(animator, Animations.SpecialMoves.Shigan)
    StartEvent:FireServer()

    -- No checks needed during startup, simple wait suffices
    task.wait(cfg.Startup)

    local dir = hrp.CFrame.LookVector
    HitboxClient.CastHitbox(
        MoveHitboxConfig.Shigan.Offset,
        MoveHitboxConfig.Shigan.Size,
        MoveHitboxConfig.Shigan.Duration,
        HitEvent,
        {dir},
        MoveHitboxConfig.Shigan.Shape,
        true,
        nil,
        true
    )

    task.wait(cfg.Endlag)

    humanoid.WalkSpeed = prevWalkSpeed
    humanoid.JumpPower = prevJumpPower
    prevWalkSpeed = nil
    prevJumpPower = nil
    currentHumanoid = nil
    active = false
end

function Shigan.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "Rokushiki" then return end
    if not ToolController.IsValidCombatTool() then return end

    if Time.now() - lastUse < (ShiganConfig.Cooldown or 0) then return end

    active = true
    lastUse = Time.now()
    MoveListManager.StartCooldown(KEY.Name, ShiganConfig.Cooldown or 0)

    MovementClient.StopSprint()
    local lockTime = ShiganConfig.Startup + (ShiganConfig.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(performMove)
end

function Shigan.OnInputEnded()
    -- move cannot be cancelled
end

return Shigan
