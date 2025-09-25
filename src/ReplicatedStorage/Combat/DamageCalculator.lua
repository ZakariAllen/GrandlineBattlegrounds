local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local CombatConfig = require(ConfigFolder:WaitForChild("Combat"))

local DamageCalculator = {}

function DamageCalculator.Calculate(attackerState, defenderState, attackType, metadata)
    metadata = metadata or {}

    local baseDamage = CombatConfig.Damage[attackType] or 0
    if baseDamage <= 0 then
        return 0
    end

    local damageMultiplier = 1

    if defenderState and defenderState:IsBlocking() then
        damageMultiplier *= CombatConfig.Block.MitigationMultiplier
    end

    if metadata.Headshot then
        damageMultiplier *= CombatConfig.MetadataMultipliers.Headshot
    end

    if metadata.ComboMultiplier then
        damageMultiplier *= metadata.ComboMultiplier
    elseif metadata.ComboIndex then
        local comboBonus = 1 + ((metadata.ComboIndex - 1) * (CombatConfig.Combo.BonusMultiplier - 1))
        damageMultiplier *= comboBonus
    end

    local damage = math.floor(baseDamage * damageMultiplier)
    return math.max(damage, 0)
end

return DamageCalculator
