-- ReplicatedStorage.Modules.Animations.Combat.lua
local Animation = {}

Animation.M1 = {
	BasicCombat = {
		Combo = {
			[1] = "rbxassetid://114200559376775",
			[2] = "rbxassetid://96320001137526",
			[3] = "rbxassetid://114200559376775",
			[4] = "rbxassetid://96320001137526",
			[5] = "rbxassetid://70382508234278",
		},
		Knockback = "rbxassetid://130846337993501"
	},

        BlackLeg = {
                Combo = {
                        [1] = "rbxassetid://89499329718727",
                        [2] = "rbxassetid://126344683553001",
                        [3] = "rbxassetid://89499329718727",
                        [4] = "rbxassetid://126344683553001",
                        [5] = "rbxassetid://84882475157331",
                },
                Knockback = "rbxassetid://130846337993501"
        },

        Rokushiki = {
                Combo = {
                        [1] = "rbxassetid://114200559376775",
                        [2] = "rbxassetid://96320001137526",
                        [3] = "rbxassetid://114200559376775",
                        [4] = "rbxassetid://96320001137526",
                        [5] = "rbxassetid://70382508234278",
                },
                Knockback = "rbxassetid://130846337993501"
        }
}

Animation.Stun = {
	Default = "rbxassetid://129747924034850",
	PerfectBlock = "rbxassetid://121569415955025",
	BlockBreak = "rbxassetid://121569415955025"
}

Animation.Blocking = {
        BlockHold = "rbxassetid://120302594310426",

}

Animation.SpecialMoves = {
    PartyTableKick = "rbxassetid://99204047574669",
    PowerKick = "rbxassetid://132858770370744",
    PowerPunch = "rbxassetid://129154072458138"
}

return Animation
