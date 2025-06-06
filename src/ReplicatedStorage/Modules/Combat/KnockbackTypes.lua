--ReplicatedStorage.Modules.Combat.KnockbackTypes

local KnockbackTypes = {}

KnockbackTypes.Type = {
    AttackerFacingDirection = "AttackerFacingDirection",
    HitboxVelocityDirection = "HitboxVelocityDirection",
    AwayFromAttacker = "AwayFromAttacker",
}

function KnockbackTypes.GetDirection(directionType, attackerRoot, targetRoot, hitboxDir)
    if directionType == KnockbackTypes.Type.HitboxVelocityDirection then
        if typeof(hitboxDir) == "Vector3" and hitboxDir.Magnitude > 0 then
            return hitboxDir.Unit
        end
    elseif directionType == KnockbackTypes.Type.AwayFromAttacker then
        if attackerRoot and targetRoot then
            local rel = targetRoot.Position - attackerRoot.Position
            rel = Vector3.new(rel.X, 0, rel.Z)
            if rel.Magnitude > 0 then
                return rel.Unit
            end
        end
    end

    if attackerRoot then
        return attackerRoot.CFrame.LookVector
    elseif targetRoot then
        return targetRoot.CFrame.LookVector
    else
        return Vector3.new(0, 0, -1)
    end
end

return KnockbackTypes
