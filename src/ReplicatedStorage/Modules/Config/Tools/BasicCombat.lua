local BasicCombat = {
    PowerPunch = {
        Damage = 120,
        StunDuration = 1.5,
        Startup = 1.0,
        HyperArmor = true,
        GuardBreak = true,
        PerfectBlockable = true,
        Endlag = 0.7,
        HitboxDuration = 0.1,
        HitboxDistance = 6,
        Cooldown = 7,
        KnockbackDirection = "AttackerFacingDirection",
        Hitbox = {
            Size = Vector3.new(6, 6, 7),
            Offset = CFrame.new(0, 0, -3.2),
            Shape = "Block",
        },
    },
}

return BasicCombat
