local DashConfig = {}

DashConfig.Cooldown = 2

DashConfig.SoundId = "rbxassetid://72014632956520"  -- Replace with your dash SFX asset id

-- Duration that characters stay invisible when performing the Rokushiki dash
DashConfig.RokuInvisDuration = 0.3

DashConfig.Settings = {
	Forward = {
		Distance = 15,
		Duration = 0.18,
	},
	Backward = {
		Distance = 15,
		Duration = 0.18,
	},
	Left = {
		Distance = 15,
		Duration = 0.18,
	},
	Right = {
		Distance = 15,
		Duration = 0.18,
	},
	ForwardLeft = {
		Distance = 15,
		Duration = 0.18,
	},
	ForwardRight = {
		Distance = 15,
		Duration = 0.18,
	},
	BackwardLeft = {
		Distance = 15,
		Duration = 0.18,
	},
	BackwardRight = {
		Distance = 15,
		Duration = 0.18,
	},
}

-- Separate dash settings for the Rokushiki style. These can be tuned
-- independently from the regular dash distances and durations.
DashConfig.RokuSettings = {
    Forward = { Distance = 18, Duration = 0.22 },
    Backward = { Distance = 18, Duration = 0.22 },
    Left = { Distance = 18, Duration = 0.22 },
    Right = { Distance = 18, Duration = 0.22 },
    ForwardLeft = { Distance = 18, Duration = 0.22 },
    ForwardRight = { Distance = 18, Duration = 0.22 },
    BackwardLeft = { Distance = 18, Duration = 0.22 },
    BackwardRight = { Distance = 18, Duration = 0.22 },
}

return DashConfig
