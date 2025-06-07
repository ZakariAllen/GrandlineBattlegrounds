local Rokushiki = {
    Teleport = {
        Cooldown = 5,
        MaxDistance = 25,
        Sound = {
            Use = "rbxassetid://105257107308215",
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
            Hit = "rbxassetid://9117969717",
        },
    },
    Tekkai = {
        BlockHP = 750,
        StaminaDrain = 10,
    },
}

return Rokushiki
