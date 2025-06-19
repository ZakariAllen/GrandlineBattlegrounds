--ReplicatedStorage.Modules.Config.CombatConfig

local CombatConfig = {}

CombatConfig.M1 = {
	ComboHits = 5,
	DelayBetweenHits = 0.3,
	ComboResetTime = 2,
	ComboCooldown = 2,

        HitDelay = 0.12, -- Delay before damage applies after animation starts
        -- Time window where two attacks may clash. When enabled, the player who
        -- pressed attack first wins the exchange and the other's hit is ignored.
        ClashWindow = 0.15,
        M1StunDuration = 0.5,
        M1_5StunDuration = 1.5,
        HitSoundDelay = 0.05,
        MissSoundDelay = 0.05,
        DefaultM1Damage = 1,
        -- Maximum distance the server will allow for a confirmed hit
        ServerHitRange = 12,

        Hitbox = {
                Offset = CFrame.new(0, 0, -2.4),
                Size = Vector3.new(4, 5, 4),
                Duration = 0.1,
                Shape = "Block",
        },
}

CombatConfig.Blocking = {
    -- Time between pressing block and the block becoming active
    StartupTime = 0.05,
        PerfectBlockWindow = 0.08,
        BlockBreakStunDuration = 2.5,
        PerfectBlockStunDuration = 2.5,
        BlockCooldown = 2,
}

return CombatConfig
