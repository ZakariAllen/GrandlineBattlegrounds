local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage.Modules.Config.WorldConfig)

local WorldGenerator = {}

local assets = ReplicatedStorage:WaitForChild("Assets", 5)
local tilesFolder = assets and assets:FindFirstChild("Tiles")
local tileTemplates = tilesFolder and {
    Grass = tilesFolder:FindFirstChild("Grass"),
    Sand = tilesFolder:FindFirstChild("Sand"),
    Water = tilesFolder:FindFirstChild("Water"),
}
local tileSize = WorldConfig.Tiles.TileSize
local activeRadius = WorldConfig.Tiles.ActiveRadius or 32
local baseHeight = WorldConfig.Tiles.BaseHeight or 0

local generatedTiles = {}
local lastPlayerCenters = {}
local worldFolder
local updateConnection
local playerAddedConnection
local playerRemovingConnection

local function choose(list)
    return list[math.random(1, #list)]
end

local function weightedTileType()
    local weights = WorldConfig.Tiles.TileTypeWeights
    if not weights or #weights == 0 then
        return "Grass"
    end

    local total = 0
    for _, entry in ipairs(weights) do
        total += entry.Weight
    end

    local roll = math.random() * total
    for _, entry in ipairs(weights) do
        roll -= entry.Weight
        if roll <= 0 then
            return entry.Type
        end
    end

    return weights[#weights].Type
end

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

local function placeTile(folder, basePosition, tileType)
    local template = tileTemplates and tileTemplates[tileType]
    local tile
    local size

    if template then
        tile = template:Clone()
        tile.Name = string.format("%sTile_%d_%d_%d", tileType, basePosition.X, basePosition.Y, basePosition.Z)
        tile.Parent = folder
        anchorTileParts(tile)

        if tile:IsA("Model") then
            size = tile:GetExtentsSize()
            tile:PivotTo(CFrame.new(basePosition + Vector3.new(0, size.Y / 2, 0)))
        elseif tile:IsA("BasePart") then
            size = tile.Size
            tile.CFrame = CFrame.new(basePosition + Vector3.new(0, size.Y / 2, 0))
        end
    end

    if not tile then
        local fallback = Instance.new("Part")
        fallback.Anchored = true
        fallback.Material = Enum.Material.SmoothPlastic
        fallback.Color = choose(WorldConfig.Tiles.GrassColors)
        fallback.Size = Vector3.new(tileSize, tileSize, tileSize)
        fallback.Position = basePosition + Vector3.new(0, fallback.Size.Y / 2, 0)
        fallback.TopSurface = Enum.SurfaceType.Smooth
        fallback.BottomSurface = Enum.SurfaceType.Smooth
        fallback.Name = string.format("%sTile_%d_%d_%d", tileType, basePosition.X, basePosition.Y, basePosition.Z)
        fallback.Parent = folder

        tile = fallback
        size = fallback.Size
    end

    if not size then
        size = Vector3.new(tileSize, tileSize, tileSize)
    end

    return tile, size
end

local function randomOffset(range)
    return (math.random() * 2 - 1) * range
end

local function makeRock(folder, surfacePosition, offsetRange)
    local rock = Instance.new("Part")
    rock.Anchored = true
    rock.Material = Enum.Material.Slate
    rock.Shape = Enum.PartType.Ball
    rock.Size = Vector3.new(3.5, 3.5, 3.5)
    rock.Position = surfacePosition
        + Vector3.new(randomOffset(offsetRange), rock.Size.Y / 2, randomOffset(offsetRange))
    rock.Color = WorldConfig.Tiles.RockColor
    rock.Name = "Rock"
    rock.Parent = folder
end

local function makePebble(folder, surfacePosition, offsetRange)
    local pebble = Instance.new("Part")
    pebble.Anchored = true
    pebble.Material = Enum.Material.SmoothPlastic
    pebble.Shape = Enum.PartType.Ball
    pebble.Size = Vector3.new(1, 1, 1)
    pebble.Position = surfacePosition
        + Vector3.new(randomOffset(offsetRange), pebble.Size.Y / 2, randomOffset(offsetRange))
    pebble.Color = WorldConfig.Tiles.RockColor
    pebble.Name = "Pebble"
    pebble.Parent = folder
end

local function makeTree(folder, surfacePosition, offsetRange)
    local trunk = Instance.new("Part")
    trunk.Anchored = true
    trunk.Material = Enum.Material.Wood
    trunk.Color = WorldConfig.Tiles.DirtColor
    trunk.Size = Vector3.new(1.5, 6, 1.5)
    trunk.Position = surfacePosition
        + Vector3.new(randomOffset(offsetRange), trunk.Size.Y / 2, randomOffset(offsetRange))
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

local function makeTallGrass(folder, surfacePosition, offsetRange)
    local grass = Instance.new("Part")
    grass.Anchored = true
    grass.Material = Enum.Material.Grass
    grass.Color = choose(WorldConfig.Tiles.GrassColors)
    grass.Size = Vector3.new(1.2, 2, 1.2)
    grass.Position = surfacePosition
        + Vector3.new(randomOffset(offsetRange), grass.Size.Y / 2, randomOffset(offsetRange))
    grass.Name = "TallGrass"
    grass.Parent = folder
end

local function makeHotspot(folder, surfacePosition)
    local buoy = Instance.new("Part")
    buoy.Anchored = true
    buoy.Material = Enum.Material.Neon
    buoy.Color = WorldConfig.Fishing.HotspotColor
    buoy.Shape = Enum.PartType.Ball
    buoy.Size = Vector3.new(1.5, 1.5, 1.5)
    buoy.Position = surfacePosition + Vector3.new(0, buoy.Size.Y / 2, 0)
    buoy.Name = "FishingHotspot"
    buoy.Parent = folder
end

local function generateDecorations(folder, tileType, tileTopPosition)
    -- Decorations temporarily disabled while focusing on stable terrain generation.
    return

    local offsetRange = WorldConfig.Tiles.TileSize * 0.25

    if tileType == "Water" then
        if math.random() < WorldConfig.Fishing.HotspotChance then
            makeHotspot(folder, tileTopPosition)
        end
        return
    end

    if tileType == "Grass" and math.random() < WorldConfig.Decorations.TreeChance then
        makeTree(folder, tileTopPosition, offsetRange * 0.6)
    elseif math.random() < WorldConfig.Decorations.RockChance then
        makeRock(folder, tileTopPosition, offsetRange)
    end

    if math.random() < WorldConfig.Decorations.PebbleChance then
        makePebble(folder, tileTopPosition, offsetRange * 0.4)
    end

    if tileType == "Grass" and math.random() < WorldConfig.Decorations.TallGrassChance then
        makeTallGrass(folder, tileTopPosition, offsetRange)
    end
end

local function resetGeneratedTiles()
    for key, record in pairs(generatedTiles) do
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

    local position = Vector3.new(tileX * tileSize, baseHeight, tileZ * tileSize)
    local tile, tileSizeVec = placeTile(worldFolder, position, tileType or weightedTileType())
    if tile then
        generatedTiles[key] = {
            instance = tile,
            x = tileX,
            z = tileZ,
            size = tileSizeVec,
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
            if record.instance then
                record.instance:Destroy()
            end
            generatedTiles[key] = nil
        end
    end
end

local function beginUpdateLoop()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end

    local function updateTiles()
        local centers, changed = collectPlayerCenters()
        if #centers == 0 then
            return
        end
        if not changed then
            return
        end

        for _, center in ipairs(centers) do
            generateTilesForCenter(center.x, center.z)
        end
        cleanupFarTiles(centers)
    end

    updateConnection = RunService.Heartbeat:Connect(updateTiles)
    updateTiles()
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
    math.randomseed(seed or os.time())

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

    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Size = Vector3.new(tileSize, 1, tileSize)
    spawnLocation.Position = Vector3.new(WorldConfig.Spawn.X, baseHeight + tileSize, WorldConfig.Spawn.Z)
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
