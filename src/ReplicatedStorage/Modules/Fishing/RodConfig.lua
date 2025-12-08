return {
    Wayfinder = {
        displayName = "Wayfinder Rod",
        description = "Light, forgiving rod tuned for scouting the new isometric islands.",
        castRange = 95, -- Max horizontal studs the bobber can travel at full power
        biteMultiplier = 1.1, -- Scales fish rarity weights (higher = better odds for rare fish)
        biteTime = NumberRange.new(9, 13), -- Baseline seconds before a fish can bite (pre modifiers)
        lureSpeed = 12, -- Bite-time divisor; higher values reduce wait time until a bite
        bobberAsset = "Default", -- Reserved for future bobber assets
        control = 0.18, -- Percentage change to the base capture width (0.1 = +10% wider)
        staminaDrain = 0.55, -- How quickly capture progress drains when the fish leaves the zone
    },
}
