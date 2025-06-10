--ReplicatedStorage.Modules.Combat.RagdollUtils

local RagdollUtils = {}

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
    local root = getHumanoidRoot(humanoid)
    if root then
        root:SetAttribute("Ragdolled", true)
    end
end

function RagdollUtils.Disable(humanoid)
    if not humanoid then return end
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
