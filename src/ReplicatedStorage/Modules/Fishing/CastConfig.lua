return {
    Meter = {
        CycleDuration = 1.05, -- seconds for the slider to travel end-to-end
        MinimumPower = 0.2, -- minimum percentage of the rod range to allow
        GradeDisplayDuration = 1, -- seconds to keep the grade popup visible
    },

    CastingMovementSlowFactor = 0.35, -- multiply WalkSpeed while winding up a cast

    -- Maximum bonus that can be awarded via casting accuracy (10% luck).
    MaxLuckBonus = 0.1,

    Grades = {
        {
            label = "PERFECT!!",
            maxDelta = 0.015,
            luckBonus = 0.10,
            color = Color3.fromRGB(120, 255, 180),
        },
        {
            label = "Amazing!",
            maxDelta = 0.04,
            luckBonus = 0.08,
            color = Color3.fromRGB(86, 230, 164),
        },
        {
            label = "Great!",
            maxDelta = 0.08,
            luckBonus = 0.06,
            color = Color3.fromRGB(70, 200, 150),
        },
        {
            label = "Good!",
            maxDelta = 0.15,
            luckBonus = 0.04,
            color = Color3.fromRGB(255, 210, 120),
        },
        {
            label = "Fine.",
            maxDelta = 0.25,
            luckBonus = 0.02,
            color = Color3.fromRGB(255, 170, 90),
        },
        {
            label = "Meh..",
            maxDelta = math.huge,
            luckBonus = 0,
            color = Color3.fromRGB(255, 130, 90),
        },
    },
}
