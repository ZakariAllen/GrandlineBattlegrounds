local WorldConfig = {
    Tiles = {
        -- Number of tiles to keep loaded outward from the player on each axis (square coverage)
        ActiveRadius = 32,
        -- Legacy grid size kept for UI display; generation is now infinite and radius-driven
        GridSize = Vector2.new(32, 32),
        TileSize = 16,
        BaseHeight = 0,
        ElevationStep = 1,
        TileTypeWeights = {
            { Type = "Grass", Weight = 0.7 },
            { Type = "Sand", Weight = 0.2 },
            { Type = "Water", Weight = 0.1 },
        },
        GrassColors = {
            Color3.fromRGB(134, 212, 133),
            Color3.fromRGB(154, 228, 144),
            Color3.fromRGB(118, 191, 112),
        },
        WaterColor = Color3.fromRGB(95, 166, 214),
        RockColor = Color3.fromRGB(194, 203, 210),
        DirtColor = Color3.fromRGB(166, 123, 91),
    },
    Decorations = {
        TreeChance = 0.08,
        RockChance = 0.12,
        PebbleChance = 0.2,
        WaterChance = 0.05,
        TallGrassChance = 0.15,
    },
    Fishing = {
        HotspotChance = 0.06,
        HotspotColor = Color3.fromRGB(255, 201, 107),
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
