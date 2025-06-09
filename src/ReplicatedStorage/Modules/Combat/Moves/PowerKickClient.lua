--ReplicatedStorage.Modules.Combat.Moves.PowerKickClient
local PowerKick = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PowerKickStart")
local HitEvent = CombatRemotes:WaitForChild("PowerKickHit")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local PowerKickConfig = AbilityConfig.BlackLeg.PowerKick
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)

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
    local cfg = PowerKickConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not humanoid or not hrp then
        active = false
        if DEBUG then print("[PowerKickClient] Invalid character state") end
        return
    end

    currentHumanoid = humanoid
    prevWalkSpeed = humanoid.WalkSpeed
    prevJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    playAnimation(animator, Animations.SpecialMoves.PowerKick)
    StartEvent:FireServer()

    -- Straightforward delay before the hitbox spawns
    task.wait(cfg.Startup)

    local dir = hrp.CFrame.LookVector
    HitboxClient.CastHitbox(
        MoveHitboxConfig.PowerKick.Offset,
        MoveHitboxConfig.PowerKick.Size,
        MoveHitboxConfig.PowerKick.Duration,
        HitEvent,
        {dir},
        MoveHitboxConfig.PowerKick.Shape,
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

function PowerKick.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "BlackLeg" then return end
    if not ToolController.IsValidCombatTool() then return end

    if StaminaService.GetStamina(Players.LocalPlayer) < 20 then return end

    if tick() - lastUse < (PowerKickConfig.Cooldown or 0) then return end

    active = true
    lastUse = tick()

    MovementClient.StopSprint()
    local lockTime = PowerKickConfig.Startup + (PowerKickConfig.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(performMove)
end

function PowerKick.OnInputEnded()
    -- move cannot be cancelled
end

return PowerKick
