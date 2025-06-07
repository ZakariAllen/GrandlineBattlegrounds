local BasicCombat = {
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
        Hitbox = {
            Size = Vector3.new(6, 6, 6),
            Offset = CFrame.new(0, 0, -3.5),
            Duration = 0.2,
            Shape = "Block",
        },
        Sound = {
            Hit = "rbxassetid://9117969717",
        },
    },
}

return BasicCombat
