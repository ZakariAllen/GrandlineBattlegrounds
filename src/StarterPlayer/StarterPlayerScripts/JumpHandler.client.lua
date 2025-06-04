-- JumpHandler (LocalScript)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ✅ Updated path to JumpCooldownEvent under Remotes.Combat
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local JumpCooldownEvent = CombatRemotes:WaitForChild("JumpCooldownEvent")

local JumpController = require(ReplicatedStorage.Modules.Client.JumpController)

-- 🟢 Initialization
print("[JumpHandler] JumpController initialized.")

-- ⏱️ Server requests jump cooldown
JumpCooldownEvent.OnClientEvent:Connect(function(duration)
	print("[JumpHandler] Received jump cooldown trigger:", duration)
	JumpController.StartCooldown(duration)
end)
