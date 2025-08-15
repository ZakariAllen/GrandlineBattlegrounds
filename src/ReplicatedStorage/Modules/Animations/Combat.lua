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
	},

        BlackLeg = {
                Combo = {
                        [1] = "rbxassetid://89499329718727",
                        [2] = "rbxassetid://126344683553001",
                        [3] = "rbxassetid://89499329718727",
                        [4] = "rbxassetid://126344683553001",
                        [5] = "rbxassetid://84882475157331",
                },
        },

        Rokushiki = {
                Combo = {
                        [1] = "rbxassetid://114200559376775",
                        [2] = "rbxassetid://96320001137526",
                        [3] = "rbxassetid://114200559376775",
                        [4] = "rbxassetid://96320001137526",
                        [5] = "rbxassetid://70382508234278",
                },
        }
}

Animation.Stun = {
	Default = "rbxassetid://129747924034850",
	PerfectBlock = "rbxassetid://121569415955025",
	BlockBreak = "rbxassetid://121569415955025"
}

Animation.Blocking = {
        BlockHold = "rbxassetid://120302594310426",
        TekkaiHold = "rbxassetid://109637374943375",

}

Animation.SpecialMoves = {
    PartyTableKick = "rbxassetid://99204047574669",
    PowerKick = "rbxassetid://132858770370744",
    PowerPunch = "rbxassetid://129154072458138",
    Shigan = "rbxassetid://114553452416795"
}

-- Animation state tagging for AI perception
local animationTags = {}
local function tag(animId, ...)
    animationTags[animId] = { ... }
end

for _, style in pairs(Animation.M1) do
    if style.Combo then
        for _, id in pairs(style.Combo) do
            tag(id, "Windup", "Active", "Recovery")
        end
    end
end

Animation.TagMap = animationTags

--[=[
    Returns a set-like table of tags based on currently playing animations on
    the given character. Tags mirror what human players can observe visually
    such as "Windup" or "Blocking".

    @param character Model
    @return table<string, boolean>
]=]
function Animation.GetCurrentTags(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return {} end
    local tags = {}
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        local anim = track.Animation
        if anim then
            local list = animationTags[anim.AnimationId]
            if list then
                for _, t in ipairs(list) do
                    tags[t] = true
                end
            end
        end
    end
    return tags
end

return Animation
