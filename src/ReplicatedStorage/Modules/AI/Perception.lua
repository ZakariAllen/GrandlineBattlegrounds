--[[
    Perception.lua
    Computes perceptual information for an NPC and writes results to the blackboard.
    This is intentionally lightweight and avoids any form of hidden information.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local AIConfig = require(ReplicatedStorage.Modules.Config.AIConfig)

local Perception = {}

-- Determines distance band for given NPC/target pair
local function computeDistanceBand(npc, target)
    local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")
    local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
    if not npcRoot or not targetRoot then
        return "Long"
    end
    local dist = (npcRoot.Position - targetRoot.Position).Magnitude
    -- Generic thresholds if tool data not present
    local idealMin, idealMax = 4, 8
    local tool = npc:FindFirstChildOfClass("Tool")
    if tool then
        local meta = ToolConfig.ToolMeta[tool.Name]
        if meta and meta.IdealDistanceBand then
            -- IdealDistanceBand can be a table {min,max}
            if typeof(meta.IdealDistanceBand) == "table" then
                idealMin = meta.IdealDistanceBand[1] or idealMin
                idealMax = meta.IdealDistanceBand[2] or idealMax
            end
        else
            local hb = MoveHitboxConfig[tool.Name]
            if hb and hb.M1 and hb.M1.Range then
                idealMax = hb.M1.Range
            end
        end
    end
    if dist < idealMin then
        return "TooClose"
    elseif dist <= idealMax then
        return "Ideal"
    end
    return "Long"
end

-- Updates the blackboard based on current world state
function Perception.Update(npc, blackboard)
    local target = blackboard.Target
    if target then
        blackboard.LastSeenPos = target.PrimaryPart and target.PrimaryPart.Position or blackboard.LastSeenPos
        blackboard.DistanceBand = computeDistanceBand(npc, target)
        -- Basic beliefs from observable humanoid states
        local hum = target:FindFirstChildOfClass("Humanoid")
        if hum then
            blackboard.Beliefs.IsBlocking = hum:FindFirstChild("Block") and hum.Block.Value or false
            blackboard.Beliefs.IsDashing = hum:FindFirstChild("Dash") and hum.Dash.Value or false
        end
    else
        blackboard.DistanceBand = "Long"
    end
end

return Perception
