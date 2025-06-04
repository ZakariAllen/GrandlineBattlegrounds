--ReplicatedStorage.Modules.Config.CombatConfig

local CombatConfig = {}

CombatConfig.M1 = {
	ComboHits = 5,
	DelayBetweenHits = 0.3,
	ComboResetTime = 1.8,
	ComboCooldown = 2.2,

	HitDelay = 0.12, -- Delay before damage applies after animation starts
	M1StunDuration = 0.65,
	M1_5StunDuration = 2.0,

	KnockbackDistance = 25,
	KnockbackDuration = 0.4,
	KnockbackLift = 3,

	HitboxSize = Vector3.new(4, 5, 4),
	HitboxOffset = CFrame.new(0, 0, -2.4),
	HitboxDuration = 0.1,

	HitSoundDelay = 0.05,
	MissSoundDelay = 0.05,
	DefaultM1Damage = 5,
}

CombatConfig.Blocking = {
	BlockHP = 12,
	PerfectBlockWindow = 0.3,
	BlockBreakStunDuration = 4,
	PerfectBlockStunDuration = 6,
	BlockCooldown = 2,
}

return CombatConfig
