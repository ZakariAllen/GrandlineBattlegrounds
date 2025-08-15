--[[
    Blackboard.lua
    Per-NPC memory store used by the combat AI.
    Exposes helper methods for accessing and tracking state.
]]
local Blackboard = {}
Blackboard.__index = Blackboard

-- Creates a new empty blackboard
-- @return Blackboard
function Blackboard.new()
    local self = {
        Target = nil,
        LastSeenPos = nil,
        DistanceBand = "Long",
        Beliefs = {
            IsBlocking = false,
            IsDashing = false,
            InWindup = false,
            InRecovery = false,
            ComboIndex = 0,
        },
        Utilities = {},
        History = {},
        Cooldowns = {},
        Stamina = 0,
        ArchetypeLevel = 1,
        RNG = Random.new(),
    }
    return setmetatable(self, Blackboard)
end

-- Gets a value from the board
function Blackboard:Get(key)
    return self[key]
end

-- Sets a value on the board
function Blackboard:Set(key, value)
    self[key] = value
end

-- Pushes a key into a history bucket (for repetition penalties)
function Blackboard:PushHistory(bucket, key)
    local hist = self.History[bucket]
    if not hist then
        hist = {}
        self.History[bucket] = hist
    end
    hist[key] = (hist[key] or 0) + 1
end

-- Gets the number of times a key has been used in a bucket
function Blackboard:GetRepeatCount(bucket, key)
    local hist = self.History[bucket]
    if not hist then return 0 end
    return hist[key] or 0
end

-- Clears transient state when stunned
function Blackboard:ClearOnStun()
    self.Beliefs.InWindup = false
    self.Beliefs.InRecovery = false
    self.Utilities = {}
end

return Blackboard
