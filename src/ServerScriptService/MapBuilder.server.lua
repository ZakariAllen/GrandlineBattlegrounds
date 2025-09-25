local Workspace = game:GetService("Workspace")

local MAP_NAME = "GrandlineGeneratedMap"

if Workspace:FindFirstChild(MAP_NAME) then
    return
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = MAP_NAME
mapFolder.Parent = Workspace

local function createPart(properties)
    local part = Instance.new("Part")
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Size = properties.Size or Vector3.new(4, 1, 4)
    part.CFrame = properties.CFrame or CFrame.new()
    part.Material = properties.Material or Enum.Material.SmoothPlastic
    part.Color = properties.Color or Color3.new(1, 1, 1)
    part.Name = properties.Name or "Part"
    if properties.Shape then
        part.Shape = properties.Shape
    end
    if properties.Transparency then
        part.Transparency = properties.Transparency
    end
    if properties.Reflectance then
        part.Reflectance = properties.Reflectance
    end
    part.Parent = properties.Parent or mapFolder
    return part
end

local function createSpawnArea()
    createPart({
        Name = "Baseplate",
        Size = Vector3.new(300, 2, 300),
        CFrame = CFrame.new(0, -1, 0),
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(93, 169, 92),
    })

    local plaza = createPart({
        Name = "CentralPlaza",
        Size = Vector3.new(70, 1, 70),
        CFrame = CFrame.new(0, 0.5, 0),
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(210, 210, 210),
    })

    createPart({
        Name = "PlazaTrim",
        Size = Vector3.new(74, 1.2, 74),
        CFrame = CFrame.new(0, 0.6, 0),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(80, 80, 80),
    })

    createPart({
        Name = "PlazaFountainBase",
        Size = Vector3.new(18, 1, 18),
        CFrame = CFrame.new(0, 1.1, 0),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(60, 60, 60),
    })

    local fountainBasin = createPart({
        Name = "PlazaFountain",
        Size = Vector3.new(15, 1.2, 15),
        CFrame = CFrame.new(0, 1.3, 0),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(120, 120, 120),
    })

    createPart({
        Name = "FountainWater",
        Size = Vector3.new(12, 0.2, 12),
        CFrame = CFrame.new(0, 1.7, 0),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(112, 177, 255),
        Transparency = 0.3,
    })

    local fountainSpray = createPart({
        Name = "FountainSpray",
        Size = Vector3.new(2, 8, 2),
        CFrame = CFrame.new(0, 5.2, 0),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(173, 221, 255),
        Transparency = 0.1,
    })

    fountainSpray.Shape = Enum.PartType.Cylinder

    local spawnPad = Instance.new("SpawnLocation")
    spawnPad.Name = "CentralSpawn"
    spawnPad.Anchored = true
    spawnPad.Size = Vector3.new(8, 1, 8)
    spawnPad.CFrame = CFrame.new(0, 1.1, -18)
    spawnPad.TopSurface = Enum.SurfaceType.Smooth
    spawnPad.BottomSurface = Enum.SurfaceType.Smooth
    spawnPad.Neutral = true
    spawnPad.AllowTeamChangeOnTouch = false
    spawnPad.Material = Enum.Material.Marble
    spawnPad.BrickColor = BrickColor.new("Institutional white")
    spawnPad.Parent = mapFolder

    createPart({
        Name = "SpawnHighlight",
        Size = Vector3.new(12, 0.4, 12),
        CFrame = CFrame.new(0, 0.8, -18),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(0, 170, 255),
        Transparency = 0.35,
    })

    local function createBench(position, rotationDegrees)
        rotationDegrees = rotationDegrees or 0
        local seatHeight = 1.4
        local base = CFrame.new(position.X, seatHeight, position.Z) * CFrame.Angles(0, math.rad(rotationDegrees), 0)

        local seat = createPart({
            Name = "BenchSeat",
            Size = Vector3.new(6, 0.4, 2),
            CFrame = base,
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(150, 111, 51),
        })

        createPart({
            Name = "BenchBack",
            Size = Vector3.new(6, 1.6, 0.3),
            CFrame = base * CFrame.new(0, 0.8, -0.9),
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(121, 85, 46),
        })

        local legOffsets = {
            Vector3.new(-2.4, -0.9, 0.7),
            Vector3.new(2.4, -0.9, 0.7),
            Vector3.new(-2.4, -0.9, -0.7),
            Vector3.new(2.4, -0.9, -0.7),
        }

        for _, offset in ipairs(legOffsets) do
            createPart({
                Name = "BenchLeg",
                Size = Vector3.new(0.4, 1.6, 0.4),
                CFrame = seat.CFrame * CFrame.new(offset.X, offset.Y, offset.Z),
                Material = Enum.Material.Metal,
                Color = Color3.fromRGB(90, 90, 90),
            })
        end
    end

    createBench(Vector3.new(-10, 0, -30), 45)
    createBench(Vector3.new(10, 0, -30), -45)
    createBench(Vector3.new(-10, 0, 30), 135)
    createBench(Vector3.new(10, 0, 30), -135)
end

local function createTree(position)
    createPart({
        Name = "TreeTrunk",
        Size = Vector3.new(2.2, 8, 2.2),
        CFrame = CFrame.new(position.X, 4, position.Z),
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(120, 92, 58),
    })

    createPart({
        Name = "TreeLeaves",
        Size = Vector3.new(7, 7, 7),
        CFrame = CFrame.new(position.X, 9, position.Z),
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(76, 141, 71),
        Shape = Enum.PartType.Ball,
    })
end

local function createLampPost(position)
    createPart({
        Name = "LampBase",
        Size = Vector3.new(2, 0.6, 2),
        CFrame = CFrame.new(position.X, 0.3, position.Z),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(50, 50, 50),
    })

    local pole = createPart({
        Name = "LampPole",
        Size = Vector3.new(0.6, 10, 0.6),
        CFrame = CFrame.new(position.X, 5.3, position.Z),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(40, 40, 40),
    })

    local lamp = createPart({
        Name = "LampLight",
        Size = Vector3.new(2, 2, 2),
        CFrame = CFrame.new(position.X, 10.5, position.Z),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(255, 245, 200),
        Shape = Enum.PartType.Ball,
    })

    local light = Instance.new("PointLight")
    light.Range = 25
    light.Brightness = 2.2
    light.Color = lamp.Color
    light.Parent = lamp

    pole.Anchored = true
    lamp.Anchored = true
end

local function createPark()
    local parkArea = createPart({
        Name = "ParkLawn",
        Size = Vector3.new(110, 1, 80),
        CFrame = CFrame.new(-110, 0.5, 0),
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(88, 170, 78),
    })

    createPart({
        Name = "ParkPath",
        Size = Vector3.new(110, 0.6, 8),
        CFrame = CFrame.new(-110, 0.8, 0),
        Material = Enum.Material.Pebble,
        Color = Color3.fromRGB(190, 190, 190),
    })

    createPart({
        Name = "ParkCrossPath",
        Size = Vector3.new(40, 0.5, 30),
        CFrame = CFrame.new(-110, 0.75, -18),
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(170, 170, 170),
    })

    createPart({
        Name = "Pond",
        Size = Vector3.new(30, 0.4, 22),
        CFrame = CFrame.new(-120, 0.7, 18),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(70, 140, 200),
        Transparency = 0.45,
    })

    createPart({
        Name = "PondBorder",
        Size = Vector3.new(32, 0.8, 24),
        CFrame = CFrame.new(-120, 0.9, 18),
        Material = Enum.Material.Sandstone,
        Color = Color3.fromRGB(210, 198, 160),
    })

    createPart({
        Name = "GardenGazeboFloor",
        Size = Vector3.new(12, 0.6, 12),
        CFrame = CFrame.new(-90, 0.8, 20),
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(180, 150, 110),
    })

    local gazeboRoof = createPart({
        Name = "GardenGazeboRoof",
        Size = Vector3.new(12, 4, 12),
        CFrame = CFrame.new(-90, 4, 20),
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(150, 120, 80),
    })
    gazeboRoof.Shape = Enum.PartType.Cylinder
    gazeboRoof.CFrame = gazeboRoof.CFrame * CFrame.Angles(0, 0, math.rad(90))

    local gazeboLight = Instance.new("PointLight")
    gazeboLight.Range = 15
    gazeboLight.Brightness = 1.4
    gazeboLight.Color = Color3.fromRGB(255, 218, 164)
    gazeboLight.Parent = gazeboRoof

    local treePositions = {
        Vector3.new(-150, 0, -25),
        Vector3.new(-130, 0, 30),
        Vector3.new(-100, 0, -35),
        Vector3.new(-80, 0, 35),
        Vector3.new(-60, 0, -15),
    }

    for _, position in ipairs(treePositions) do
        createTree(position)
    end

    local benches = {
        { position = Vector3.new(-100, 0, -10), rotation = 90 },
        { position = Vector3.new(-120, 0, -10), rotation = 90 },
        { position = Vector3.new(-90, 0, 30), rotation = 180 },
    }

    for _, config in ipairs(benches) do
        local benchPosition = config.position
        local rotation = config.rotation or 0
        local seatHeight = 1.2
        local base = CFrame.new(benchPosition.X, seatHeight, benchPosition.Z)
            * CFrame.Angles(0, math.rad(rotation), 0)

        local seat = createPart({
            Name = "ParkBenchSeat",
            Size = Vector3.new(5, 0.4, 2),
            CFrame = base,
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(160, 120, 70),
        })

        createPart({
            Name = "ParkBenchBack",
            Size = Vector3.new(5, 1.4, 0.3),
            CFrame = base * CFrame.new(0, 0.7, -0.9),
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(130, 90, 50),
        })

        local offsets = {
            Vector3.new(-2, -0.8, 0.7),
            Vector3.new(2, -0.8, 0.7),
            Vector3.new(-2, -0.8, -0.7),
            Vector3.new(2, -0.8, -0.7),
        }

        for _, offset in ipairs(offsets) do
            createPart({
                Name = "ParkBenchLeg",
                Size = Vector3.new(0.4, 1.4, 0.4),
                CFrame = seat.CFrame * CFrame.new(offset.X, offset.Y, offset.Z),
                Material = Enum.Material.Metal,
                Color = Color3.fromRGB(90, 90, 90),
            })
        end
    end

    createLampPost(Vector3.new(-80, 0, -25))
    createLampPost(Vector3.new(-140, 0, 25))
    createLampPost(Vector3.new(-110, 0, 35))

    createPart({
        Name = "ParkBorder",
        Size = Vector3.new(110, 3, 2),
        CFrame = CFrame.new(-110, 1.5, 41),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(150, 75, 60),
    })

    createPart({
        Name = "ParkBorderBack",
        Size = Vector3.new(110, 3, 2),
        CFrame = CFrame.new(-110, 1.5, -41),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(150, 75, 60),
    })

    createPart({
        Name = "ParkBorderLeft",
        Size = Vector3.new(2, 3, 80),
        CFrame = CFrame.new(-165, 1.5, 0),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(150, 75, 60),
    })

    createPart({
        Name = "ParkBorderRight",
        Size = Vector3.new(2, 3, 80),
        CFrame = CFrame.new(-55, 1.5, 0),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(150, 75, 60),
    })
end

local function createBuilding(config)
    local base = createPart({
        Name = config.Name .. "Base",
        Size = Vector3.new(config.Width, config.Height, config.Depth),
        CFrame = CFrame.new(config.Position.X, config.Height / 2, config.Position.Z),
        Material = Enum.Material.Brick,
        Color = config.Color,
    })

    createPart({
        Name = config.Name .. "Roof",
        Size = Vector3.new(config.Width + 2, 1.2, config.Depth + 2),
        CFrame = CFrame.new(config.Position.X, config.Height + 0.6, config.Position.Z),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(100, 100, 100),
    })

    createPart({
        Name = config.Name .. "Door",
        Size = Vector3.new(3, 5, 0.4),
        CFrame = CFrame.new(
            config.Position.X,
            2.5,
            config.Position.Z - (config.Depth / 2) + 0.3
        ),
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(120, 80, 40),
    })

    local windowHeight = 3
    local windowSize = Vector3.new(4, 3, 0.4)
    local windowOffsetZ = (config.Depth / 2) - 0.4

    createPart({
        Name = config.Name .. "WindowLeft",
        Size = windowSize,
        CFrame = CFrame.new(
            config.Position.X - (config.Width / 4),
            config.Height * 0.6,
            config.Position.Z - windowOffsetZ
        ),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(180, 230, 255),
        Transparency = 0.25,
    })

    createPart({
        Name = config.Name .. "WindowRight",
        Size = windowSize,
        CFrame = CFrame.new(
            config.Position.X + (config.Width / 4),
            config.Height * 0.6,
            config.Position.Z - windowOffsetZ
        ),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(180, 230, 255),
        Transparency = 0.25,
    })

    return base
end

local function createTown()
    createPart({
        Name = "TownPlaza",
        Size = Vector3.new(130, 1, 120),
        CFrame = CFrame.new(120, 0.5, 0),
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(205, 205, 205),
    })

    createPart({
        Name = "MainRoad",
        Size = Vector3.new(130, 0.6, 22),
        CFrame = CFrame.new(120, 0.8, 0),
        Material = Enum.Material.Asphalt,
        Color = Color3.fromRGB(45, 45, 45),
    })

    createPart({
        Name = "Crosswalk",
        Size = Vector3.new(16, 0.65, 22),
        CFrame = CFrame.new(80, 0.825, 0),
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(230, 230, 230),
    })

    local buildingConfigs = {
        {
            Name = "TownhouseA",
            Position = Vector3.new(100, 0, -30),
            Width = 24,
            Depth = 20,
            Height = 18,
            Color = Color3.fromRGB(232, 208, 171),
        },
        {
            Name = "TownhouseB",
            Position = Vector3.new(130, 0, -30),
            Width = 20,
            Depth = 18,
            Height = 16,
            Color = Color3.fromRGB(199, 139, 116),
        },
        {
            Name = "TownhouseC",
            Position = Vector3.new(160, 0, -30),
            Width = 22,
            Depth = 20,
            Height = 17,
            Color = Color3.fromRGB(175, 197, 221),
        },
        {
            Name = "TownhouseD",
            Position = Vector3.new(100, 0, 30),
            Width = 22,
            Depth = 18,
            Height = 15,
            Color = Color3.fromRGB(218, 179, 132),
        },
        {
            Name = "TownhouseE",
            Position = Vector3.new(130, 0, 30),
            Width = 24,
            Depth = 20,
            Height = 19,
            Color = Color3.fromRGB(162, 196, 183),
        },
        {
            Name = "TownhouseF",
            Position = Vector3.new(160, 0, 30),
            Width = 22,
            Depth = 18,
            Height = 16,
            Color = Color3.fromRGB(205, 142, 160),
        },
    }

    for _, config in ipairs(buildingConfigs) do
        createBuilding(config)
    end

    createPart({
        Name = "MarketplaceAwning",
        Size = Vector3.new(18, 0.6, 12),
        CFrame = CFrame.new(120, 4.4, 18),
        Material = Enum.Material.Fabric,
        Color = Color3.fromRGB(240, 110, 110),
    })

    createPart({
        Name = "MarketplaceTable",
        Size = Vector3.new(16, 1, 10),
        CFrame = CFrame.new(120, 2.5, 18),
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(170, 120, 70),
    })

    for _, offset in ipairs({ -7, 7 }) do
        createPart({
            Name = "MarketplacePost",
            Size = Vector3.new(0.8, 5, 0.8),
            CFrame = CFrame.new(120 + offset, 2.5, 12),
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(140, 96, 52),
        })
    end

    createLampPost(Vector3.new(90, 0, -10))
    createLampPost(Vector3.new(150, 0, -10))
    createLampPost(Vector3.new(90, 0, 10))
    createLampPost(Vector3.new(150, 0, 10))

    createPart({
        Name = "TownFountainBase",
        Size = Vector3.new(20, 0.8, 20),
        CFrame = CFrame.new(120, 1, -18),
        Material = Enum.Material.Marble,
        Color = Color3.fromRGB(200, 200, 200),
    })

    createPart({
        Name = "TownFountainWater",
        Size = Vector3.new(16, 0.3, 16),
        CFrame = CFrame.new(120, 1.3, -18),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(120, 180, 255),
        Transparency = 0.35,
    })

    createPart({
        Name = "TownSquareBorder",
        Size = Vector3.new(130, 2.2, 2),
        CFrame = CFrame.new(120, 1.1, -60),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(150, 75, 60),
    })

    createPart({
        Name = "TownSquareBorderBack",
        Size = Vector3.new(130, 2.2, 2),
        CFrame = CFrame.new(120, 1.1, 60),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(150, 75, 60),
    })
end

local function connectAreas()
    createPart({
        Name = "ParkPathway",
        Size = Vector3.new(100, 0.4, 12),
        CFrame = CFrame.new(-50, 0.7, 0),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(205, 205, 205),
    })

    createPart({
        Name = "TownPathway",
        Size = Vector3.new(100, 0.4, 14),
        CFrame = CFrame.new(50, 0.7, 0),
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(205, 205, 205),
    })

    createPart({
        Name = "NorthWalk",
        Size = Vector3.new(40, 0.4, 12),
        CFrame = CFrame.new(0, 0.7, -60),
        Material = Enum.Material.Pebble,
        Color = Color3.fromRGB(195, 195, 195),
    })

    createPart({
        Name = "SouthWalk",
        Size = Vector3.new(40, 0.4, 12),
        CFrame = CFrame.new(0, 0.7, 60),
        Material = Enum.Material.Pebble,
        Color = Color3.fromRGB(195, 195, 195),
    })

    createLampPost(Vector3.new(-40, 0, 0))
    createLampPost(Vector3.new(40, 0, 0))
end

createSpawnArea()
createPark()
createTown()
connectAreas()

