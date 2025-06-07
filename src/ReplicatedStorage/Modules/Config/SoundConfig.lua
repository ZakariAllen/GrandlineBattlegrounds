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

                Rokushiki = {
                        Hit = "rbxassetid://9117969717",
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

        Haki = {
                Activate = "rbxassetid://122809552011508",
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
                -- Each entry includes an asset ID and optional pitch (playback speed)
                MusicPool = {
                        { Id = "rbxassetid://78834849660646", Pitch = 0.8 }, -- Track 1 208-B
                        { Id = "rbxassetid://78834849660646", Pitch = 0.9 }, -- Track 2 208-B
                        { Id = "rbxassetid://78834849660646", Pitch = 1 }, -- Track 3 208-B
                        { Id = "rbxassetid://78834849660646", Pitch = 1.1 }, -- Track 4 208-B
                        { Id = "rbxassetid://90253170109596", Pitch = 1.1 }, -- Track 5 Overtaken
						{ Id = "rbxassetid://90253170109596", Pitch = 0.9 }, -- Track 6 Overtaken
						{ Id = "rbxassetid://90253170109596", Pitch = 1 } -- Track 7 Overtaken
                },

                -- 🎼 Main menu music (single track)
                MainMenuMusic = { Id = "rbxassetid://73680974075134", Pitch = 0.9 }
        }
}

return SoundConfig
