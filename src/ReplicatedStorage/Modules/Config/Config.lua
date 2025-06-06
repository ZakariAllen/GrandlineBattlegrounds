--ReplicatedStorage.Modules.Config.Config

local Config = {}

-- Import additional sub-configurations
local HitEffectConfig = require(script.Parent.HitEffectConfig)

Config.GameSettings = {
	DefaultSprintSpeed = 20,
	DefaultWalkSpeed = 10,
	DefaultJumpPower = 50,

        JumpCooldown = 1.25,
        DebugEnabled = true, -- Global debug toggle
        AttackerLockoutDuration = 0, -- Remove extra delay after hits
}

Config.HitEffect = HitEffectConfig

return Config
