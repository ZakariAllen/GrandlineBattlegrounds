--ReplicatedStorage.Modules.Combat.Moves.PartyTableKickClient
local PartyTableKick = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PartyTableKickStart")
local HitEvent = CombatRemotes:WaitForChild("PartyTableKickHit")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local PartyTableKickConfig = require(ReplicatedStorage.Modules.Config.PartyTableKickConfig)
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

local KEY = Enum.KeyCode.E
local active = false
local held = false
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
    local cfg = PartyTableKickConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not hrp or not humanoid then
        if DEBUG then print("[PartyTableKickClient] Invalid character state") end
        active = false
        return
    end

    local animId = Animations.SpecialMoves.PartyTableKick
    local track = playAnimation(animator, animId)
    if DEBUG then print("[PartyTableKickClient] Animation started") end
    StartEvent:FireServer()
    if DEBUG then print("[PartyTableKickClient] StartEvent fired") end

    local startTime = tick()
    while tick() - startTime < cfg.Startup do
        if not held or (not cfg.HyperArmor and StunStatusClient.IsStunned()) then
            if DEBUG then print("[PartyTableKickClient] Startup cancelled") end
            active = false
            if track then track:Stop() track:Destroy() end
            return
        end
        RunService.RenderStepped:Wait()
    end

    local interval = cfg.Duration / math.max(cfg.Hits - 1, 1)
    for i = 1, cfg.Hits do
        if not held or StunStatusClient.IsStunned() then
            if DEBUG then print("[PartyTableKickClient] Move interrupted") end
            active = false
            if track then track:Stop() track:Destroy() end
            return
        end
        HitboxClient.CastHitbox(
            MoveHitboxConfig.PartyTableKick.Offset,
            MoveHitboxConfig.PartyTableKick.Size,
            MoveHitboxConfig.PartyTableKick.Duration,
            HitEvent,
            {i == cfg.Hits},
            MoveHitboxConfig.PartyTableKick.Shape
        )
        if SoundConfig.Combat.BlackLeg and SoundConfig.Combat.BlackLeg.Hit and hrp then
            SoundUtils:PlaySpatialSound(SoundConfig.Combat.BlackLeg.Hit, hrp)
        end
        if i < cfg.Hits then
            local waitStart = tick()
            while tick() - waitStart < interval do
                if not held or StunStatusClient.IsStunned() then
                    active = false
                    if track then track:Stop() track:Destroy() end
                    return
                end
                RunService.RenderStepped:Wait()
            end
        end
    end
    active = false
    if track then track:Stop() track:Destroy() end
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
    local cfg = PartyTableKickConfig
    if tick() - lastUse < (cfg.Cooldown or 0) then
        if DEBUG then print("[PartyTableKickClient] On cooldown") end
        return
    end

    if DEBUG then print("[PartyTableKickClient] Move initiated") end
    held = true
    active = true
    lastUse = tick()
    task.spawn(performMove)
end

function PartyTableKick.OnInputEnded(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    held = false
    active = false
    if DEBUG then print("[PartyTableKickClient] Input ended") end
end

return PartyTableKick
