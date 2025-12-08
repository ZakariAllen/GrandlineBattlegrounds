local Rarities = {
    Common = {
        chance = 55,
        goalScale = 0.9,
        Multipliers = {
            MinorFreq = 0.9,
            MinorDist = 0.9,
            MajorFreq = 0.9,
            MajorDist = 0.9,
        },
    },
    Uncommon = {
        chance = 28,
        goalScale = 1.0,
        Multipliers = {
            MinorFreq = 1,
            MinorDist = 1,
            MajorFreq = 1,
            MajorDist = 1,
        },
    },
    Rare = {
        chance = 12,
        goalScale = 1.15,
        Multipliers = {
            MinorFreq = 1.1,
            MinorDist = 1.15,
            MajorFreq = 1.05,
            MajorDist = 1.1,
        },
    },
    Epic = {
        chance = 5,
        goalScale = 1.3,
        Multipliers = {
            MinorFreq = 1.2,
            MinorDist = 1.25,
            MajorFreq = 1.15,
            MajorDist = 1.2,
        },
    },
}

return {
    Rarities = Rarities,
}
