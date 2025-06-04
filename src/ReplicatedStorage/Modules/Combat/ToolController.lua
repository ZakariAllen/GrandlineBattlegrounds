--ReplicatedStorage.Modules.Combat.ToolController.lua

local ToolController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- 🔁 Config & Animation
local ToolAnimations = require(ReplicatedStorage.Modules.Animations.Tool)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)

-- Internal state
local equippedTool = nil
local equippedStyleKey = nil
local activeStance = nil

-- 📦 Public access
function ToolController.GetEquippedTool()
	return equippedTool
end

function ToolController.GetEquippedStyleKey()
	return equippedStyleKey
end

-- 🛠️ Equipping logic
function ToolController.SetEquippedTool(tool)
	-- Clean up old stance
	if activeStance then
		activeStance:Stop()
		activeStance:Destroy()
		activeStance = nil
	end

	-- Equip new tool
	if tool then
		local styleKey = tool.Name:gsub(" ", "")
		local styleConfig = ToolAnimations[styleKey]

		equippedTool = tool
		equippedStyleKey = styleKey

		if styleConfig and styleConfig.EquipStance then
			local char = player.Character
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			local animId = styleConfig.EquipStance

			if animId and humanoid then
				local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 2)
				if animator then
					local anim = Instance.new("Animation")
					anim.AnimationId = animId

					local track = animator:LoadAnimation(anim)
					track.Priority = Enum.AnimationPriority.Idle
					track.Looped = true
					track:Play()

					activeStance = track
					print("[ToolController] Equipped:", styleKey, "| Stance:", animId)
				else
					warn("[ToolController] No animator found")
				end
			end
		end

		return
	end

	-- Clear state if no valid tool
	equippedTool = nil
	equippedStyleKey = nil
	print("[ToolController] Tool unequipped or invalid.")
end

-- ✅ Combat tool validation using ToolConfig
function ToolController.IsValidCombatTool()
	local tool = ToolController.GetEquippedTool()
	if not tool then return false end

	return ToolConfig.ValidCombatTools[tool.Name] or false
end

return ToolController
