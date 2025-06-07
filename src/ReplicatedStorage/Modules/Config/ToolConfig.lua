--ReplicatedStorage.Modules.Config.ToolConfig

local ToolConfig = {}

ToolConfig.ValidCombatTools = {
        ["BasicCombat"] = true,
        ["BlackLeg"] = true,
        ["Rokushiki"] = true,
        -- Add more tools here
}

ToolConfig.ToolStats = {
        BasicCombat = { M1Damage = 35, AllowsBlocking = true },
        BlackLeg = { M1Damage = 35, AllowsBlocking = true },
        Rokushiki = { M1Damage = 35, AllowsBlocking = true },
        -- Add more tools here
}

return ToolConfig
