--ReplicatedStorage.Modules.Config.SoundConfig

local SoundConfig = {
	Combat = {
		-- 🥊 Tool-specific combat sounds
		BasicCombat = {
			Hit = "rbxassetid://9117969717",
			Miss = "rbxassetid://135883654541622",
		},

		BlackLeg = {
			Hit = "rbxassetid://122809552011508",
			Miss = "rbxassetid://135883654541622",
		},
	},

	Blocking = {
		-- 🛡️ Shared blocking sounds
		Block = "rbxassetid://103609526141113",
		PerfectBlock = "rbxassetid://4547193309",
		BlockBreak = "rbxassetid://72374553050886",
	},

	Movement = {
		-- 🌀 Movement sounds
		Dash = "rbxassetid://84275983410258",
		Walk = "rbxassetid://YOUR_WALK_SOUND_ID",
		Sprint = "rbxassetid://YOUR_SPRINT_SOUND_ID",
	},

	UI = {
		-- 🖱️ UI interaction sounds
		Hover = "rbxassetid://92876108656319",       -- example hover sound
		Click = "rbxassetid://6042053626",       -- example click sound
		Select = "rbxassetid://12222030",
		Back = "rbxassetid://132931539",
	},

	Music = {
		-- 🎵 Background music pool (for gameplay rotation)
		MusicPool = {
			"rbxassetid://78834849660646", -- Track 1
			"rbxassetid://78834849660646", -- Track 2
			"rbxassetid://78834849660646", -- Track 3
			"rbxassetid://78834849660646", -- Track 4
			"rbxassetid://78834849660646", -- Track 5
		},

		-- 🎼 Main menu music (single track)
		MainMenuMusic = "rbxassetid://73680974075134"
	}
}

return SoundConfig
