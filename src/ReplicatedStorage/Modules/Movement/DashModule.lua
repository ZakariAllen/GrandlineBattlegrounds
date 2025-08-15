-- ReplicatedStorage.Modules.Movement.DashModule

local DashConfig = require(script.Parent.DashConfig)
local DashModule = {}

local activeDashes = {}

-- Called when a dash is requested (just mark dash state & lock autorotate for side/back/diagonal-back)
-- styleKey specifies the equipped combat style, e.g. "Rokushiki". It allows
-- style-specific dash behaviour such as different durations.
function DashModule.ExecuteDash(player, direction, dashVector, styleKey)
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

        local dashSet = DashConfig.Settings
        if styleKey == "Rokushiki" then
                dashSet = DashConfig.RokuSettings
        end
        local dashSettings = dashSet[direction] or dashSet["Forward"]
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

-- Mirror of ExecuteDash but operates on a model/NPC instead of a player
-- @param model Model
-- @param direction string dash direction
-- @param dashVector Vector3? unused for now
-- @param styleKey string combat style
function DashModule.ExecuteDashForModel(model, direction, dashVector, styleKey)
        if activeDashes[model] then
                return
        end
        activeDashes[model] = true

        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid and (
                direction == "Left"
                or direction == "Right"
                or direction == "Backward"
                or direction == "BackwardLeft"
                or direction == "BackwardRight"
        ) then
                humanoid.AutoRotate = false
        end

        local dashSet = DashConfig.Settings
        if styleKey == "Rokushiki" then
                dashSet = DashConfig.RokuSettings
        end
        local dashSettings = dashSet[direction] or dashSet["Forward"]
        local duration = dashSettings and dashSettings.Duration or 0.25

        task.delay(duration, function()
                activeDashes[model] = nil
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                        hum.AutoRotate = true
                end
        end)
end

-- Helper to check dash state
function DashModule.IsPlayerDashing(player)
	return activeDashes[player] == true
end

-- Cancel an active dash early if needed
function DashModule.CancelDash(player)
    if activeDashes[player] then
        activeDashes[player] = nil
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = true
        end
    end
end

return DashModule
