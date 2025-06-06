local AbilityConfig = {}

AbilityConfig.BlackLeg = {
    PartyTableKick = {
        Hits = 10,
        Duration = 2.4,
        DamagePerHit = 5,
        StunDuration = 0.75,
        Startup = 1,
        HyperArmor = false,
        GuardBreak = false,
        Endlag = 1,
        HitboxDuration = 0.1,
        Cooldown = 5,
        KnockbackDirection = "AwayFromAttacker",
    },
}

AbilityConfig.BasicCombat = {
    PowerPunch = {
        Damage = 15,
        StunDuration = 2.0,
        Startup = 1.0,
        HyperArmor = true,
        GuardBreak = true,
        Endlag = 1,
        HitboxDuration = 0.5,
        HitboxDistance = 5,
        Cooldown = 4,
        KnockbackDirection = "AttackerFacingDirection",
    },
}

return AbilityConfig

