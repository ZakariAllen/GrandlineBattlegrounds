--ReplicatedStorage.Modules.Config.SoundConfig

local SoundConfig = {
        Combat = {
                -- 🥊 Generic combat sounds used by most tools
                Hit = { Id = "rbxassetid://9117969717", Pitch = 1, Volume = 1 },
                Miss = { Id = "rbxassetid://135883654541622", Pitch = 1, Volume = 1 },

                -- 🥾 Black Leg specific sounds
               BlackLeg = {
                       Hit = { Id = "rbxassetid://122809552011508", Pitch = 1, Volume = 1 },
                       StrongKickHit = { Id = "rbxassetid://118765157785806", Pitch = 1, Volume = 1 },
                       PartyTableKickLoop = { Id = "rbxassetid://118537831520752", Pitch = 1, Volume = 1 },
               },

               Rokushiki = {
                       TeleportUse = { Id = "rbxassetid://105257107308215", Pitch = 1, Volume = 1 },
               },
       },

	Blocking = {
		-- 🛡️ Shared blocking sounds
                Block = { Id = "rbxassetid://103609526141113", Pitch = 1, Volume = 1 },
                PerfectBlock = { Id = "rbxassetid://4547193309", Pitch = 1, Volume = 1 },
                BlockBreak = { Id = "rbxassetid://72374553050886", Pitch = 1, Volume = 1 },
        },

        Movement = {
                -- 🌀 Movement sounds
                Dash = { Id = "rbxassetid://72014632956520", Pitch = 1, Volume = 1 },
                Walk = { Id = "rbxassetid://YOUR_WALK_SOUND_ID", Pitch = 1, Volume = 1 },
                Sprint = { Id = "rbxassetid://YOUR_SPRINT_SOUND_ID", Pitch = 1, Volume = 1 },
        },

        Haki = {
                Activate = { Id = "rbxassetid://979751563", Pitch = 1, Volume = 0.35 },
        },

	UI = {
		-- 🖱️ UI interaction sounds
                Hover = { Id = "rbxassetid://92876108656319", Pitch = 1, Volume = 1 },       -- example hover sound
                Click = { Id = "rbxassetid://6042053626", Pitch = 1, Volume = 1 },       -- example click sound
                Select = { Id = "rbxassetid://12222030", Pitch = 1, Volume = 1 },
                Back = { Id = "rbxassetid://132931539", Pitch = 1, Volume = 1 },
        },

        Music = {
                -- 🎵 Background music pool (for gameplay rotation)
                -- Each entry includes an asset ID and optional pitch (playback speed)
                MusicPool = {
                        { Id = "rbxassetid://78834849660646", Pitch = 0.8, Volume = 0.5 }, -- Track 1 208-B
                        { Id = "rbxassetid://78834849660646", Pitch = 0.9, Volume = 0.5 }, -- Track 2 208-B
                        { Id = "rbxassetid://78834849660646", Pitch = 1, Volume = 0.5 }, -- Track 3 208-B
                        { Id = "rbxassetid://78834849660646", Pitch = 1.1, Volume = 0.5 }, -- Track 4 208-B
                        { Id = "rbxassetid://78834849660646", Pitch = 1.2, Volume = 0.5 }, -- Track 4 208-B
                },

                -- 🎼 Main menu music (single track)
                MainMenuMusic = { Id = "rbxassetid://73680974075134", Pitch = 0.9, Volume = 1 }
        }
}

return SoundConfig
