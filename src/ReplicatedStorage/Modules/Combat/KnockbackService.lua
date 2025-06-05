--ReplicatedStorage.Modules.Combat.KnockbackService

local KnockbackService = {}

KnockbackService.DirectionType = {
    AttackerFacingDirection = "AttackerFacingDirection",
    HitboxVelocityDirection = "HitboxVelocityDirection",
    AwayFromAttacker = "AwayFromAttacker",
}

-- Computes the knockback vector based on the direction type.
function KnockbackService.ComputeDirection(directionType, attackerRoot, enemyRoot, hitboxDir)
    if directionType == KnockbackService.DirectionType.HitboxVelocityDirection then
        if typeof(hitboxDir) == "Vector3" and hitboxDir.Magnitude > 0 then
            return hitboxDir.Unit
        end
    elseif directionType == KnockbackService.DirectionType.AwayFromAttacker then
        if attackerRoot and enemyRoot then
            local rel = enemyRoot.Position - attackerRoot.Position
            rel = Vector3.new(rel.X, 0, rel.Z)
            if rel.Magnitude > 0 then
                return rel.Unit
            end
        end
    end

    if attackerRoot then
        return attackerRoot.CFrame.LookVector
    elseif enemyRoot then
        return enemyRoot.CFrame.LookVector
    else
        return Vector3.new(0, 0, -1)
    end
end

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Applies a knockback force to the target humanoid's root part
-- direction: Vector3 direction of knockback
-- distance: studs to travel over the duration
-- duration: time in seconds the knockback force is applied
-- lift: upward velocity component
function KnockbackService.ApplyKnockback(humanoid, direction, distance, duration, lift)
    if not humanoid then return end
    local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end

    direction = typeof(direction) == "Vector3" and direction.Unit or root.CFrame.LookVector
    distance = distance or 25
    duration = duration or 0.4
    lift = lift or 3

    local playerOwner = Players:GetPlayerFromCharacter(humanoid.Parent)
    local originalOwner = root:GetNetworkOwner()

    -- Server controls physics during knockback
    root:SetNetworkOwner(nil)
    -- Mark knockback active so other systems don't zero velocity
    root:SetAttribute("KnockbackActive", true)

    local speed = distance / duration
    local knockVelocity = Vector3.new(direction.X * speed, lift, direction.Z * speed)

    -- Directly set velocity instead of applying physical forces
    root.AssemblyLinearVelocity = knockVelocity

    -- Face away from the attacker
    root.CFrame = CFrame.new(root.Position, root.Position - direction)

    -- Restore network ownership after knockback duration
    task.delay(duration, function()
        if root.Parent then
            root:SetNetworkOwner(originalOwner or playerOwner)
            root:SetAttribute("KnockbackActive", nil)
        end
    end)
end

return KnockbackService
