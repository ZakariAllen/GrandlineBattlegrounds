local CombatConfig = {
    AttackCooldown = 0.55,
    Block = {
        StartCost = 8,
        StaminaDrainPerSecond = 20,
        MitigationMultiplier = 0.3,
        HitStaminaMultiplier = 0.45,
        HitStaminaFlatCost = 6,
        GuardBreakThreshold = 0,
        GuardBreakCooldown = 1.6,
        PerfectWindow = 0.25,
        PerfectMitigationMultiplier = 0,
        PerfectStaminaRefund = 10,
        PerfectCounterDamage = 4,
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
