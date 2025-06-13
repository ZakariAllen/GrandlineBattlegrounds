--ReplicatedStorage.Modules.Config.Config

local Config = {}

-- Import additional sub-configurations
local HitEffectConfig = require(script.Parent.HitEffectConfig)
local VFXConfig = require(script.Parent.VFXConfig)
local UltConfig = require(script.Parent.UltConfig)

Config.GameSettings = {
	DefaultSprintSpeed = 20,
	DefaultWalkSpeed = 10,
	DefaultJumpPower = 50,

        JumpCooldown = 1.25,
        DebugEnabled = true, -- Global debug toggle
        AttackerLockoutDuration = 0, -- Remove extra delay after hits
        DayNightCycleMinutes = 15, -- Length of a full day/night cycle
}

Config.HitEffect = HitEffectConfig
Config.VFX = VFXConfig
Config.Ult = UltConfig

return Config
