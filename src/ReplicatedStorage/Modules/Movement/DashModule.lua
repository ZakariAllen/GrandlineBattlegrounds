-- ReplicatedStorage.Modules.Movement.DashModule

local DashConfig = require(script.Parent.DashConfig)
local ActorAdapter = require(game.ReplicatedStorage.Modules.AI.ActorAdapter)
local DashModule = {}

local activeDashes = {}

local function resolve(actor)
        local info = ActorAdapter.Get(actor)
        if not info or not info.Character or not info.Humanoid then
                return nil, nil, nil
        end
        return info.Character, info.Humanoid, info.StyleKey
end

local function execute(actor, direction, dashVector, styleKey)
        local key, humanoid, resolvedStyle = resolve(actor)
        if not key then
                return
        end
        if activeDashes[key] then
                return
        end
        activeDashes[key] = true

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
        styleKey = styleKey or resolvedStyle
        if styleKey == "Rokushiki" then
                dashSet = DashConfig.RokuSettings
        end
        local dashSettings = dashSet[direction] or dashSet["Forward"]
        local duration = dashSettings and dashSettings.Duration or 0.25

        task.delay(duration, function()
                activeDashes[key] = nil
                local hum = ActorAdapter.GetHumanoid(actor)
                if hum then
                        hum.AutoRotate = true
                end
        end)
end

-- Called when a player requests a dash.
function DashModule.ExecuteDash(player, direction, dashVector, styleKey)
        execute(player, direction, dashVector, styleKey)
end

-- Mirrors ExecuteDash but accepts an NPC model.
function DashModule.ExecuteDashForModel(model, direction, dashVector, styleKey)
        execute(model, direction, dashVector, styleKey)
end

-- Helper to check dash state
function DashModule.IsDashing(actor)
        local key = resolve(actor)
        return key and activeDashes[key] == true
end

DashModule.IsPlayerDashing = DashModule.IsDashing

-- Cancel an active dash early if needed
function DashModule.CancelDash(actor)
        local key, humanoid = resolve(actor)
        if key and activeDashes[key] then
                activeDashes[key] = nil
                if humanoid then
                        humanoid.AutoRotate = true
                end
        end
end

return DashModule
