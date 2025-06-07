-- ServerScriptService > DashServer.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MovementRemotes = Remotes:WaitForChild("Movement")
local DashEvent = MovementRemotes:WaitForChild("DashEvent")

local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)

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
       if not StaminaService.Consume(player, 10) then return end

       local char = player.Character
       local tool = char and char:FindFirstChildOfClass("Tool")

       -- Allow dashing even when no tool is equipped. Only the Rokushiki tool
       -- modifies dash behaviour, so styleKey is nil unless that tool is
       -- equipped.
       local equippedStyle = nil
       if tool and tool.Name == "Rokushiki" then
               equippedStyle = "Rokushiki"
       end

       -- Always forward dashVector to the DashModule (module handles all logic now)
       DashModule.ExecuteDash(player, direction, dashVector, equippedStyle)

       -- Notify all clients so they can play VFX/SFX for this dash
       DashEvent:FireAllClients(player, direction, equippedStyle)
end)

print("[DashServer] Ready")
