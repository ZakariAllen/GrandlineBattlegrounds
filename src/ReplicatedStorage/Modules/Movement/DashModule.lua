-- ReplicatedStorage.Modules.Movement.DashModule

local DashConfig = require(script.Parent.DashConfig)
local DashModule = {}

local activeDashes = {}

-- Called when a dash is requested (just mark dash state & lock autorotate for side/back/diagonal-back)
function DashModule.ExecuteDash(player, direction, dashVector)
	if activeDashes[player] then
		-- Already dashing, ignore
		return
	end
	activeDashes[player] = true

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	-- Lock AutoRotate for all non-steerable directions
	if humanoid and (
		direction == "Left"
			or direction == "Right"
			or direction == "Backward"
			or direction == "BackwardLeft"
			or direction == "BackwardRight"
		) then
		humanoid.AutoRotate = false
	end

	local dashSettings = DashConfig.Settings[direction] or DashConfig.Settings["Forward"]
	local duration = dashSettings and dashSettings.Duration or 0.25

	-- End dash after duration, unlock autorotate if needed
	task.delay(duration, function()
		activeDashes[player] = nil
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.AutoRotate = true
		end
	end)
end

-- Helper to check dash state
function DashModule.IsPlayerDashing(player)
	return activeDashes[player] == true
end

return DashModule
