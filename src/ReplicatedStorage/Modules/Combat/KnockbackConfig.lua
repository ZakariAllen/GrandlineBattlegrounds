--ReplicatedStorage.Modules.Combat.KnockbackConfig

local KnockbackConfig = {}

KnockbackConfig.Type = {
    AttackerFacingDirection = "AttackerFacingDirection",
    HitboxVelocityDirection = "HitboxVelocityDirection",
    HitboxTravelDirection = "HitboxTravelDirection",
    AwayFromAttacker = "AwayFromAttacker",
}

-- Default parameters for each knockback type
KnockbackConfig.Params = {
    [KnockbackConfig.Type.AttackerFacingDirection] = {
        Distance = 20,
        Duration = 0.3,
        Lift = 3,
    },
    [KnockbackConfig.Type.HitboxVelocityDirection] = {
        Distance = 20,
        Duration = 0.3,
        Lift = 3,
    },
    [KnockbackConfig.Type.HitboxTravelDirection] = {
        Distance = 20,
        Duration = 0.3,
        Lift = 3,
    },
    [KnockbackConfig.Type.AwayFromAttacker] = {
        Distance = 20,
        Duration = 0.3,
        Lift = 3,
    },
}

function KnockbackConfig.GetDirection(directionType, attackerRoot, targetRoot, hitboxDir)
    if directionType == KnockbackConfig.Type.HitboxVelocityDirection
        or directionType == KnockbackConfig.Type.HitboxTravelDirection then
        if typeof(hitboxDir) == "Vector3" and hitboxDir.Magnitude > 0 then
            return hitboxDir.Unit
        end
    elseif directionType == KnockbackConfig.Type.AwayFromAttacker then
        if attackerRoot and targetRoot then
            local rel = targetRoot.Position - attackerRoot.Position
            rel = Vector3.new(rel.X, 0, rel.Z)
            if rel.Magnitude > 0 then
                return rel.Unit
            end
        end
    end

    if attackerRoot then
        local look = attackerRoot.CFrame.LookVector
        if look.Magnitude > 0 then
            return look.Unit
        end
    end
    if targetRoot then
        local look = targetRoot.CFrame.LookVector
        if look.Magnitude > 0 then
            return look.Unit
        end
    end
    return Vector3.new(0, 0, -1)
end

return KnockbackConfig
