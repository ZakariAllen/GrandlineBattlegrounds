local CombatConfig = {
    AttackCooldown = 0.55,
    Block = {
        StartCost = 8,
        StaminaDrainPerSecond = 20,
        MitigationMultiplier = 0.3,
    },
    Stamina = {
        Max = 100,
        RegenPerSecond = 15,
        AttackCost = {
            Light = 12,
            Heavy = 32,
        },
    },
    Damage = {
        Light = 12,
        Heavy = 28,
    },
    Range = {
        Light = 10,
        Heavy = 12,
        Default = 10,
    },
    MetadataMultipliers = {
        Headshot = 1.5,
    },
    Combo = {
        MinimumWindow = 0.15,
        MaximumWindow = 0.6,
        BonusMultiplier = 1.2,
    },
}

return CombatConfig
