--ReplicatedStorage.Modules.Combat.Moves.PowerPunchClient
local PowerPunch = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PowerPunchStart")
local HitEvent = CombatRemotes:WaitForChild("PowerPunchHit")
local VFXEvent = CombatRemotes:WaitForChild("PowerPunchVFX")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local PowerPunchConfig = AbilityConfig.BasicCombat.PowerPunch
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

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

local function playVFX(parentPart)
    if not parentPart then return end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://14049479051"
    emitter.LightEmission = 1
    emitter.Speed = NumberRange.new(0)
    emitter.Lifetime = NumberRange.new(0.4)
    emitter.Rate = 0
    emitter.Enabled = false
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Parent = parentPart
    emitter:Emit(12)
    Debris:AddItem(emitter, 1)
end

local function performMove()
    local cfg = PowerPunchConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not humanoid or not hrp then
        active = false
        if DEBUG then print("[PowerPunchClient] Invalid character state") end
        return
    end

    currentHumanoid = humanoid
    prevWalkSpeed = humanoid.WalkSpeed
    prevJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    playAnimation(animator, Animations.SpecialMoves.PowerPunch)
    StartEvent:FireServer()

    -- Wait for startup without a busy loop
    task.wait(cfg.Startup)

    -- Cast the hitbox while movement is still locked
    local dir = hrp.CFrame.LookVector
    local hitbox = HitboxClient.CastHitbox(
        MoveHitboxConfig.PowerPunch.Offset,
        MoveHitboxConfig.PowerPunch.Size,
        PowerPunchConfig.HitboxDuration,
        HitEvent,
        {dir},
        MoveHitboxConfig.PowerPunch.Shape,
        true,
        PowerPunchConfig.HitboxDistance,
        true
    )

    if hitbox then
        playVFX(hitbox)
    end

    task.wait(cfg.Endlag)

    -- Restore movement after endlag finishes
    humanoid.WalkSpeed = prevWalkSpeed
    humanoid.JumpPower = prevJumpPower
    prevWalkSpeed = nil
    prevJumpPower = nil
    currentHumanoid = nil
    active = false
end

function PowerPunch.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "BasicCombat" then return end
    if not ToolController.IsValidCombatTool() then return end

    if StaminaService.GetStamina(Players.LocalPlayer) < 20 then return end

    if tick() - lastUse < (PowerPunchConfig.Cooldown or 0) then return end

    active = true
    lastUse = tick()
    MoveListManager.StartCooldown(KEY.Name, PowerPunchConfig.Cooldown or 0)

    MovementClient.StopSprint()
    local lockTime = PowerPunchConfig.Startup + (PowerPunchConfig.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(performMove)
end

function PowerPunch.OnInputEnded()
    -- move cannot be cancelled
end

VFXEvent.OnClientEvent:Connect(function(punchPlayer)
    if typeof(punchPlayer) ~= "Instance" then return end
    local char = punchPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        playVFX(hrp)
    end
end)

return PowerPunch
