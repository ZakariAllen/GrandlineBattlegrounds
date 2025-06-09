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

        KnockbackDistance = 25,
        KnockbackDuration = 0.4,
        KnockbackLift = 3,
        KnockbackDirection = "AttackerFacingDirection",

	HitSoundDelay = 0.05,
	MissSoundDelay = 0.05,
	DefaultM1Damage = 1,
}

CombatConfig.Blocking = {
    -- Time between pressing block and the block becoming active
    StartupTime = 0.1,
        PerfectBlockWindow = 0.15,
        BlockBreakStunDuration = 4,
        PerfectBlockStunDuration = 4,
        BlockCooldown = 2,
}

return CombatConfig
