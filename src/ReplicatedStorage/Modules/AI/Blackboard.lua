--ReplicatedStorage.Modules.AI.Blackboard
-- Simple per-NPC state container.

local Blackboard = {}
Blackboard.__index = Blackboard

-- @param level number AI level 1..5
-- @param levelConfig table configuration for this level
function Blackboard.new(level, levelConfig)
    local self = {
        Level = level,
        Config = levelConfig,
        Target = nil,
        TargetDistance = math.huge,
        IsBlocking = false,
        LastPerception = 0,
    }
    return setmetatable(self, Blackboard)
end

return Blackboard
