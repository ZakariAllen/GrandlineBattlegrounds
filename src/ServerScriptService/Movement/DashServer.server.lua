-- ServerScriptService > DashServer.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MovementRemotes = Remotes:WaitForChild("Movement")
local DashEvent = MovementRemotes:WaitForChild("DashEvent")

local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)

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

DashEvent.OnServerEvent:Connect(function(player, direction, dashVector)
        if typeof(direction) ~= "string" or not validDirections[direction] then
                warn("[DashServer] Invalid dash direction:", tostring(direction))
                return
        end

       if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then
               return
       end
       if BlockService.IsBlocking(player) or BlockService.IsInStartup(player) then
               return
       end

        -- Always forward dashVector to the DashModule (module handles all logic now)
        DashModule.ExecuteDash(player, direction, dashVector)
end)
