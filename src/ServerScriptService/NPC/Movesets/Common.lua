local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)

local Common = {}

-- Use global combat settings for combo timing so NPCs mirror player behaviour
Common.comboLength = CombatConfig.M1.ComboHits
Common.comboDelay = CombatConfig.M1.DelayBetweenHits

function Common.attack(character, target, comboIndex)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local tRoot = target and target:FindFirstChild("HumanoidRootPart")
    if not hrp or not tRoot then
        return false
    end

    local range = CombatConfig.M1.ServerHitRange or 6
    return (hrp.Position - tRoot.Position).Magnitude <= range
end

function Common.block(character, duration)
    -- Placeholder; actual block logic is handled elsewhere
    task.wait(duration)
end

function Common.dash(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = hrp.CFrame - hrp.CFrame.LookVector * 10
end

return Common
