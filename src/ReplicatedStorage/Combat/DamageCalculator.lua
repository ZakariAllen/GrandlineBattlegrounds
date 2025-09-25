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

    local isBlocking = defenderState and defenderState:IsBlocking()
    if isBlocking then
        if metadata.PerfectBlock then
            damageMultiplier *= CombatConfig.Block.PerfectMitigationMultiplier or 0
        else
            damageMultiplier *= CombatConfig.Block.MitigationMultiplier
        end
    end

    if metadata.Headshot then
        damageMultiplier *= CombatConfig.MetadataMultipliers.Headshot
    end

    if metadata.ComboMultiplier then
        damageMultiplier *= math.max(metadata.ComboMultiplier, 0)
    elseif metadata.ComboIndex then
        local comboBonus = 1 + ((metadata.ComboIndex - 1) * (CombatConfig.Combo.BonusMultiplier - 1))
        damageMultiplier *= comboBonus
    end

    local damage = math.floor(baseDamage * damageMultiplier)
    return math.max(damage, 0)
end

return DamageCalculator
