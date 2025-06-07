local BlackLeg = {
    PartyTableKick = {
        Hits = 10,
        Duration = 2.4,
        DamagePerHit = 15,
        StunDuration = 0.75,
        Startup = 1.3,
        HyperArmor = true,
        GuardBreak = false,
        Endlag = 1.3,
        HitboxDuration = 0.1,
        Cooldown = 12,
        KnockbackDirection = "AwayFromAttacker",
        Hitbox = {
            Size = Vector3.new(7, 8, 8),
            Offset = CFrame.new(0, 0, 0),
            Duration = 0.1,
            Shape = "Cylinder",
        },
        Sound = {
            Hit = "rbxassetid://122809552011508",
            Miss = "rbxassetid://135883654541622",
            Loop = "rbxassetid://118537831520752",
        },
    },
    PowerKick = {
        Damage = 50,
        StunDuration = 1.5,
        Startup = 0.4,
        HyperArmor = false,
        GuardBreak = true,
        PerfectBlockable = true,
        Endlag = 0.5,
        HitboxDuration = 0.2,
        Cooldown = 12,
        Hitbox = {
            Size = Vector3.new(6, 6, 6),
            Offset = CFrame.new(0, 0, -3.5),
            Duration = 0.2,
            Shape = "Block",
        },
        Sound = {
            Hit = "rbxassetid://118765157785806",
        },
    },
}

return BlackLeg
