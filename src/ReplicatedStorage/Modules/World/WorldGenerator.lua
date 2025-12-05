local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage.Modules.Config.WorldConfig)

local WorldGenerator = {}

local function choose(list)
    return list[math.random(1, #list)]
end

local function makeTile(folder, position, color)
    local tile = Instance.new("Part")
    tile.Anchored = true
    tile.Name = string.format("Tile_%d_%d_%d", position.X, position.Y, position.Z)
    tile.Material = Enum.Material.Grass
    tile.Color = color
    tile.Size = Vector3.new(WorldConfig.Tiles.TileSize, 1, WorldConfig.Tiles.TileSize)
    tile.Position = position
    tile.TopSurface = Enum.SurfaceType.Smooth
    tile.BottomSurface = Enum.SurfaceType.Smooth
    tile.Parent = folder
    return tile
end

local function makeRock(folder, position)
    local rock = Instance.new("Part")
    rock.Anchored = true
    rock.Material = Enum.Material.Slate
    rock.Shape = Enum.PartType.Ball
    rock.Size = Vector3.new(3.5, 3.5, 3.5)
    rock.Position = position + Vector3.new(0, 2, 0)
    rock.Color = WorldConfig.Tiles.RockColor
    rock.Name = "Rock"
    rock.Parent = folder
end

local function makePebble(folder, position)
    local pebble = Instance.new("Part")
    pebble.Anchored = true
    pebble.Material = Enum.Material.SmoothPlastic
    pebble.Shape = Enum.PartType.Ball
    pebble.Size = Vector3.new(1, 1, 1)
    pebble.Position = position + Vector3.new(math.random(-2, 2), 0.5, math.random(-2, 2))
    pebble.Color = WorldConfig.Tiles.RockColor
    pebble.Name = "Pebble"
    pebble.Parent = folder
end

local function makeTree(folder, position)
    local trunk = Instance.new("Part")
    trunk.Anchored = true
    trunk.Material = Enum.Material.Wood
    trunk.Color = WorldConfig.Tiles.DirtColor
    trunk.Size = Vector3.new(1.5, 6, 1.5)
    trunk.Position = position + Vector3.new(0, trunk.Size.Y / 2, 0)
    trunk.Name = "TreeTrunk"
    trunk.Parent = folder

    local leaves = Instance.new("Part")
    leaves.Anchored = true
    leaves.Material = Enum.Material.SmoothPlastic
    leaves.Color = choose(WorldConfig.Tiles.GrassColors)
    leaves.Shape = Enum.PartType.Ball
    leaves.Size = Vector3.new(5, 5, 5)
    leaves.Position = trunk.Position + Vector3.new(0, trunk.Size.Y / 2 + 1.8, 0)
    leaves.Name = "TreeCanopy"
    leaves.Parent = folder
end

local function makeWater(folder, position)
    local water = Instance.new("Part")
    water.Anchored = true
    water.Material = Enum.Material.Glass
    water.Color = WorldConfig.Tiles.WaterColor
    water.Transparency = 0.2
    water.Size = Vector3.new(WorldConfig.Tiles.TileSize, 0.6, WorldConfig.Tiles.TileSize)
    water.Position = position + Vector3.new(0, 0.3, 0)
    water.Name = "Water"
    water.Parent = folder
end

local function makeTallGrass(folder, position)
    local grass = Instance.new("Part")
    grass.Anchored = true
    grass.Material = Enum.Material.Grass
    grass.Color = choose(WorldConfig.Tiles.GrassColors)
    grass.Size = Vector3.new(1.2, 2, 1.2)
    grass.Position = position + Vector3.new(math.random(-2, 2), grass.Size.Y / 2, math.random(-2, 2))
    grass.Name = "TallGrass"
    grass.Parent = folder
end

local function makeHotspot(folder, position)
    local buoy = Instance.new("Part")
    buoy.Anchored = true
    buoy.Material = Enum.Material.Neon
    buoy.Color = WorldConfig.Fishing.HotspotColor
    buoy.Shape = Enum.PartType.Ball
    buoy.Size = Vector3.new(1.5, 1.5, 1.5)
    buoy.Position = position + Vector3.new(0, 1.5, 0)
    buoy.Name = "FishingHotspot"
    buoy.Parent = folder
end

local function generateDecorations(folder, tilePosition)
    if math.random() < WorldConfig.Decorations.WaterChance then
        makeWater(folder, tilePosition)
    end

    if math.random() < WorldConfig.Decorations.TreeChance then
        makeTree(folder, tilePosition)
    elseif math.random() < WorldConfig.Decorations.RockChance then
        makeRock(folder, tilePosition)
    end

    if math.random() < WorldConfig.Decorations.PebbleChance then
        makePebble(folder, tilePosition)
    end

    if math.random() < WorldConfig.Decorations.TallGrassChance then
        makeTallGrass(folder, tilePosition)
    end

    if math.random() < WorldConfig.Fishing.HotspotChance then
        makeHotspot(folder, tilePosition)
    end
end

function WorldGenerator.BuildWorld(seed)
    math.randomseed(seed or os.time())

    if Workspace:FindFirstChild("IsometricWorld") then
        Workspace.IsometricWorld:Destroy()
    end

    local worldFolder = Instance.new("Folder")
    worldFolder.Name = "IsometricWorld"
    worldFolder.Parent = Workspace

    for x = 1, WorldConfig.Tiles.GridSize.X do
        for y = 1, WorldConfig.Tiles.GridSize.Y do
            local height = math.random(0, 1) * WorldConfig.Tiles.ElevationStep
            local position = Vector3.new(
                (x - 1) * WorldConfig.Tiles.TileSize,
                height,
                (y - 1) * WorldConfig.Tiles.TileSize
            )

            local tileColor = choose(WorldConfig.Tiles.GrassColors)
            local tile = makeTile(worldFolder, position, tileColor)
            tile.Position += Vector3.new(0, tile.Size.Y / 2, 0)
            generateDecorations(worldFolder, tile.Position)
        end
    end

    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Size = Vector3.new(WorldConfig.Tiles.TileSize, 1, WorldConfig.Tiles.TileSize)
    spawnLocation.Position = WorldConfig.Spawn + Vector3.new(0, spawnLocation.Size.Y / 2, 0)
    spawnLocation.Anchored = true
    spawnLocation.CanCollide = true
    spawnLocation.Transparency = 0.5
    spawnLocation.Name = "Spawn"
    spawnLocation.Parent = worldFolder

    return worldFolder
end

return WorldGenerator
