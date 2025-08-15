local BlackLeg = {
    PartyTableKick = {
        Hits = 10,
        Duration = 2.25,
        DamagePerHit = 15,
        StunDuration = 0.75,
        Startup = 0.5,
        HyperArmor = false,
        Cancelable = false,
        GuardBreak = false,
        Endlag = 1.3,
        HitboxDuration = 0.1,
        Cooldown = 12,
        Knockback = {
            Force = 300,
            Lift = 150,
            Duration = 1,
        },
        KnockbackDirection = "AwayFromAttacker",
        Hitbox = {
            Size = Vector3.new(7, 9, 9),
            Offset = CFrame.new(0, 0, 0),
            Duration = 0.1,
            Shape = "Cylinder",
        },
        Sound = {
            Hit = { Id = "rbxassetid://122809552011508", Pitch = 1, Volume = 1 },
            Miss = { Id = "rbxassetid://135883654541622", Pitch = 1, Volume = 1 },
            Loop = { Id = "rbxassetid://118537831520752", Pitch = 1, Volume = 1 },
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
        Knockback = {
            Force = 0,
            Lift = 0,
            Duration = 0,
        },
        Hitbox = {
            Size = Vector3.new(6, 6, 6),
            Offset = CFrame.new(0, 0, -3.5),
            Duration = 0.2,
            Shape = "Block",
        },
        Sound = {
            Hit = { Id = "rbxassetid://118765157785806", Pitch = 1, Volume = 1 },
        },
    },
    Concasse = {
        Damage = 45,
        StunDuration = 0.25,
        Startup = 0.2,
        HyperArmor = false,
        GuardBreak = false,
        PerfectBlockable = true,
        Endlag = 0.1,
        Range = 65,
        -- Constant travel speed for consistent feel across distances
        TravelSpeed = 65,
        -- Travel time scales with distance
        MinTravelTime = 1,
        MaxTravelTime = 2,
        HitboxDuration = 0.1,
        Cooldown = 12,
        Knockback = {
            Force = 0,
            Lift = 0,
            Duration = 0,
        },
        Hitbox = {
            Size = Vector3.new(8, 8, 8),
            Offset = CFrame.new(0, 0, 0.0),
            Duration = 0.1,
            Shape = "Cylinder",
        },
        Sound = {},
    },
    AntiMannerKickCourse = {
        Damage = 350,
        StunDuration = 3,
        Startup = 1,
        HyperArmor = true,
        GuardBreak = true,
        PerfectBlockable = false,
        Endlag = 0.5,
        Cooldown = 120,
        StaminaCost = 100,
        Knockback = {
            Force = 50,
            Lift = 140,
            Duration = 0.6,
        },
        Hitbox = {
            Size = Vector3.new(6, 6, 6),
            Offset = CFrame.new(0, 0, -3.5),
            Duration = 0.1,
            Shape = "Block",
        },
        Sound = {
            Hit = { Id = "rbxassetid://118765157785806", Pitch = 1, Volume = 1 },
        },
    },
}

-- Derive standardized metadata used by AI and combat systems
for moveName, move in pairs(BlackLeg) do
    move.Metadata = {
        Role = move.GuardBreak and "GuardBreak" or "ComboEnder",
        Range = { Min = 0, Max = move.HitboxDistance or move.Range or 0 },
        StartupMs = (move.Startup or 0) * 1000,
        ActiveMs = (move.HitboxDuration or 0) * 1000,
        RecoveryMs = (move.Endlag or 0) * 1000,
        BlockDamage = move.Damage or move.DamagePerHit or 0,
        StaminaCost = move.StaminaCost or 0,
        DashCancelOK = move.DashCancelOK or false,
        OnBlock = { Pushback = 0, AdvantageMs = -((move.Endlag or 0) * 1000) },
        OnHit = { AdvantageMs = (move.StunDuration or 0) * 1000, Knockback = move.Knockback or nil, KnockbackDirection = move.KnockbackDirection },
        RequiresFacing = true,
    }
end

return BlackLeg
