--ReplicatedStorage.Modules.Combat.RagdollUtils

local RagdollUtils = {}

-- Track motors disabled for each humanoid so we can re-enable them later
local DisabledMotors = setmetatable({}, {__mode = "k"})

local function getHumanoidRoot(humanoid)
    if not humanoid then return nil end
    local char = humanoid.Parent
    return char and char:FindFirstChild("HumanoidRootPart")
end

function RagdollUtils.Enable(humanoid)
    if not humanoid then return end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false

    -- Disable all motors so the character goes completely limp
    if not DisabledMotors[humanoid] then
        local char = humanoid.Parent
        if char then
            local motors = {}
            for _, inst in ipairs(char:GetDescendants()) do
                if inst:IsA("Motor6D") then
                    table.insert(motors, inst)
                    inst.Enabled = false
                end
            end
            DisabledMotors[humanoid] = motors
        end
    end

    -- Stop any currently playing animations
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
    local root = getHumanoidRoot(humanoid)
    if root then
        root:SetAttribute("Ragdolled", true)
    end
end

function RagdollUtils.Disable(humanoid)
    if not humanoid then return end
    local motors = DisabledMotors[humanoid]
    if motors then
        for _, motor in ipairs(motors) do
            if motor.Parent then
                motor.Enabled = true
            end
        end
        DisabledMotors[humanoid] = nil
    end
    humanoid.PlatformStand = false
    humanoid.AutoRotate = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    local root = getHumanoidRoot(humanoid)
    if root then
        root:SetAttribute("Ragdolled", nil)
    end
end

return RagdollUtils
