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

-- Additional metadata for timing and spacing, used by AI systems
ToolConfig.ToolMeta = {
        BasicCombat = {
                IdealDistanceBand = { TooClose = 3, Ideal = 8, Long = 15 },
                M1 = {
                        StartupMs = 300,
                        ChainWindowMs = {300,300,300,300,400},
                        FifthHitKnockback = { Force = 50, Lift = 0, Duration = 0.5 },
                },
        },
        BlackLeg = {
                IdealDistanceBand = { TooClose = 3, Ideal = 8, Long = 15 },
                M1 = {
                        StartupMs = 300,
                        ChainWindowMs = {300,300,300,300,400},
                        FifthHitKnockback = { Force = 50, Lift = 0, Duration = 0.5 },
                },
        },
        Rokushiki = {
                IdealDistanceBand = { TooClose = 3, Ideal = 8, Long = 15 },
                M1 = {
                        StartupMs = 300,
                        ChainWindowMs = {300,300,300,300,400},
                        FifthHitKnockback = { Force = 50, Lift = 0, Duration = 0.5 },
                },
        },
}

return ToolConfig
