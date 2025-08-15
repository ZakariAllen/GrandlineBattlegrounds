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
        Sound = {
            Hit = { Id = "rbxassetid://9117969717", Pitch = 1, Volume = 1 },
        },
    },
}

-- Derive standardized metadata used by AI and combat systems
for moveName, move in pairs(BasicCombat) do
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

return BasicCombat
