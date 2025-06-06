--ReplicatedStorage.Modules.Combat.KnockbackService

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local KnockbackConfig = require(script.Parent.KnockbackConfig)

local KnockbackService = {}

KnockbackService.DirectionType = KnockbackConfig.Type

-- Backwards compatible helper
function KnockbackService.ComputeDirection(directionType, attackerRoot, enemyRoot, hitboxDir)
    return KnockbackConfig.GetDirection(directionType, attackerRoot, enemyRoot, hitboxDir)
end

-- Utility to check active knockback forces on a root part
function KnockbackService.IsKnockbackActive(root)
    if not root then return false end
    if root:GetAttribute("KnockbackActive") then return true end
    if root:FindFirstChildOfClass("BodyVelocity") then return true end
    if root:FindFirstChildOfClass("VectorForce") then return true end
    return false
end

local function clearForces(root)
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("BodyMover") or child:IsA("VectorForce") then
            child:Destroy()
        end
    end
end

-- Applies a knockback impulse and force to the humanoid
function KnockbackService.ApplyKnockback(humanoid, direction, distance, duration, lift)
    if not humanoid then return end
    local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end

    direction = typeof(direction) == "Vector3" and direction.Unit or root.CFrame.LookVector
    distance = distance or 25
    duration = duration or 0.4
    lift = lift or 3



    humanoid.PlatformStand = false
    root.Anchored = false
    clearForces(root)

    -- Flag that knockback is active so other systems can recognize it
    root:SetAttribute("KnockbackActive", true)

    local velocity = direction * (distance / duration)
    local mass = root.AssemblyMass > 0 and root.AssemblyMass or 1
    local impulse = Vector3.new(velocity.X, lift, velocity.Z) * mass

    root.AssemblyLinearVelocity = Vector3.zero
    root:ApplyImpulse(impulse)

    local attachment = Instance.new("Attachment")
    attachment.Parent = root
    local vf = Instance.new("VectorForce")
    vf.Attachment0 = attachment
    vf.Force = impulse / duration
    vf.RelativeTo = Enum.ActuatorRelative.World
    vf.Parent = root

    Debris:AddItem(vf, duration)
    Debris:AddItem(attachment, duration)

    root.CFrame = CFrame.new(root.Position, root.Position - direction)

    task.delay(duration, function()
        if root.Parent then
            root:SetAttribute("KnockbackActive", nil)
        end
    end)
end

-- Convenience API to compute direction internally
function KnockbackService.ApplyDirectionalKnockback(humanoid, options)
    options = options or {}
    local dir = KnockbackService.ComputeDirection(
        options.DirectionType,
        options.AttackerRoot,
        options.TargetRoot,
        options.HitboxDirection
    )
    local params = KnockbackConfig.Params and KnockbackConfig.Params[options.DirectionType] or {}
    local distance = options.Distance or params.Distance
    local duration = options.Duration or params.Duration
    local lift = options.Lift or params.Lift
    KnockbackService.ApplyKnockback(humanoid, dir, distance, duration, lift)
end

return KnockbackService
