--ReplicatedStorage.Modules.AI.Decision
-- Simple utility-based decision maker.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local Time = require(ReplicatedStorage.Modules.Util.Time)

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

    local styleKey = model:GetAttribute("StyleKey") or "BasicCombat"
    local meta = ToolConfig.ToolMeta[styleKey]
    local bands = meta and meta.IdealDistanceBand or { TooClose = 3, Ideal = 8, Long = 15 }

    local band
    if dist <= bands.TooClose then
        band = "TooClose"
    elseif dist <= bands.Ideal then
        band = "Ideal"
    else
        band = "Long"
    end
    bb.DistanceBand = band
    bb.IsClosing = false

    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    if band == "Long" then
        bb.IsClosing = true
        hum:MoveTo(targetRoot.Position)
        if dist > bands.Long and bb.Level >= 2 and math.random() < 0.1 then
            queue:Dash("Forward")
        end
    elseif band == "TooClose" then
        hum:Move(hrp.CFrame.LookVector * -1)
        if bb.Level >= 2 and math.random() < (bb.Config.DashDefense or 0) then
            queue:Dash("Backward")
        end
    else -- Ideal band
        if dist > bands.TooClose + 1 then
            bb.IsClosing = true
            hum:MoveTo(targetRoot.Position)
        else
            -- stop pathing and face target
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))

            local now = Time.now()
            if now >= bb.NextStrafeChange then
                bb.StrafeDir = math.random(0, 1) == 0 and -1 or 1
                bb.NextStrafeChange = now + math.random(1, 2)
            end

            hum:Move(hrp.CFrame.RightVector * bb.StrafeDir * 0.5)
        end
        queue:PressM1()
    end

    -- L2+: occasional blocking
    if bb.Level >= 2 then
        if not bb.IsBlocking and math.random() < 0.1 then
            queue:StartBlock()
        elseif bb.IsBlocking and math.random() < 0.05 then
            queue:ReleaseBlock()
        end
    end
end

return Decision
