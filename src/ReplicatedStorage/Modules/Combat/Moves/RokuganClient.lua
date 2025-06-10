--ReplicatedStorage.Modules.Combat.Moves.RokuganClient
local Rokugan = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("RokuganStart")
local HitEvent = CombatRemotes:WaitForChild("RokuganHit")

local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local MoveConfig = AbilityConfig.Rokushiki.Rokugan
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local UltService = require(ReplicatedStorage.Modules.Stats.UltService)
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

local KEY = Enum.KeyCode.C
local active = false
local lastUse = 0

local player = Players.LocalPlayer

local function getCharacter()
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return char, humanoid, animator, hrp
end

local function performMove()
    local cfg = MoveConfig
    local char, humanoid, animator, hrp = getCharacter()
    if not char or not humanoid or not hrp then
        active = false
        return
    end

    MovementClient.StopSprint()

    task.wait(cfg.Startup)

    local startCF = hrp.CFrame
    local destCF = startCF * CFrame.new(0, 0, -30)
    hrp.CFrame = destCF
    StartEvent:FireServer(destCF.Position)

    local dir = startCF.LookVector

    HitboxClient.CastHitbox(
        MoveHitboxConfig.Rokugan.Offset,
        MoveHitboxConfig.Rokugan.Size,
        MoveHitboxConfig.Rokugan.Duration,
        HitEvent,
        {dir},
        MoveHitboxConfig.Rokugan.Shape,
        false,
        nil,
        true,
        startCF
    )

    task.wait(cfg.Endlag)

    active = false
end

function Rokugan.OnInputBegan(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= KEY then return end
    if active then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end

    local style = ToolController.GetEquippedStyleKey()
    if style ~= "Rokushiki" then return end
    if not ToolController.IsValidCombatTool() then return end

    if StaminaService.GetStamina(player) < (MoveConfig.StaminaCost or 0) then return end
    if UltService.GetUlt(player) < UltService.GetMaxUlt(player) then return end

    if tick() - lastUse < (MoveConfig.Cooldown or 0) then return end

    active = true
    lastUse = tick()
    MoveListManager.StartCooldown(KEY.Name, MoveConfig.Cooldown or 0)

    local lockTime = (MoveConfig.Startup or 0) + (MoveConfig.Endlag or 0)
    StunStatusClient.LockFor(lockTime)

    task.spawn(performMove)
end

function Rokugan.OnInputEnded() end

return Rokugan
