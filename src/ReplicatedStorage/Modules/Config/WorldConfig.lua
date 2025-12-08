local WorldConfig = {
    Tiles = {
        -- Number of tiles to keep loaded outward from the player on each axis (square coverage)
        ActiveRadius = 28,
        -- Legacy grid size kept for UI display; generation is now infinite and radius-driven
        GridSize = Vector2.new(32, 32),
        TileSize = 16,
        TileThickness = 8,
        BaseHeight = 0,
        ElevationStep = 4,
        HeightSteps = 4,
        WaterDepth = -6,
        -- Palette and materials are tuned to resemble the C++ prototype's clean banding.
        GrassColors = {
            Color3.fromRGB(134, 212, 133),
            Color3.fromRGB(154, 228, 144),
            Color3.fromRGB(118, 191, 112),
        },
        SandColors = {
            Color3.fromRGB(216, 187, 140),
            Color3.fromRGB(196, 166, 120),
        },
        WaterColor = Color3.fromRGB(79, 143, 196),
        WaterFoamColor = Color3.fromRGB(207, 234, 255),
        ForestColor = Color3.fromRGB(93, 167, 112),
        RockColor = Color3.fromRGB(158, 166, 180),
        DirtColor = Color3.fromRGB(166, 123, 91),
    },
    Decorations = {
        TreeChance = 0.12,
        RockChance = 0.1,
        PebbleChance = 0.18,
        TallGrassChance = 0.18,
        DriftwoodChance = 0.05,
    },
    Fishing = {
        Hotspot = {
            Chance = 0.12,
            HaloColor = Color3.fromRGB(255, 201, 107),
            BobbingAmplitude = 0.4,
            BobbingFrequency = 1.25,
        },
    },
    Noise = {
        Seed = 1337,
        BaseFrequency = 0.045,
        Persistence = 0.55,
        Octaves = 4,
        WaterThreshold = 0.43,
        BeachBand = 0.05,
        ForestThreshold = 0.7,
        RockThreshold = 0.86,
    },
    Camera = {
        Distance = 42,
        Height = 32,
        PitchDeg = 55,
        YawDeg = 45,
        FocusHeight = 3,
    },
    Spawn = Vector3.new(0, 0, 0),
}

return WorldConfig
