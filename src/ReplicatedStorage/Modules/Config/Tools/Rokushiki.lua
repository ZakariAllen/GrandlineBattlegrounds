local Rokushiki = {
    Teleport = {
        Startup = 0.2,
        Endlag = 0.05,
        Cooldown = 15,
        StaminaCost = 35,
        MaxDistance = 40,
        Sound = {
            Use = { Id = "rbxassetid://105257107308215", Pitch = 1, Volume = 1 },
        },
    },
    Shigan = {
        Damage = 65,
        StunDuration = 1.25,
        Startup = 0.5,
        HyperArmor = false,
        GuardBreak = true,
        PerfectBlockable = true,
        Endlag = 0.25,
        HitboxDuration = 0.1,
        Cooldown = 12,
        Hitbox = {
            Size = Vector3.new(5, 6, 5),
            Offset = CFrame.new(0, 0, -2.4),
            Duration = 0.1,
            Shape = "Block",
        },
        Sound = {
            Hit = { Id = "rbxassetid://9117969717", Pitch = 1, Volume = 1 },
        },
    },
    TempestKick = {
        Damage = 75,
        StunDuration = 1,
        Startup = 1,
        HyperArmor = false,
        GuardBreak = false,
        PerfectBlockable = true,
        Endlag = 0.5,
        HitboxDuration = 0.3,
        HitboxDistance = 25,
        Cooldown = 12,
        KnockbackDirection = "AttackerFacingDirection",
        Hitbox = {
            Size = Vector3.new(8, 6, 6),
            Offset = CFrame.new(0, 0, -3.2),
            Duration = 0.3,
            Shape = "Block",
        },
    },
    Tekkai = {
        BlockHP = 750,
        StaminaDrain = 10,
        Startup = 0.1,
        Endlag = 0.1,
        HyperArmor = false,
        Cooldown = 15,
    },
}

return Rokushiki
