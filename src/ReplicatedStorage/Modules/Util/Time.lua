-- ReplicatedStorage.Modules.Util.Time
local RunService = game:GetService("RunService")

local Time = {}

-- Monotonic now(): on server use server time, on client use os.clock()
function Time.now()
    if RunService:IsServer() then
        return workspace:GetServerTimeNow()
    else
        return os.clock()
    end
end

return Time
