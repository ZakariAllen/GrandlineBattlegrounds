--ReplicatedStorage.Modules.Combat.Moves.ConcasseClient
local Concasse = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Time = require(ReplicatedStorage.Modules.Util.Time)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

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
    local prevPlat = humanoid.PlatformStand
    local prevAuto = humanoid.AutoRotate
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    playAnimation(animator, Animations.SpecialMoves.PowerKick)

    local start = hrp.Position
    local dest = targetPos
    local dir = dest - start
    local horiz = Vector3.new(dir.X, 0, dir.Z)
    local dist = horiz.Magnitude
    local range = cfg.Range or 65
    if dist > range then
        horiz = horiz.Unit * range
        dist = range
    end
    dest = start + horiz

    local height = math.max(dist * 0.5 + 25, 20)

    -- Initial raycast along the arc to pick the first static obstacle
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    params.IgnoreWater = true

    local steps = 20
    local last = start
    for i = 1, steps do
        local t = i / steps
        local nextPos = start:Lerp(dest, t)
        nextPos += Vector3.new(0, math.sin(math.pi * t) * height, 0)
        local result = Workspace:Raycast(last, nextPos - last, params)
        if result then
            dest = result.Position
            dist = (dest - start).Magnitude
            height = math.max(dist * 0.5 + 25, 20)
            break
        end
        last = nextPos
    end

    StartEvent:FireServer(dest)

    -- Travel time scales between configured min and max based on distance
    range = cfg.Range or 65
    local ratio = math.clamp(dist / range, 0, 1)
    local minTime = cfg.MinTravelTime or 0
    local maxTime = cfg.MaxTravelTime or minTime
    local travelTime = minTime + (maxTime - minTime) * ratio

    local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
    if look.Magnitude == 0 then
        look = Vector3.new(0, 0, -1)
    else
        look = look.Unit
    end

    local startTime = Time.now()
    local lastPos = start
    local airborne = humanoid.FloorMaterial == Enum.Material.Air
    while Time.now() - startTime < travelTime do
        local t = (Time.now() - startTime) / travelTime
        local nextPos = start:Lerp(dest, t)
        nextPos += Vector3.new(0, math.sin(math.pi * t) * height, 0)
        local result = Workspace:Raycast(lastPos, nextPos - lastPos, params)
        if result then
            nextPos = result.Position
            hrp.CFrame = CFrame.lookAt(nextPos, nextPos + look)
            dest = nextPos
            break
        end
        hrp.CFrame = CFrame.lookAt(nextPos, nextPos + look)
        lastPos = nextPos
        if not airborne and humanoid.FloorMaterial == Enum.Material.Air then
            airborne = true
        elseif airborne and humanoid.FloorMaterial ~= Enum.Material.Air then
            dest = nextPos
            break
        end
        RunService.RenderStepped:Wait()
    end
    hrp.CFrame = CFrame.lookAt(dest, dest + look)
    humanoid.PlatformStand = prevPlat
    humanoid.AutoRotate = prevAuto

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

    if Time.now() - lastUse < (ConcasseConfig.Cooldown or 0) then return end

    active = true
    lastUse = Time.now()
    MoveListManager.StartCooldown(KEY.Name, ConcasseConfig.Cooldown or 0)

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
