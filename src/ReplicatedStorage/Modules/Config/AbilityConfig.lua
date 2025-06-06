local AbilityConfig = {}

AbilityConfig.BlackLeg = {
    PartyTableKick = {
        Hits = 10,
        Duration = 2.4,
        DamagePerHit = 15,
        StunDuration = 0.75,
        Startup = 1.3,
        HyperArmor = false,
        GuardBreak = false,
        Endlag = 1.3,
        HitboxDuration = 0.1,
        Cooldown = 12,
        KnockbackDirection = "AwayFromAttacker",
    },
    PowerKick = {
        Damage = 50,
        StunDuration = 2.0,
        Startup = 0.4,
        HyperArmor = false,
        GuardBreak = true,
        PerfectBlockable = true,
        Endlag = 0.5,
        HitboxDuration = 0.2,
        Cooldown = 12,
    },
}

AbilityConfig.BasicCombat = {
    PowerPunch = {
        Damage = 120,
        StunDuration = 2.0,
        Startup = 1.0,
        HyperArmor = true,
        GuardBreak = true,
        PerfectBlockable = true,
        Endlag = 0.7,
        HitboxDuration = 0.2,
        HitboxDistance = 8,
        Cooldown = 7,
        KnockbackDirection = "AttackerFacingDirection",
    },
}

return AbilityConfig

