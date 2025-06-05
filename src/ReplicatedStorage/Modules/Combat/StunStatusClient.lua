--ReplicatedStorage.Modules.Combat.StunStatusClient

local StunStatusClient = {}

-- Internal state
local isStunned = false
local serverLocked = false
local localLockUntil = 0

-- Helper to get remaining local lock duration
local function getRemaining()
    return math.max(0, localLockUntil - tick())
end

-- Getter functions (to be called)
function StunStatusClient.IsStunned()
        return isStunned
end

function StunStatusClient.IsAttackerLocked()
        return serverLocked or tick() < localLockUntil
end

-- Optional utility
function StunStatusClient:CanAct()
        return not isStunned and not StunStatusClient.IsAttackerLocked()
end

-- Allow updates from remote event (used in MovementClient, etc.)
function StunStatusClient.SetStatus(stunned, locked)
        isStunned = stunned
        serverLocked = locked
end

function StunStatusClient.LockFor(duration)
        if typeof(duration) ~= "number" or duration <= 0 then return end
        localLockUntil = math.max(localLockUntil, tick() + duration)
end

-- Force the local lock to end after the given duration if it would
-- otherwise last longer. This cannot shorten server-applied locks.
function StunStatusClient.ReduceLockTo(duration)
    if typeof(duration) ~= "number" or duration < 0 then return end
    local newEnd = tick() + duration
    if newEnd < localLockUntil then
        localLockUntil = newEnd
    end
end

-- Expose remaining local lock duration for consumers
function StunStatusClient.GetRemainingLock()
    return getRemaining()
end

return StunStatusClient
