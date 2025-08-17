--ReplicatedStorage.Modules.AI.Perception
-- Naive perception: finds nearest alive player within sight and line-of-sight.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AIConfig = require(ReplicatedStorage.Modules.Config.AIConfig)
local Time = require(ReplicatedStorage.Modules.Util.Time)

local Perception = {}

-- Updates blackboard with nearest target information.
-- @param bb Blackboard
-- @param model Model NPC character
function Perception.Update(bb, model)
    local hrp = model and model:FindFirstChild("HumanoidRootPart")
    if not hrp then
        bb.Target = nil
        bb.TargetDistance = math.huge
        return
    end

    local now = Time.now()
    local sightRange = (AIConfig.Detection and AIConfig.Detection.SightRange) or 90
    local loseSightTime = (AIConfig.Detection and AIConfig.Detection.LoseSightTime) or 2.0

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local nearest
    local nearestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and root then
            local d = (root.Position - hrp.Position).Magnitude
            if d <= sightRange and d < nearestDist then
                params.FilterDescendantsInstances = { model, char }
                local result = workspace:Raycast(hrp.Position, root.Position - hrp.Position, params)
                if not result then
                    nearest = char
                    nearestDist = d
                end
            end
        end
    end

    if nearest then
        bb.Target = nearest
        bb.TargetDistance = nearestDist
        bb.LastSeenTime = now
    else
        if bb.Target then
            local targetRoot = bb.Target:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                bb.TargetDistance = (targetRoot.Position - hrp.Position).Magnitude
            else
                bb.TargetDistance = math.huge
            end
            if now - (bb.LastSeenTime or 0) > loseSightTime then
                bb.Target = nil
                bb.TargetDistance = math.huge
                bb.LastSeenTime = 0
            end
        else
            bb.TargetDistance = math.huge
        end
    end
end

return Perception
