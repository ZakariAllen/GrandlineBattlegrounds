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
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)

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
    local cfg = AbilityConfig.BlackLeg.PartyTableKick
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not hrp or not humanoid then active = false return end

    local animId = Animations.SpecialMoves.PartyTableKick
    local track = playAnimation(animator, animId)
    StartEvent:FireServer()

    local startTime = tick()
    while tick() - startTime < cfg.Startup do
        if not held or (not cfg.HyperArmor and StunStatusClient.IsStunned()) then
            active = false
            if track then track:Stop() track:Destroy() end
            return
        end
        RunService.RenderStepped:Wait()
    end

    local interval = cfg.Duration / math.max(cfg.Hits - 1, 1)
    for i = 1, cfg.Hits do
        if not held or StunStatusClient.IsStunned() then
            active = false
            if track then track:Stop() track:Destroy() end
            return
        end
        HitboxClient.CastHitbox(cfg.HitboxOffset, cfg.HitboxSize, cfg.HitboxDuration, HitEvent, {i == cfg.Hits}, "Cylinder")
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
end

function PartyTableKick.OnInputBegan(input, gp)
    if gp or input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end
    local style = ToolController.GetEquippedStyleKey()
    if style ~= "BlackLeg" then return end
    if not ToolController.IsValidCombatTool() then return end
    local cfg = AbilityConfig.BlackLeg.PartyTableKick
    if tick() - lastUse < (cfg.Cooldown or 0) then return end

    held = true
    active = true
    lastUse = tick()
    task.spawn(performMove)
end

function PartyTableKick.OnInputEnded(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    held = false
    active = false
end

return PartyTableKick
