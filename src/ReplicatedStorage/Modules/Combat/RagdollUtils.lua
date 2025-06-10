--ReplicatedStorage.Modules.Combat.RagdollUtils

local RagdollUtils = {}

-- Track motors disabled for each humanoid so we can re-enable them later
local DisabledMotors = setmetatable({}, {__mode = "k"})
-- Track constraints we create for each humanoid
local CreatedConstraints = setmetatable({}, {__mode = "k"})

local function ragdollJoint(char, part0, part1, attachmentName, className, properties)
    attachmentName = attachmentName .. "RigAttachment"
    local a0 = part0 and part0:FindFirstChild(attachmentName)
    local a1 = part1 and part1:FindFirstChild(attachmentName)
    if not (a0 and a1) then return nil end
    local constraint = Instance.new(className .. "Constraint")
    constraint.Attachment0 = a0
    constraint.Attachment1 = a1
    constraint.Name = "RagdollConstraint" .. part1.Name
    for _, prop in ipairs(properties or {}) do
        constraint[prop[1]] = prop[2]
    end
    constraint.Parent = char
    return constraint
end

local function setupConstraints(humanoid)
    local char = humanoid.Parent
    if not char or CreatedConstraints[humanoid] then return end

    -- Normalize attachment orientations to prevent jitter
    for _, inst in ipairs(char:GetDescendants()) do
        if inst:IsA("Attachment") then
            inst.Axis = Vector3.new(0, 1, 0)
            inst.SecondaryAxis = Vector3.new(0, 0, 1)
            inst.Rotation = Vector3.new(0, 0, 0)
        end
    end

    local created = {}
    local function add(c)
        if c then table.insert(created, c) end
    end

    -- Keep the root part attached to the torso so knockback moves the
    -- entire character instead of separating the body from the HP bar
    add(ragdollJoint(char, char.HumanoidRootPart, char.LowerTorso, "Root", "BallSocket"))

    add(ragdollJoint(char, char.LowerTorso, char.UpperTorso, "Waist", "BallSocket", {
        {"LimitsEnabled", true},
        {"UpperAngle", 5},
    }))
    add(ragdollJoint(char, char.UpperTorso, char.Head, "Neck", "BallSocket", {
        {"LimitsEnabled", true},
        {"UpperAngle", 15},
    }))

    local handProps = {
        {"LimitsEnabled", true},
        {"UpperAngle", 0},
        {"LowerAngle", 0},
    }
    add(ragdollJoint(char, char.LeftLowerArm, char.LeftHand, "LeftWrist", "Hinge", handProps))
    add(ragdollJoint(char, char.RightLowerArm, char.RightHand, "RightWrist", "Hinge", handProps))

    local shinProps = {
        {"LimitsEnabled", true},
        {"UpperAngle", 0},
        {"LowerAngle", -75},
    }
    add(ragdollJoint(char, char.LeftUpperLeg, char.LeftLowerLeg, "LeftKnee", "Hinge", shinProps))
    add(ragdollJoint(char, char.RightUpperLeg, char.RightLowerLeg, "RightKnee", "Hinge", shinProps))

    local footProps = {
        {"LimitsEnabled", true},
        {"UpperAngle", 15},
        {"LowerAngle", -45},
    }
    add(ragdollJoint(char, char.LeftLowerLeg, char.LeftFoot, "LeftAnkle", "Hinge", footProps))
    add(ragdollJoint(char, char.RightLowerLeg, char.RightFoot, "RightAnkle", "Hinge", footProps))

    add(ragdollJoint(char, char.UpperTorso, char.LeftUpperArm, "LeftShoulder", "BallSocket"))
    add(ragdollJoint(char, char.LeftUpperArm, char.LeftLowerArm, "LeftElbow", "BallSocket"))
    add(ragdollJoint(char, char.UpperTorso, char.RightUpperArm, "RightShoulder", "BallSocket"))
    add(ragdollJoint(char, char.RightUpperArm, char.RightLowerArm, "RightElbow", "BallSocket"))
    add(ragdollJoint(char, char.LowerTorso, char.LeftUpperLeg, "LeftHip", "BallSocket"))
    add(ragdollJoint(char, char.LowerTorso, char.RightUpperLeg, "RightHip", "BallSocket"))

    CreatedConstraints[humanoid] = created
end

local function removeConstraints(humanoid)
    local list = CreatedConstraints[humanoid]
    if list then
        for _, c in ipairs(list) do
            if c.Parent then
                c:Destroy()
            end
        end
        CreatedConstraints[humanoid] = nil
    end
end

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

    setupConstraints(humanoid)

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

    removeConstraints(humanoid)
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
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

return RagdollUtils
