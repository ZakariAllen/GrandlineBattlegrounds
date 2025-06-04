--ReplicatedStorage.Modules.Config.ToolConfig

local ToolConfig = {}

ToolConfig.ValidCombatTools = {
	["Basic Combat"] = true,
	["Black Leg"] = true,
	-- Add more tools here
}

ToolConfig.ToolStats = {
	BasicCombat = { M1Damage = 3 },
	BlackLeg = { M1Damage = 4 },
	-- Add more tools here
}

return ToolConfig
