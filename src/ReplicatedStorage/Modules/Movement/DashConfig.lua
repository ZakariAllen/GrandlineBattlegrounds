local DashConfig = {}

DashConfig.Cooldown = 2

DashConfig.SoundId = "rbxassetid://72014632956520"  -- Replace with your dash SFX asset id

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
    Forward = { Distance = 20, Duration = 0.12 },
    Backward = { Distance = 20, Duration = 0.12 },
    Left = { Distance = 20, Duration = 0.12 },
    Right = { Distance = 20, Duration = 0.12 },
    ForwardLeft = { Distance = 20, Duration = 0.12 },
    ForwardRight = { Distance = 20, Duration = 0.12 },
    BackwardLeft = { Distance = 20, Duration = 0.12 },
    BackwardRight = { Distance = 20, Duration = 0.12 },
}

return DashConfig
