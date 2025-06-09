--ReplicatedStorage.Modules.Combat.Moves.TekkaiClient
local Tekkai = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local TekkaiEvent = CombatRemotes:WaitForChild("TekkaiEvent")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local TekkaiConfig = AbilityConfig.Rokushiki.Tekkai or {}
local Config = require(ReplicatedStorage.Modules.Config.Config)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)

local KEY = Enum.KeyCode.E
local active = false
local track
local prevWalk
local prevJump

local function getCharacter()
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    return char, humanoid, animator
end

local function playAnimation(animator, animId)
    if not animator or not animId then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local t = animator:LoadAnimation(anim)
    t.Priority = Enum.AnimationPriority.Action
    t.Looped = true
    t:Play()
    return t
end

TekkaiEvent.OnClientEvent:Connect(function(tekkaiPlayer, state)
    if tekkaiPlayer ~= Players.LocalPlayer then return end
    local char, humanoid, animator = getCharacter()
    if not humanoid then return end
    if state then
        active = true
        if not prevWalk then prevWalk = humanoid.WalkSpeed end
        if not prevJump then prevJump = humanoid.JumpPower end
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        track = playAnimation(animator, Animations.Blocking.TekkaiHold)
    else
        active = false
        if track then
            track:Stop()
            track:Destroy()
            track = nil
        end
        humanoid.WalkSpeed = prevWalk or Config.GameSettings.DefaultWalkSpeed
        humanoid.JumpPower = prevJump or Config.GameSettings.DefaultJumpPower
        prevWalk = nil
        prevJump = nil
    end
end)

function Tekkai.OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end
    if BlockClient.IsBlocking() then return end
    local style = ToolController.GetEquippedStyleKey()
    if style ~= "Rokushiki" then return end
    if not ToolController.IsValidCombatTool() then return end
    if StaminaService.GetStamina(Players.LocalPlayer) <= 0 then return end

    local _, humanoid = getCharacter()
    if humanoid then
        prevWalk = humanoid.WalkSpeed
        prevJump = humanoid.JumpPower
    end
    MovementClient.StopSprint()
    TekkaiEvent:FireServer(true)
end

function Tekkai.OnInputEnded(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if not active then return end
    TekkaiEvent:FireServer(false)
end

return Tekkai
