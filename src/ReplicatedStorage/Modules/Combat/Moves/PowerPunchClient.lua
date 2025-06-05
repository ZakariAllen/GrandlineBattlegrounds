--ReplicatedStorage.Modules.Combat.Moves.PowerPunchClient
local PowerPunch = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PowerPunchStart")
local HitEvent = CombatRemotes:WaitForChild("PowerPunchHit")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local PowerPunchConfig = require(ReplicatedStorage.Modules.Config.PowerPunchConfig)
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

local KEY = Enum.KeyCode.R
local active = false
local lastUse = 0

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
    local cfg = PowerPunchConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not humanoid or not hrp then
        active = false
        if DEBUG then print("[PowerPunchClient] Invalid character state") end
        return
    end

    playAnimation(animator, Animations.SpecialMoves.PowerPunch)
    StartEvent:FireServer()

    local startTime = tick()
    while tick() - startTime < cfg.Startup do
        RunService.RenderStepped:Wait()
    end

    HitboxClient.CastHitbox(
        MoveHitboxConfig.PowerPunch.Offset,
        MoveHitboxConfig.PowerPunch.Size,
        MoveHitboxConfig.PowerPunch.Duration,
        HitEvent,
        {true},
        MoveHitboxConfig.PowerPunch.Shape,
        true
    )

    task.wait(cfg.Endlag)
    active = false
end

function PowerPunch.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "BasicCombat" then return end
    if not ToolController.IsValidCombatTool() then return end

    if tick() - lastUse < (PowerPunchConfig.Cooldown or 0) then return end

    active = true
    lastUse = tick()

    MovementClient.StopSprint()
    local lockTime = PowerPunchConfig.Startup + (PowerPunchConfig.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(performMove)
end

function PowerPunch.OnInputEnded()
    -- move cannot be cancelled
end

return PowerPunch
