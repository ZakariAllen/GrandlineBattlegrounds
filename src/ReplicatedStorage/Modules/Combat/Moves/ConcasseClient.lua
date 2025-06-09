--ReplicatedStorage.Modules.Combat.Moves.ConcasseClient
local Concasse = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("ConcasseStart")
local HitEvent = CombatRemotes:WaitForChild("ConcasseHit")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local ConcasseConfig = AbilityConfig.BlackLeg.Concasse
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)

local KEY = Enum.KeyCode.T
local active = false
local lastUse = 0
local prevWalkSpeed
local prevJumpPower
local currentHumanoid

-- Wait until the humanoid touches the ground without busy-waiting
local function waitForLanding(hum)
    while hum and hum.Parent and hum.FloorMaterial == Enum.Material.Air do
        hum:GetPropertyChangedSignal("FloorMaterial"):Wait()
    end
end

local player = Players.LocalPlayer
local mouse = player:GetMouse()

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

local function performMove(targetPos)
    local cfg = ConcasseConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not humanoid or not hrp then
        active = false
        return
    end

    currentHumanoid = humanoid
    prevWalkSpeed = humanoid.WalkSpeed
    prevJumpPower = humanoid.JumpPower
    local prevAnchored = hrp.Anchored
    local prevPlat = humanoid.PlatformStand
    local prevAuto = humanoid.AutoRotate
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    hrp.Anchored = true
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    playAnimation(animator, Animations.SpecialMoves.PowerKick)

    local start = hrp.Position
    local dest = targetPos
    local dir = dest - start
    local horiz = Vector3.new(dir.X, 0, dir.Z)
    local dist = horiz.Magnitude
    if dist > (cfg.Range or 65) then
        horiz = horiz.Unit * (cfg.Range or 65)
        dist = (cfg.Range or 65)
    end
    dest = start + horiz
    StartEvent:FireServer(dest)

    local height = math.max(dist * 0.5 + 25, 15)
    -- Calculate travel time from a constant travel speed with a floor so short
    -- distances don't feel instantaneous
    local travelTime = math.max(
        cfg.TravelTime or (dist / (cfg.TravelSpeed or 10)),
        cfg.MinTravelTime or 0
    )
    local startTime = tick()
    while tick() - startTime < travelTime do
        local t = (tick() - startTime) / travelTime
        local pos = start:Lerp(dest, t)
        pos = pos + Vector3.new(0, math.sin(math.pi * t) * height, 0)
        hrp.CFrame = CFrame.new(pos, dest)
        RunService.RenderStepped:Wait()
    end
    hrp.CFrame = CFrame.new(dest)
    hrp.Anchored = prevAnchored
    humanoid.PlatformStand = prevPlat
    humanoid.AutoRotate = prevAuto

    waitForLanding(humanoid)

    HitboxClient.CastHitbox(
        MoveHitboxConfig.Concasse.Offset,
        MoveHitboxConfig.Concasse.Size,
        MoveHitboxConfig.Concasse.Duration,
        HitEvent,
        {hrp.CFrame.LookVector},
        MoveHitboxConfig.Concasse.Shape,
        true,
        nil,
        true
    )

    humanoid.WalkSpeed = prevWalkSpeed
    humanoid.JumpPower = prevJumpPower
    prevWalkSpeed = nil
    prevJumpPower = nil
    currentHumanoid = nil
    active = false
end

function Concasse.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "BlackLeg" then return end
    if not ToolController.IsValidCombatTool() then return end

    if StaminaService.GetStamina(player) < 20 then return end

    if tick() - lastUse < (ConcasseConfig.Cooldown or 0) then return end

    active = true
    lastUse = tick()

    MovementClient.StopSprint()
    StunStatusClient.LockFor(ConcasseConfig.Startup + (ConcasseConfig.Endlag or 0))

    local _, _, _, hrp = getCharacter()
    local pos = mouse.Hit and mouse.Hit.Position or (hrp and hrp.Position or Vector3.new())
    task.spawn(performMove, pos)
end

function Concasse.OnInputEnded()
    -- cannot be cancelled
end

return Concasse
