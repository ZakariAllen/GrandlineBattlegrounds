--ReplicatedStorage.Modules.Combat.ToolController.lua

local ToolController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- 🔁 Config & Animation
local ToolAnimations = require(ReplicatedStorage.Modules.Animations.Tool)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)

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

-- 💤 Temporarily stop the idle stance animation
function ToolController.PauseStance()
        if activeStance and activeStance.IsPlaying then
                activeStance:Stop()
        end
end

-- ▶️ Resume the idle stance animation if it exists
function ToolController.ResumeStance()
        if activeStance and not activeStance.IsPlaying then
                activeStance:Play()
        end
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
            local styleKey = tool.Name
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

                MoveListManager.UpdateVisibleMoves(styleKey)
                return
        end

        -- Clear state if no valid tool
        equippedTool = nil
        equippedStyleKey = nil
        print("[ToolController] Tool unequipped or invalid.")
        MoveListManager.UpdateVisibleMoves(nil)
end

-- ✅ Combat tool validation using ToolConfig
function ToolController.IsValidCombatTool()
	local tool = ToolController.GetEquippedTool()
	if not tool then return false end

	return ToolConfig.ValidCombatTools[tool.Name] or false
end

--[=[
    Returns a list of move identifiers that are currently usable given the
    attacker, target distance band and target state. This does not reveal any
    hidden information and relies entirely on configuration data.

    @param character Model -- the attacking character
    @param distanceBand string -- result from Helpers.GetDistanceBand
    @param targetState table? -- observable state of the target
    @return {string}
]=]
function ToolController.GetUsableMoves(character, distanceBand, targetState)
        local tool = ToolController.GetEquippedTool()
        if not tool then return {} end
        local styleKey = tool.Name
        local config = AbilityConfig[styleKey]
        if not config then return {} end
        distanceBand = distanceBand or "Long"
        targetState = targetState or {}
        local usable = {}
        for moveId, move in pairs(config) do
                local meta = move.Metadata
                if meta then
                        local ok = true
                        if meta.RequiresFacing and targetState.Facing == false then
                                ok = false
                        end
                        if ok then
                                table.insert(usable, moveId)
                        end
                end
        end
        return usable
end

return ToolController
