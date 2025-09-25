local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local existingMap = Workspace:FindFirstChild("Map")
if existingMap then
    existingMap:Destroy()
end

local mapModel = Instance.new("Model")
mapModel.Name = "Map"
mapModel.Parent = Workspace

local function createPart(props)
    local partClass = props.ClassName or "Part"
    local part = Instance.new(partClass)
    part.Anchored = true
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.TopSurface = Enum.SurfaceType.Smooth

    local cframe = props.CFrame

    for key, value in pairs(props) do
        if key ~= "ClassName" and key ~= "Children" and key ~= "Parent" and key ~= "CFrame" then
            part[key] = value
        end
    end

    if cframe then
        part.CFrame = cframe
    end

    part.Parent = props.Parent or mapModel

    if props.Children then
        for _, childProps in ipairs(props.Children) do
            childProps.Parent = part
            createPart(childProps)
        end
    end

    return part
end

-- Base terrain
createPart({
    Name = "BasePlate",
    Size = Vector3.new(512, 2, 512),
    Position = Vector3.new(0, -1, 0),
    Material = Enum.Material.Grass,
    Color = Color3.fromRGB(94, 132, 65)
})

-- Central plaza / spawn area
local plaza = createPart({
    Name = "CentralPlaza",
    Size = Vector3.new(120, 1, 120),
    Position = Vector3.new(0, 0.5, 0),
    Material = Enum.Material.Concrete,
    Color = Color3.fromRGB(180, 181, 178)
})

-- Plaza border
for _, offset in ipairs({Vector3.new(0, 0.75, 60), Vector3.new(0, 0.75, -60), Vector3.new(60, 0.75, 0), Vector3.new(-60, 0.75, 0)}) do
    local isNorthSouth = offset.X == 0
    createPart({
        Name = "PlazaBorder",
        Size = isNorthSouth and Vector3.new(120, 1.5, 4) or Vector3.new(4, 1.5, 120),
        Position = plaza.Position + offset,
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(99, 95, 98)
    })
end

-- Spawn location in the center plaza
local spawnsFolder = Instance.new("Folder")
spawnsFolder.Name = "Spawns"
spawnsFolder.Parent = mapModel

local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "MainSpawn"
spawnLocation.Anchored = true
spawnLocation.Transparency = 1
spawnLocation.Size = Vector3.new(8, 1, 8)
spawnLocation.Position = Vector3.new(0, 1.1, 0)
spawnLocation.Neutral = true
spawnLocation.Parent = spawnsFolder

-- Decorative spawn pad ring
createPart({
    Name = "SpawnRing",
    Size = Vector3.new(14, 0.5, 14),
    Position = Vector3.new(0, 0.75, 0),
    Material = Enum.Material.Metal,
    Color = Color3.fromRGB(204, 188, 73)
})

-- Pathways extending from the plaza
local pathSize = Vector3.new(20, 1, 120)
createPart({
    Name = "NorthPath",
    Size = pathSize,
    Position = Vector3.new(0, 0.5, 120),
    Material = Enum.Material.Cobblestone,
    Color = Color3.fromRGB(112, 109, 108)
})
createPart({
    Name = "SouthPath",
    Size = pathSize,
    Position = Vector3.new(0, 0.5, -120),
    Material = Enum.Material.Cobblestone,
    Color = Color3.fromRGB(112, 109, 108)
})
createPart({
    Name = "EastPath",
    Size = Vector3.new(120, 1, 20),
    Position = Vector3.new(120, 0.5, 0),
    Material = Enum.Material.Cobblestone,
    Color = Color3.fromRGB(112, 109, 108)
})
createPart({
    Name = "WestPath",
    Size = Vector3.new(120, 1, 20),
    Position = Vector3.new(-120, 0.5, 0),
    Material = Enum.Material.Cobblestone,
    Color = Color3.fromRGB(112, 109, 108)
})

-- Small park area to the north-west of the plaza
local parkBase = createPart({
    Name = "ParkGrass",
    Size = Vector3.new(90, 1, 90),
    Position = Vector3.new(-120, 0.5, 120),
    Material = Enum.Material.Grass,
    Color = Color3.fromRGB(87, 142, 68)
})

createPart({
    Name = "ParkPath",
    Size = Vector3.new(80, 0.5, 12),
    Position = parkBase.Position + Vector3.new(0, 0.5, 0),
    Material = Enum.Material.Pebble,
    Color = Color3.fromRGB(151, 141, 129)
})

-- Park pond
createPart({
    Name = "Pond",
    Size = Vector3.new(30, 0.5, 30),
    Position = parkBase.Position + Vector3.new(-20, 0.3, 0),
    Material = Enum.Material.Water,
    Color = Color3.fromRGB(33, 84, 185)
})

-- Benches in the park
local function createBench(position, orientation)
    local benchModel = Instance.new("Model")
    benchModel.Name = "Bench"
    benchModel.Parent = mapModel

    local yaw = math.rad(orientation)
    local rotation = CFrame.Angles(0, yaw, 0)

    local seat = createPart({
        Name = "Seat",
        Size = Vector3.new(8, 0.5, 2),
        CFrame = CFrame.new(position) * rotation,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(145, 92, 46),
        Parent = benchModel
    })

    local backrest = createPart({
        Name = "Backrest",
        Size = Vector3.new(8, 2, 0.5),
        CFrame = CFrame.new(position + rotation:VectorToWorldSpace(Vector3.new(0, 1.25, -0.75))) * rotation,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(125, 81, 42),
        Parent = benchModel
    })

    for _, offset in ipairs({Vector3.new(-3, -1.25, -0.75), Vector3.new(3, -1.25, -0.75)}) do
        createPart({
            Name = "Leg",
            Size = Vector3.new(0.5, 2.5, 0.5),
            CFrame = CFrame.new(position + rotation:VectorToWorldSpace(offset)) * rotation,
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(100, 70, 35),
            Parent = benchModel
        })
    end
end

createBench(Vector3.new(-130, 1.5, 130), 45)
createBench(Vector3.new(-110, 1.5, 110), -45)

-- Simple trees for the park
local function createTree(position)
    local treeModel = Instance.new("Model")
    treeModel.Name = "Tree"
    treeModel.Parent = mapModel

    createPart({
        Name = "Trunk",
        Size = Vector3.new(2, 12, 2),
        Position = position + Vector3.new(0, 6, 0),
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(102, 51, 0),
        Parent = treeModel
    })

    createPart({
        ClassName = "Part",
        Shape = Enum.PartType.Ball,
        Name = "Leaves",
        Size = Vector3.new(10, 10, 10),
        Position = position + Vector3.new(0, 15, 0),
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(58, 125, 21),
        Parent = treeModel
    })
end

for _, offset in ipairs({Vector3.new(-150, 0, 150), Vector3.new(-100, 0, 140), Vector3.new(-140, 0, 100), Vector3.new(-120, 0, 160)}) do
    createTree(Vector3.new(offset.X, 0, offset.Z))
end

-- Town district to the east of the plaza
local townBase = createPart({
    Name = "TownSquare",
    Size = Vector3.new(160, 1, 140),
    Position = Vector3.new(180, 0.5, 0),
    Material = Enum.Material.Brick,
    Color = Color3.fromRGB(173, 159, 143)
})

local function createHouse(position, color)
    local houseModel = Instance.new("Model")
    houseModel.Name = "House"
    houseModel.Parent = mapModel

    createPart({
        Name = "HouseBase",
        Size = Vector3.new(20, 12, 18),
        Position = position + Vector3.new(0, 6, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = color,
        Parent = houseModel
    })

    local roof = Instance.new("WedgePart")
    roof.Anchored = true
    roof.Size = Vector3.new(20, 8, 18)
    roof.Position = position + Vector3.new(0, 16, 0)
    roof.Orientation = Vector3.new(0, 0, 0)
    roof.Material = Enum.Material.Slate
    roof.Color = Color3.fromRGB(80, 76, 74)
    roof.BottomSurface = Enum.SurfaceType.Smooth
    roof.TopSurface = Enum.SurfaceType.Smooth
    roof.Parent = houseModel

    -- Door
    createPart({
        Name = "Door",
        Size = Vector3.new(3, 6, 0.5),
        Position = position + Vector3.new(0, 3, 9),
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(111, 73, 42),
        Parent = houseModel
    })

    -- Windows
    createPart({
        Name = "WindowLeft",
        Size = Vector3.new(3, 3, 0.5),
        Position = position + Vector3.new(-6, 7, 9),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(189, 232, 247),
        Transparency = 0.3,
        Parent = houseModel
    })

    createPart({
        Name = "WindowRight",
        Size = Vector3.new(3, 3, 0.5),
        Position = position + Vector3.new(6, 7, 9),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(189, 232, 247),
        Transparency = 0.3,
        Parent = houseModel
    })
end

local housePositions = {
    {Vector3.new(140, 0, 50), Color3.fromRGB(241, 196, 15)},
    {Vector3.new(170, 0, -10), Color3.fromRGB(231, 76, 60)},
    {Vector3.new(200, 0, 60), Color3.fromRGB(46, 204, 113)},
    {Vector3.new(230, 0, -30), Color3.fromRGB(52, 152, 219)},
    {Vector3.new(260, 0, 20), Color3.fromRGB(155, 89, 182)}
}

for _, info in ipairs(housePositions) do
    createHouse(info[1], info[2])
end

-- Market stalls in the town square
local function createMarketStall(position, color)
    local stallModel = Instance.new("Model")
    stallModel.Name = "MarketStall"
    stallModel.Parent = mapModel

    local counter = createPart({
        Name = "Counter",
        Size = Vector3.new(12, 3, 6),
        Position = position + Vector3.new(0, 1.5, 0),
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(139, 84, 43),
        Parent = stallModel
    })

    createPart({
        Name = "Canopy",
        Size = Vector3.new(12, 1, 6),
        Position = position + Vector3.new(0, 4.5, 0),
        Material = Enum.Material.Fabric,
        Color = color,
        Parent = stallModel
    })

    for _, offset in ipairs({Vector3.new(-5.5, 0, -2.5), Vector3.new(5.5, 0, -2.5), Vector3.new(-5.5, 0, 2.5), Vector3.new(5.5, 0, 2.5)}) do
        createPart({
            Name = "Support",
            Size = Vector3.new(0.5, 5, 0.5),
            Position = position + offset + Vector3.new(0, 2.5, 0),
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(99, 68, 29),
            Parent = stallModel
        })
    end
end

createMarketStall(Vector3.new(180, 0, -50), Color3.fromRGB(236, 240, 241))
createMarketStall(Vector3.new(210, 0, -10), Color3.fromRGB(243, 156, 18))
createMarketStall(Vector3.new(150, 0, 20), Color3.fromRGB(52, 73, 94))

-- Cliffs framing the map edges
local function createCliff(position, size)
    createPart({
        Name = "Cliff",
        Size = size,
        Position = position,
        Material = Enum.Material.Rock,
        Color = Color3.fromRGB(93, 92, 89)
    })
end

createCliff(Vector3.new(0, 20, 260), Vector3.new(512, 40, 40))
createCliff(Vector3.new(0, 20, -260), Vector3.new(512, 40, 40))
createCliff(Vector3.new(260, 20, 0), Vector3.new(40, 40, 512))
createCliff(Vector3.new(-260, 20, 0), Vector3.new(40, 40, 512))

if not Lighting:GetAttribute("MapLightingConfigured") then
    Lighting.Brightness = 2.2
    Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    Lighting.OutdoorAmbient = Color3.fromRGB(114, 117, 128)
    Lighting:SetAttribute("MapLightingConfigured", true)
end

return mapModel
