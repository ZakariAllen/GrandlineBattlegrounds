local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MovementRemotes = Remotes:WaitForChild("Movement")
local EvasiveEvent = MovementRemotes:WaitForChild("EvasiveEvent")

local EvasiveService = require(ReplicatedStorage.Modules.Stats.EvasiveService)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)

local validDirections = {
    Forward = true,
    Backward = true,
    Left = true,
    Right = true,
    ForwardLeft = true,
    ForwardRight = true,
    BackwardLeft = true,
    BackwardRight = true,
}

EvasiveEvent.OnServerEvent:Connect(function(player, direction, dashVector)
    if typeof(direction) ~= "string" or not validDirections[direction] then
        warn("[EvasiveServer] Invalid direction:", tostring(direction))
        return
    end

    if not StunService:IsStunned(player) then return end

    if not EvasiveService.Consume(player) then return end

    StunService.ClearStun(player)
    StunService.LockAttacker(player, 1.5)
    EvasiveService.SetActive(player, true)

    DashModule.ExecuteDash(player, direction, dashVector)
    EvasiveEvent:FireAllClients(player, direction)

    task.delay(1.5, function()
        EvasiveService.SetActive(player, false)
    end)
end)

print("[EvasiveServer] Ready")
