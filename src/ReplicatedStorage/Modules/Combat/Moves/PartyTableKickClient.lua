--ReplicatedStorage.Modules.Combat.Moves.PartyTableKickClient
local PartyTableKick = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PartyTableKickStart")
local HitEvent = CombatRemotes:WaitForChild("PartyTableKickHit")
local StopEvent = CombatRemotes:WaitForChild("PartyTableKickStop")
local VFXEvent = CombatRemotes:WaitForChild("PartyTableKickVFX")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local BlackLegConfig = require(ReplicatedStorage.Modules.Config.Tools.BlackLeg)
local PartyTableKickConfig = BlackLegConfig.PartyTableKick
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local PartyTableKickVFX = require(ReplicatedStorage.Modules.Effects.PartyTableKickVFX)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

local KEY = Enum.KeyCode.E
local active = false
local held = false
local lastUse = 0

local currentTrack
local currentHumanoid
local prevWalkSpeed

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

local function cleanup()
    if currentTrack then
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
    end
    if currentHumanoid and prevWalkSpeed then
        currentHumanoid.WalkSpeed = prevWalkSpeed
    end
    StopEvent:FireServer()
end

local function performMove()
    local cfg = PartyTableKickConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not hrp or not humanoid then
        if DEBUG then print("[PartyTableKickClient] Invalid character state") end
        active = false
        return
    end

    currentHumanoid = humanoid
    prevWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 3

    local animId = Animations.SpecialMoves.PartyTableKick
    currentTrack = playAnimation(animator, animId)
    if DEBUG then print("[PartyTableKickClient] Animation started") end
    StartEvent:FireServer()
    if DEBUG then print("[PartyTableKickClient] StartEvent fired") end
    local function endMove()
        if not active then return end
        active = false
        cleanup()
    end

    local startTime = tick()
    local canCancel = cfg.Cancelable ~= false
    while tick() - startTime < cfg.Startup do
        if not held or (canCancel and not cfg.HyperArmor and StunStatusClient.IsStunned()) then
            if DEBUG then print("[PartyTableKickClient] Startup cancelled") end
            endMove()
            return
        end
        RunService.RenderStepped:Wait()
    end

    local interval = cfg.Duration / math.max(cfg.Hits - 1, 1)
    for i = 1, cfg.Hits do
        if not held or (canCancel and StunStatusClient.IsStunned()) then
            if DEBUG then print("[PartyTableKickClient] Move interrupted") end
            endMove()
            return
        end
        local hitbox = HitboxClient.CastHitbox(
            PartyTableKickConfig.Hitbox.Offset,
            PartyTableKickConfig.Hitbox.Size,
            PartyTableKickConfig.Hitbox.Duration,
            HitEvent,
            {i == cfg.Hits},
            PartyTableKickConfig.Hitbox.Shape,
            true
        )
        if hitbox then
            PartyTableKickVFX.Create(hitbox)
        end
        if i < cfg.Hits then
            local waitStart = tick()
            while tick() - waitStart < interval do
                if not held or (canCancel and StunStatusClient.IsStunned()) then
                    endMove()
                    return
                end
                RunService.RenderStepped:Wait()
            end
        end
    end
    endMove()
    if DEBUG then print("[PartyTableKickClient] Move finished") end
end

function PartyTableKick.OnInputBegan(input, gp)
    if DEBUG then
        local codeName = input.KeyCode and input.KeyCode.Name or input.UserInputType.Name
        print("[PartyTableKickClient] OnInputBegan:", codeName, "GP:", gp)
    end
    -- Ignore gameProcessed so the move still triggers even if a GUI consumed the input
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then
        if DEBUG then print("[PartyTableKickClient] Input blocked") end
        return
    end
    if active then
        if DEBUG then print("[PartyTableKickClient] Already active") end
        return
    end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then
        if DEBUG then print("[PartyTableKickClient] Player stunned or locked") end
        return
    end
    local style = ToolController.GetEquippedStyleKey()
    if style ~= "BlackLeg" then
        if DEBUG then print("[PartyTableKickClient] Style not BlackLeg:", style) end
        return
    end
    if not ToolController.IsValidCombatTool() then
        if DEBUG then print("[PartyTableKickClient] Invalid combat tool") end
        return
    end
    if StaminaService.GetStamina(Players.LocalPlayer) < 10 then
        if DEBUG then print("[PartyTableKickClient] Not enough stamina") end
        return
    end
    local cfg = PartyTableKickConfig
    if tick() - lastUse < (cfg.Cooldown or 0) then
        if DEBUG then print("[PartyTableKickClient] On cooldown") end
        return
    end

    if DEBUG then print("[PartyTableKickClient] Move initiated") end
    held = true
    active = true
    lastUse = tick()
    MoveListManager.StartCooldown(KEY.Name, cfg.Cooldown or 0)

    MovementClient.StopSprint()
    local lockTime = cfg.Startup + cfg.Duration + (cfg.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(performMove)
end

function PartyTableKick.OnInputEnded(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    held = false
    if active then
        cleanup()
        active = false
    else
        StopEvent:FireServer()
    end
    -- Reduce attacker lock to just the endlag duration when the move is released early
    StunStatusClient.ReduceLockTo(PartyTableKickConfig.Endlag or 0)
    if DEBUG then print("[PartyTableKickClient] Input ended") end
end

VFXEvent.OnClientEvent:Connect(function(kickPlayer)
    if typeof(kickPlayer) ~= "Instance" then return end
    if kickPlayer == Players.LocalPlayer then return end

    local char = kickPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        PartyTableKickVFX.Create(hrp)
    end
end)

return PartyTableKick
