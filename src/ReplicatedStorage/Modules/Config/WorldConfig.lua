local WorldConfig = {
    Tiles = {
        GridSize = Vector2.new(32, 32),
        TileSize = 6,
        ElevationStep = 1,
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
    Spawn = Vector3.new(0, 8, 0),
}

return WorldConfig
