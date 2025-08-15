--ReplicatedStorage.Modules.AI.Decision
-- Simple utility-based decision maker.

local Decision = {}

-- Evaluates current state and queues actions.
-- @param model Model NPC
-- @param bb Blackboard
-- @param queue ActionQueue
function Decision.Tick(model, bb, queue)
    local target = bb.Target
    if not target then
        return
    end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetRoot then
        return
    end
    local dist = (targetRoot.Position - hrp.Position).Magnitude
    bb.TargetDistance = dist

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:MoveTo(targetRoot.Position)
    end

    -- L1: only basic M1 when close
    if dist <= 8 then
        queue:PressM1()
    end

    -- L2+: occasional blocking or dash back
    if bb.Level >= 2 then
        local cfg = bb.Config
        if dist <= 10 and math.random() < (cfg.DashDefense or 0) then
            queue:Dash("Backward")
        elseif not bb.IsBlocking and math.random() < 0.1 then
            queue:StartBlock()
        elseif bb.IsBlocking and math.random() < 0.05 then
            queue:ReleaseBlock()
        end
    end
end

return Decision
