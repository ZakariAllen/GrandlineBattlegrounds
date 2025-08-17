--ReplicatedStorage.Modules.Combat.Moves.TempestKickClient
local TempestKick = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Time = require(ReplicatedStorage.Modules.Util.Time)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("TempestKickStart")
local HitEvent = CombatRemotes:WaitForChild("TempestKickHit")
local VFXEvent = CombatRemotes:WaitForChild("TempestKickVFX")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local TempestKickConfig = AbilityConfig.Rokushiki.TempestKick
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local TempestKickVFX = require(ReplicatedStorage.Modules.Effects.TempestKickVFX)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

local DEBUG = Config.GameSettings.DebugEnabled

local KEY = Enum.KeyCode.X
local active = false
local lastUse = 0
local prevWalkSpeed
local prevJumpPower
local currentHumanoid

local function resolveChar(actor)
       if typeof(actor) ~= "Instance" then return nil end
       if actor:IsA("Player") then
               return actor.Character
       elseif actor:IsA("Model") then
               return actor
       elseif actor:IsA("Humanoid") then
               return actor.Parent
       end
       return nil
end

local function getCharacter()
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
    local cfg = TempestKickConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not humanoid or not hrp then
        active = false
        if DEBUG then print("[TempestKickClient] Invalid character state") end
        return
    end

    currentHumanoid = humanoid
    prevWalkSpeed = humanoid.WalkSpeed
    prevJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    playAnimation(animator, Animations.SpecialMoves.PowerKick)
    StartEvent:FireServer()

    -- No extra logic during startup, so a simple timed wait is fine
    task.wait(cfg.Startup)

    local dir = hrp.CFrame.LookVector
    local hitbox = HitboxClient.CastHitbox(
        MoveHitboxConfig.TempestKick.Offset,
        MoveHitboxConfig.TempestKick.Size,
        TempestKickConfig.HitboxDuration,
        HitEvent,
        {dir},
        MoveHitboxConfig.TempestKick.Shape,
        true,
        TempestKickConfig.HitboxDistance,
        true
    )

    if hitbox then
        TempestKickVFX.Create(hitbox)
    end

    task.wait(cfg.Endlag)

    humanoid.WalkSpeed = prevWalkSpeed
    humanoid.JumpPower = prevJumpPower
    prevWalkSpeed = nil
    prevJumpPower = nil
    currentHumanoid = nil
    active = false
end

function TempestKick.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "Rokushiki" then return end
    if not ToolController.IsValidCombatTool() then return end

    if StaminaService.GetStamina(Players.LocalPlayer) < 75 then return end

    if Time.now() - lastUse < (TempestKickConfig.Cooldown or 0) then return end

    active = true
    lastUse = Time.now()
    MoveListManager.StartCooldown(KEY.Name, TempestKickConfig.Cooldown or 0)

    MovementClient.StopSprint()
    local lockTime = TempestKickConfig.Startup + (TempestKickConfig.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(performMove)
end

function TempestKick.OnInputEnded()
    -- move cannot be cancelled
end

-- Play VFX for other actors when the server notifies us
VFXEvent.OnClientEvent:Connect(function(kickActor, startCF)
    local char = resolveChar(kickActor)
    if not char or char == player.Character then return end
    if typeof(startCF) ~= "CFrame" then return end

    local hitbox = HitboxClient.CastHitbox(
        MoveHitboxConfig.TempestKick.Offset,
        MoveHitboxConfig.TempestKick.Size,
        TempestKickConfig.HitboxDuration,
        nil,
        nil,
        MoveHitboxConfig.TempestKick.Shape,
        false,
        TempestKickConfig.HitboxDistance,
        false,
        startCF
    )
    if hitbox then
        TempestKickVFX.Create(hitbox)
    end
end)

return TempestKick
