--ReplicatedStorage.Modules.Combat.StunStatusClient

local StunStatusClient = {}

-- Internal state
local isStunned = false
local isAttackerLocked = false

-- Getter functions (to be called)
function StunStatusClient.IsStunned()
	return isStunned
end

function StunStatusClient.IsAttackerLocked()
	return isAttackerLocked
end

-- Optional utility
function StunStatusClient:CanAct()
	return not isStunned and not isAttackerLocked
end

-- Allow updates from remote event (used in MovementClient, etc.)
function StunStatusClient.SetStatus(stunned, locked)
	isStunned = stunned
	isAttackerLocked = locked
end

return StunStatusClient
