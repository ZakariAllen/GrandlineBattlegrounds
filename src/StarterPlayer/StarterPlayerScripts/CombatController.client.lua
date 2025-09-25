local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local combatFolder = ReplicatedStorage:WaitForChild("Combat")
local CombatConstants = require(combatFolder:WaitForChild("CombatConstants"))
local combatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")

local currentTargetHumanoid

local function findHumanoidFromPart(part)
    if not part then
        return nil
    end

    local model = part:FindFirstAncestorWhichIsA("Model")
    if not model or model == player.Character then
        return nil
    end

    return model:FindFirstChildOfClass("Humanoid")
end

local function sendAttack(attackType, targetHumanoid)
    combatRemote:FireServer("Attack", {
        AttackType = attackType,
        Target = targetHumanoid,
    })
end

local function performAttack(attackType)
    local targetHumanoid = currentTargetHumanoid
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        targetHumanoid = findHumanoidFromPart(mouse.Target)
    end

    sendAttack(attackType, targetHumanoid)
end

local function lightAttackAction(_, inputState)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    performAttack("Light")
    return Enum.ContextActionResult.Sink
end

local function heavyAttackAction(_, inputState)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    performAttack("Heavy")
    return Enum.ContextActionResult.Sink
end

local function blockAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        combatRemote:FireServer("Block", {
            IsBlocking = true,
        })
    elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
        combatRemote:FireServer("Block", {
            IsBlocking = false,
        })
    end

    return Enum.ContextActionResult.Sink
end

RunService.RenderStepped:Connect(function()
    local targetHumanoid = findHumanoidFromPart(mouse.Target)
    currentTargetHumanoid = targetHumanoid
end)

ContextActionService:BindAction("LightAttack", lightAttackAction, false, Enum.UserInputType.MouseButton1)
ContextActionService:BindAction("HeavyAttack", heavyAttackAction, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.Q)
ContextActionService:BindAction("Block", blockAction, false, Enum.KeyCode.F)

return {}
