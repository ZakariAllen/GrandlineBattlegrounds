local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage.Modules.Config.WorldConfig)
local TerrainNoise = require(ReplicatedStorage.Modules.World.TerrainNoise)

local WorldGenerator = {}

local assets = ReplicatedStorage:WaitForChild("Assets", 5)
local tilesFolder = assets and assets:FindFirstChild("Tiles")
local tileTemplates = tilesFolder and {
    Grass = tilesFolder:FindFirstChild("Grass"),
    Sand = tilesFolder:FindFirstChild("Sand"),
    Water = tilesFolder:FindFirstChild("Water"),
}
local tileSize = WorldConfig.Tiles.TileSize
local tileThickness = WorldConfig.Tiles.TileThickness or math.max(4, math.floor(tileSize * 0.5))
local activeRadius = WorldConfig.Tiles.ActiveRadius or 32

local generatedTiles = {}
local hotspots = {}
local lastPlayerCenters = {}
local worldFolder
local updateConnection
local playerAddedConnection
local playerRemovingConnection

local function tileKey(tileX, tileZ)
    return string.format("%d:%d", tileX, tileZ)
end

local function anchorTileParts(tile)
    if tile:IsA("BasePart") then
        tile.Anchored = true
        return
    end

    if tile:IsA("Model") then
        for _, descendant in ipairs(tile:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Anchored = true
            end
        end
    end
end

local function applyTileVisuals(tile, sample)
    if not tile or not tile:IsA("BasePart") then
        return
    end

    tile.Material = (function()
        if sample.type == "Water" then
            return Enum.Material.SmoothPlastic
        elseif sample.type == "Sand" then
            return Enum.Material.Sand
        elseif sample.type == "Rock" then
            return Enum.Material.Slate
        else
            return Enum.Material.Grass
        end
    end)()

    tile.Color = sample.color
    tile.TopSurface = Enum.SurfaceType.Smooth
    tile.BottomSurface = Enum.SurfaceType.Smooth
    tile:SetAttribute("TileType", sample.type)
end

local function pickVariant(list, tileX, tileZ, salt)
    if not list or #list == 0 then
        return nil
    end
    local hash = math.abs(TerrainNoise.RandomOffset(tileX, tileZ, 0.49, salt or 0)) % 1
    local idx = math.clamp(math.floor(hash * #list) + 1, 1, #list)
    return list[idx]
end

local function placeTile(folder, tileX, tileZ, sample)
    local basePosition = Vector3.new(tileX * tileSize, sample.height, tileZ * tileSize)
    local template = tileTemplates and tileTemplates[sample.type]
    local tile
    local size

    if template then
        tile = template:Clone()
        tile.Name = string.format("%sTile_%d_%d_%d", sample.type, basePosition.X, basePosition.Y, basePosition.Z)
        tile.Parent = folder
        anchorTileParts(tile)

        if tile:IsA("Model") then
            size = tile:GetExtentsSize()
            tile:PivotTo(CFrame.new(basePosition + Vector3.new(0, size.Y / 2, 0)))
            applyTileVisuals(tile.PrimaryPart or tile:FindFirstChildWhichIsA("BasePart"), sample)
        elseif tile:IsA("BasePart") then
            size = tile.Size
            tile.CFrame = CFrame.new(basePosition + Vector3.new(0, size.Y / 2, 0))
            applyTileVisuals(tile, sample)
        end
    end

    if not tile then
        local fallback = Instance.new("Part")
        fallback.Anchored = true
        fallback.Size = Vector3.new(tileSize, tileThickness, tileSize)
        fallback.Position = basePosition + Vector3.new(0, fallback.Size.Y / 2, 0)
        fallback.TopSurface = Enum.SurfaceType.Smooth
        fallback.BottomSurface = Enum.SurfaceType.Smooth
        fallback.Name = string.format("%sTile_%d_%d", sample.type, tileX, tileZ)
        applyTileVisuals(fallback, sample)
        fallback.Parent = folder

        tile = fallback
        size = fallback.Size
    end

    if not size then
        size = Vector3.new(tileSize, tileSize, tileSize)
    end

    return tile, size
end

local function makeRock(folder, surfacePosition, offsetRange, tileX, tileZ)
    local rock = Instance.new("Part")
    rock.Anchored = true
    rock.Material = Enum.Material.Slate
    rock.Shape = Enum.PartType.Ball
    rock.Size = Vector3.new(3.5, 3.5, 3.5)
    rock.Position = surfacePosition
        + Vector3.new(
            TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 51),
            rock.Size.Y / 2,
            TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 52)
        )
    rock.Color = WorldConfig.Tiles.RockColor
    rock.Name = "Rock"
    rock.Parent = folder
end

local function makePebble(folder, surfacePosition, offsetRange, tileX, tileZ)
    local pebble = Instance.new("Part")
    pebble.Anchored = true
    pebble.Material = Enum.Material.SmoothPlastic
    pebble.Shape = Enum.PartType.Ball
    pebble.Size = Vector3.new(1, 1, 1)
    pebble.Position = surfacePosition
        + Vector3.new(
            TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 53),
            pebble.Size.Y / 2,
            TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 54)
        )
    pebble.Color = WorldConfig.Tiles.RockColor
    pebble.Name = "Pebble"
    pebble.Parent = folder
end

local function makeTree(folder, surfacePosition, offsetRange, tileX, tileZ)
    local trunk = Instance.new("Part")
    trunk.Anchored = true
    trunk.Material = Enum.Material.Wood
    trunk.Color = WorldConfig.Tiles.DirtColor
    trunk.Size = Vector3.new(1.5, 6, 1.5)
    trunk.Position = surfacePosition
        + Vector3.new(TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 1), trunk.Size.Y / 2, TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 2))
    trunk.Name = "TreeTrunk"
    trunk.Parent = folder

    local leaves = Instance.new("Part")
    leaves.Anchored = true
    leaves.Material = Enum.Material.SmoothPlastic
    leaves.Color = pickVariant(WorldConfig.Tiles.GrassColors, tileX, tileZ, 9) or WorldConfig.Tiles.GrassColors[1]
    leaves.Shape = Enum.PartType.Ball
    leaves.Size = Vector3.new(5, 5, 5)
    leaves.Position = trunk.Position + Vector3.new(0, trunk.Size.Y / 2 + 1.8, 0)
    leaves.Name = "TreeCanopy"
    leaves.Parent = folder
end

local function makeTallGrass(folder, surfacePosition, offsetRange, tileX, tileZ)
    local grass = Instance.new("Part")
    grass.Anchored = true
    grass.Material = Enum.Material.Grass
    grass.Color = pickVariant(WorldConfig.Tiles.GrassColors, tileX, tileZ, 13) or WorldConfig.Tiles.GrassColors[1]
    grass.Size = Vector3.new(1.2, 2, 1.2)
    grass.Position = surfacePosition
        + Vector3.new(TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 5), grass.Size.Y / 2, TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 6))
    grass.Name = "TallGrass"
    grass.Parent = folder
end

local function makeDriftwood(folder, surfacePosition, offsetRange, tileX, tileZ)
    local plank = Instance.new("Part")
    plank.Anchored = true
    plank.Material = Enum.Material.WoodPlanks
    plank.Color = WorldConfig.Tiles.DirtColor
    plank.Size = Vector3.new(4.5, 0.6, 1.2)
    plank.Orientation = Vector3.new(0, TerrainNoise.RandomOffset(tileX, tileZ, 35, 15), TerrainNoise.RandomOffset(tileX, tileZ, 4, 16))
    plank.Position = surfacePosition
        + Vector3.new(TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 17), plank.Size.Y / 2, TerrainNoise.RandomOffset(tileX, tileZ, offsetRange, 18))
    plank.Name = "Driftwood"
    plank.Parent = folder
end

local function makeHotspot(folder, surfacePosition, tileX, tileZ)
    -- Hotspots temporarily disabled while art is rebuilt.
    return nil
end

local function generateDecorations(parent, tileType, tileTopPosition, tileX, tileZ)
    -- Decorations temporarily disabled; tiles only.
    return nil
end

local function purgeHotspotFor(record)
    -- No hotspots at the moment.
end

local function resetGeneratedTiles()
    for key, record in pairs(generatedTiles) do
        purgeHotspotFor(record)
        if record.instance then
            record.instance:Destroy()
        end
        generatedTiles[key] = nil
    end
end

local function recordTile(tileX, tileZ, tileType)
    local key = tileKey(tileX, tileZ)
    if generatedTiles[key] then
        return generatedTiles[key].instance
    end

    local sample = TerrainNoise.Sample(tileX, tileZ)
    local tile, tileSizeVec = placeTile(worldFolder, tileX, tileZ, sample)
    if tile then
        local topY = sample.height + (tileSizeVec.Y or tileThickness)
        local topPosition = Vector3.new(tileX * tileSize, topY, tileZ * tileSize)
        local hotspotPart = generateDecorations(tile, sample.type, topPosition, tileX, tileZ)
        generatedTiles[key] = {
            instance = tile,
            x = tileX,
            z = tileZ,
            size = tileSizeVec,
            sample = sample,
            hotspotPart = hotspotPart,
        }
    end

    return tile
end

local function generateTilesForCenter(tileX, tileZ)
    for x = tileX - activeRadius, tileX + activeRadius do
        for z = tileZ - activeRadius, tileZ + activeRadius do
            recordTile(x, z)
        end
    end
end

local function collectPlayerCenters()
    local centers = {}
    local changed = false
    local activePlayers = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local tileX = math.floor(root.Position.X / tileSize)
            local tileZ = math.floor(root.Position.Z / tileSize)
            centers[#centers + 1] = { x = tileX, z = tileZ }

            local last = lastPlayerCenters[player]
            if not last or last.x ~= tileX or last.z ~= tileZ then
                changed = true
                lastPlayerCenters[player] = { x = tileX, z = tileZ }
            end
            activePlayers[player] = true
        end
    end

    for player in pairs(lastPlayerCenters) do
        if not activePlayers[player] then
            lastPlayerCenters[player] = nil
            changed = true
        end
    end

    return centers, changed
end

local function cleanupFarTiles(centers)
    for key, record in pairs(generatedTiles) do
        local keep = false
        for _, center in ipairs(centers) do
            if math.abs(record.x - center.x) <= activeRadius
                and math.abs(record.z - center.z) <= activeRadius then
                keep = true
                break
            end
        end

        if not keep then
            purgeHotspotFor(record)
            if record.instance then
                record.instance:Destroy()
            end
            generatedTiles[key] = nil
        end
    end
end

local function updateHotspots(dt)
    -- Hotspot animation disabled while hotspot visuals are removed.
end

local function beginUpdateLoop()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end

    local function updateTiles(dt)
        local centers, changed = collectPlayerCenters()
        if #centers == 0 then
            updateHotspots(dt or 0)
            return
        end
        if not changed then
            updateHotspots(dt or 0)
            return
        end

        for _, center in ipairs(centers) do
            generateTilesForCenter(center.x, center.z)
        end
        cleanupFarTiles(centers)
        updateHotspots(dt or 0)
    end

    updateConnection = RunService.Heartbeat:Connect(updateTiles)
    updateTiles(0)
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not root then
            return
        end

        local tileX = math.floor(root.Position.X / tileSize)
        local tileZ = math.floor(root.Position.Z / tileSize)
        generateTilesForCenter(tileX, tileZ)
    end)
end

local function bindPlayerEvents()
    if playerAddedConnection then
        playerAddedConnection:Disconnect()
        playerAddedConnection = nil
    end
    if playerRemovingConnection then
        playerRemovingConnection:Disconnect()
        playerRemovingConnection = nil
    end

    playerAddedConnection = Players.PlayerAdded:Connect(onPlayerAdded)
    playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        lastPlayerCenters[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
end

function WorldGenerator.BuildWorld(seed)
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    if playerAddedConnection then
        playerAddedConnection:Disconnect()
        playerAddedConnection = nil
    end
    if playerRemovingConnection then
        playerRemovingConnection:Disconnect()
        playerRemovingConnection = nil
    end

    if Workspace:FindFirstChild("IsometricWorld") then
        Workspace.IsometricWorld:Destroy()
    end

    resetGeneratedTiles()
    lastPlayerCenters = {}

    worldFolder = Instance.new("Folder")
    worldFolder.Name = "IsometricWorld"
    worldFolder.Parent = Workspace

    local spawnSample = TerrainNoise.SampleFromWorldPosition(WorldConfig.Spawn)
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Size = Vector3.new(tileSize, 1, tileSize)
    spawnLocation.Position = Vector3.new(
        WorldConfig.Spawn.X,
        spawnSample.height + spawnLocation.Size.Y / 2,
        WorldConfig.Spawn.Z
    )
    spawnLocation.Anchored = true
    spawnLocation.CanCollide = true
    spawnLocation.Transparency = 0.5
    spawnLocation.Name = "Spawn"
    spawnLocation.Parent = worldFolder

    local spawnTileX = math.floor(WorldConfig.Spawn.X / tileSize)
    local spawnTileZ = math.floor(WorldConfig.Spawn.Z / tileSize)
    generateTilesForCenter(spawnTileX, spawnTileZ)
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local tileX = math.floor(root.Position.X / tileSize)
            local tileZ = math.floor(root.Position.Z / tileSize)
            generateTilesForCenter(tileX, tileZ)
        end
    end

    beginUpdateLoop()
    bindPlayerEvents()

    return worldFolder
end

return WorldGenerator
