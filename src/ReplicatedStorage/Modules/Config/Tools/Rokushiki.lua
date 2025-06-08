local Rokushiki = {
    Teleport = {
        Cooldown = 5,
        MaxDistance = 40,
        Sound = {
            Use = { Id = "rbxassetid://105257107308215", Pitch = 1, Volume = 1 },
        },
    },
    Shigan = {
        Damage = 65,
        StunDuration = 0.5,
        Startup = 0.5,
        HyperArmor = false,
        GuardBreak = false,
        PerfectBlockable = true,
        Endlag = 0.5,
        HitboxDuration = 0.1,
        Cooldown = 5,
        Hitbox = {
            Size = Vector3.new(4, 5, 4),
            Offset = CFrame.new(0, 0, -2.4),
            Duration = 0.1,
            Shape = "Block",
        },
        Sound = {
            Hit = { Id = "rbxassetid://9117969717", Pitch = 1, Volume = 1 },
        },
    },
    TempestKick = {
        Damage = 100,
        StunDuration = 0.75,
        Startup = 0.75,
        HyperArmor = false,
        GuardBreak = false,
        PerfectBlockable = true,
        Endlag = 0.5,
        HitboxDuration = 0.4,
        HitboxDistance = 25,
        Cooldown = 7,
        KnockbackDirection = "AttackerFacingDirection",
        Hitbox = {
            Size = Vector3.new(8, 6, 6),
            Offset = CFrame.new(0, 0, -3.2),
            Duration = 0.4,
            Shape = "Block",
        },
    },
    Tekkai = {
        BlockHP = 750,
        StaminaDrain = 10,
    },
}

return Rokushiki
