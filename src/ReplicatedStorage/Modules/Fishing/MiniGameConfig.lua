return {
    Capture = {
        -- Total capture progress required (higher = longer fight, tougher fish).
        Goal = 10,
        -- Default capture zone width (portion of the track, 0-1) before rod bonuses.
        BaseWidth = 0.14,
        -- How fast the capture meter drains whenever the fish marker leaves the zone.
        Decay = 1,
        -- How fast the meter fills while the marker is inside the zone.
        Rise = 1.1,
    },

    -- Movement behavior broken into tunable minor (twitch) and major (sweep) controls.
    Movement = {
        Minor = {
            -- Portion of the track covered by each twitch (scaled by difficulty).
            Distance = NumberRange.new(0.05, 0.065),
            -- Seconds spent completing the twitch.
            Duration = NumberRange.new(0.4, 0.55),
            -- Number of twitches per second before difficulty scaling.
            Frequency = NumberRange.new(0.7, 0.9),
            -- Easing for the minor twitch tween.
            EaseStyle = "Sine",
            EaseDirection = "InOut",
        },
        Major = {
            -- Portion of the track covered by the larger sweeps (scaled by difficulty).
            Distance = NumberRange.new(0.2, 0.28),
            -- Seconds spent on a sweep.
            Duration = NumberRange.new(0.9, 1.1),
            -- Sweeps per second before difficulty scaling.
            Frequency = NumberRange.new(0.08, 0.12),
            -- Easing for the major sweep tween.
            EaseStyle = "Sine",
            EaseDirection = "InOut",
        },
    },

    -- Default time range (seconds) before a fish can bite if rods don't override it.
    BiteTimeRange = NumberRange.new(10, 16),

    -- Maximum horizontal speed the fish marker can reach.
    MarkerMaxSpeed = 22,

    -- Base acceleration applied when the player holds/releases the control input (higher = reaches top speed faster).
    InputPower = 2,

    -- Additional inertia applied when the player tries to reverse direction (higher = harder to flip).
    DirectionInertia = 1.15,

    -- Maximum horizontal speed the capture bar can reach in either direction.
    ControlMaxSpeed = 15,

    -- Dampening factor that gives the capture zone its weight/inertia.
    CaptureDamping = 4,

    -- How much velocity the capture bar retains when bouncing off the track edges (0 = stick, 1 = perfect reflection).
    CaptureBounceFactor = 0.78,

    -- Extra seconds added to the fight duration before automatically failing.
    FailGraceTime = 0,

    -- Minimum time (seconds) before inputs are accepted.
    LockDuration = 1.4,

    -- Minimum progress (0-1) required before inputs unlock if reached earlier.
    UnlockProgressThreshold = 0.22,

    -- Portion (0-1) of the capture meter to pre-fill when the minigame starts.
    InitialFillPercent = 0.2,
}
