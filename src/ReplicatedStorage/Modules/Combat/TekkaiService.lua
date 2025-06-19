--ReplicatedStorage.Modules.Combat.TekkaiService

local TekkaiService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RokushikiConfig = require(ReplicatedStorage.Modules.Config.Tools.Rokushiki)
local TekkaiConfig = RokushikiConfig.Tekkai or {}
local OverheadBarService = require(ReplicatedStorage.Modules.UI.OverheadBarService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatFolder = remotes:WaitForChild("Combat")
local TekkaiEvent = combatFolder:WaitForChild("TekkaiEvent")

local ACTIVE = {}
local HP = {}
local PREV_MOVEMENT = {}

function TekkaiService.IsActive(player)
    return ACTIVE[player] == true
end

function TekkaiService.GetHP(player)
    return HP[player] or (TekkaiConfig.BlockHP or 750)
end

function TekkaiService.GetDrainRate()
    return TekkaiConfig.StaminaDrain or 10
end

local function cleanup(player)
    ACTIVE[player] = nil
    HP[player] = nil
    PREV_MOVEMENT[player] = nil
end

function TekkaiService.Start(player)
    if ACTIVE[player] then return false end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    ACTIVE[player] = true
    HP[player] = TekkaiConfig.BlockHP or 750

    OverheadBarService.SetTekkaiActive(player, true)
    OverheadBarService.UpdateTekkai(player, HP[player], TekkaiConfig.BlockHP or 750)
    StaminaService.PauseRegen(player)

    PREV_MOVEMENT[player] = {Walk = humanoid.WalkSpeed, Jump = humanoid.JumpPower}
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    return true
end

function TekkaiService.Stop(player)
    if not ACTIVE[player] then return end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    local prev = PREV_MOVEMENT[player]
    if humanoid then
        if prev then
            humanoid.WalkSpeed = prev.Walk or humanoid.WalkSpeed
            humanoid.JumpPower = prev.Jump or humanoid.JumpPower
        else
            local Config = require(ReplicatedStorage.Modules.Config.Config)
            humanoid.WalkSpeed = Config.GameSettings.DefaultWalkSpeed
            humanoid.JumpPower = Config.GameSettings.DefaultJumpPower
        end
    end

    OverheadBarService.SetTekkaiActive(player, false)
    OverheadBarService.UpdateTekkai(player, 0, TekkaiConfig.BlockHP or 750)
    StaminaService.ResumeRegen(player)
    cleanup(player)

    TekkaiEvent:FireAllClients(player, false)
end

function TekkaiService.ApplyDamage(player, dmg)
    if not ACTIVE[player] then return nil end
    local hp = HP[player] or 0
    hp -= dmg
    if hp <= 0 then
        TekkaiService.Stop(player)
        return "Broken"
    else
        HP[player] = hp
        OverheadBarService.UpdateTekkai(player, hp, TekkaiConfig.BlockHP or 750)
        return "Damaged"
    end
end

if RunService:IsServer() then
    Players.PlayerRemoving:Connect(cleanup)

    RunService.Heartbeat:Connect(function(dt)
        for player in pairs(ACTIVE) do
            local amount = TekkaiService.GetDrainRate() * dt
            if not StaminaService.Consume(player, amount) then
                TekkaiService.Stop(player)
            end
        end
    end)
end

return TekkaiService
