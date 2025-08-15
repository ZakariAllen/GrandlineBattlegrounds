--ReplicatedStorage.Modules.AI.Perception
-- Naive perception: finds nearest alive player.

local Players = game:GetService("Players")

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

    local nearest
    local nearestDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and root then
            local d = (root.Position - hrp.Position).Magnitude
            if d < nearestDist then
                nearest = char
                nearestDist = d
            end
        end
    end

    bb.Target = nearest
    bb.TargetDistance = nearestDist
end

return Perception
