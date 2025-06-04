--ReplicatedStorage.Modules.Combat.M1InputClient
local M1InputClient = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local CombatRemotes = Remotes:WaitForChild("Combat")
local M1Event = CombatRemotes:WaitForChild("M1Event")

-- 📦 Modules
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local M1AnimationClient = require(ReplicatedStorage.Modules.Combat.M1AnimationClient)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)

-- 📌 State
local comboIndex = 1
local lastClick = 0
local isAwaitingServer = false

-- 🥊 Main input handler
function M1InputClient.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end

	-- 🖱️ Handle M1
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local now = tick()
		if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() or isAwaitingServer then return end
		if now - lastClick < CombatConfig.M1.DelayBetweenHits then return end

		local tool = ToolController.GetEquippedTool()
		local styleKey = ToolController.GetEquippedStyleKey()
		if not tool or not styleKey or not ToolController.IsValidCombatTool() then
			warn("[M1InputClient] Invalid tool or style")
			return
		end

		print("[M1InputClient] Valid tool:", tool.Name)

		-- Reset combo if delay was too long
		if now - lastClick > CombatConfig.M1.ComboResetTime then
			comboIndex = 1
		end

		lastClick = now
		isAwaitingServer = true
		CombatConfig._lastUsedComboIndex = comboIndex

		-- 📨 Fire to server
		M1Event:FireServer(comboIndex, styleKey)
		print("[M1InputClient] ComboIndex:", comboIndex)

		-- 🎬 Local animation
		M1AnimationClient.Play(styleKey, comboIndex)

		-- 🧊 Trigger hitbox
		task.delay(CombatConfig.M1.HitDelay, function()
			if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end
			HitboxClient.CastHitbox(
				CombatConfig.M1.HitboxOffset,
				CombatConfig.M1.HitboxSize,
				CombatConfig.M1.HitboxDuration
			)
		end)

		-- ⏱️ Combo advance / cooldown
		task.delay(CombatConfig.M1.DelayBetweenHits, function()
			if comboIndex == CombatConfig.M1.ComboHits then
				task.delay(CombatConfig.M1.ComboCooldown, function()
					comboIndex = 1
					isAwaitingServer = false
				end)
			else
				comboIndex += 1
				isAwaitingServer = false
			end
		end)
	end
end

-- 🧹 Input end handler
function M1InputClient.OnInputEnded(input, _)
	-- No movementKeys tracking needed anymore
end

return M1InputClient
