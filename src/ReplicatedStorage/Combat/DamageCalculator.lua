local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConstants = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatConstants"))

local DamageCalculator = {}

function DamageCalculator.Calculate(attackerState, defenderState, attackType, metadata)
    metadata = metadata or {}

    local baseDamage = CombatConstants.DAMAGE[attackType] or 0
    if baseDamage <= 0 then
        return 0
    end

    local damageMultiplier = 1

    if defenderState and defenderState:IsBlocking() then
        damageMultiplier *= 0.3
    end

    if metadata.Headshot then
        damageMultiplier *= 1.5
    end

    if metadata.ComboMultiplier then
        damageMultiplier *= metadata.ComboMultiplier
    end

    local damage = math.floor(baseDamage * damageMultiplier)
    return math.max(damage, 0)
end

return DamageCalculator
