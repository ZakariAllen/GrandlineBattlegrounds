--[[
    Decision.lua
    Very small utility based decision system. Scores a few candidate actions and
    returns a list ordered by desirability. This is a greatly simplified variant
    of the design outlined in project docs but keeps the same public surface.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AIConfig = require(ReplicatedStorage.Modules.Config.AIConfig)

local Decision = {}

-- Computes a set of desired actions for the NPC
-- @param npc Model
-- @param blackboard Blackboard
-- @return table of action strings
function Decision.Tick(npc, blackboard)
    local actions = {}
    local level = blackboard.ArchetypeLevel or 1
    local levelCfg = AIConfig.Levels[level] or AIConfig.Levels[1]
    local dist = blackboard.DistanceBand

    if dist == "Ideal" then
        table.insert(actions, "PressM1")
    elseif dist == "Long" then
        table.insert(actions, "DashIn")
    else -- TooClose
        if level >= 2 then
            table.insert(actions, "DashOut")
        end
    end

    if level >= 2 and not blackboard.Beliefs.IsBlocking then
        if math.random() < levelCfg.DashDefense then
            table.insert(actions, "StartBlock")
        end
    end

    return actions
end

return Decision
