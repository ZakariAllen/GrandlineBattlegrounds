local DashConfig = {}

DashConfig.Cooldown = 2

DashConfig.SoundId = "rbxassetid://72014632956520"  -- Replace with your dash SFX asset id

DashConfig.Settings = {
	Forward = {
		Distance = 20,
		Duration = 0.25,
	},
	Backward = {
		Distance = 20,
		Duration = 0.25,
	},
	Left = {
		Distance = 20,
		Duration = 0.25,
	},
	Right = {
		Distance = 20,
		Duration = 0.25,
	},
	ForwardLeft = {
		Distance = 20,
		Duration = 0.25,
	},
	ForwardRight = {
		Distance = 20,
		Duration = 0.25,
	},
	BackwardLeft = {
		Distance = 20,
		Duration = 0.25,
	},
	BackwardRight = {
		Distance = 25,
		Duration = 0.25,
	},
}

return DashConfig
