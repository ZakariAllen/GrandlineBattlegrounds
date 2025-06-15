--ReplicatedStorage.Modules.Combat.StunStatusClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Config.Config)

local StunStatusClient = {}

local DEBUG = Config.GameSettings.DebugEnabled

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
function StunStatusClient.SetStatus(stunned, locked, lockRemaining)
        isStunned = stunned
        serverLocked = locked
        if typeof(lockRemaining) == "number" and lockRemaining > 0 then
            localLockUntil = math.max(localLockUntil, tick() + lockRemaining)
        end
        if DEBUG then
            print("[StunStatusClient] Status update", stunned, locked, lockRemaining)
        end
end

function StunStatusClient.LockFor(duration)
        if typeof(duration) ~= "number" or duration <= 0 then return end
        localLockUntil = math.max(localLockUntil, tick() + duration)
        if DEBUG then
            print("[StunStatusClient] Local lock for", duration)
        end
end

-- Force the local lock to end after the given duration if it would
-- otherwise last longer. This cannot shorten server-applied locks.
function StunStatusClient.ReduceLockTo(duration)
    if typeof(duration) ~= "number" or duration < 0 then return end
    local newEnd = tick() + duration
    if newEnd < localLockUntil then
        localLockUntil = newEnd
        if DEBUG then
            print("[StunStatusClient] Reduced lock to", duration)
        end
    end
end

-- Expose remaining local lock duration for consumers
function StunStatusClient.GetRemainingLock()
    return getRemaining()
end

return StunStatusClient
