local WorldConfig = require(script.Parent.Parent.Config.WorldConfig)

local noiseCfg = WorldConfig.Noise
local tileCfg = WorldConfig.Tiles
local hotspotCfg = WorldConfig.Fishing.Hotspot

local TerrainNoise = {}

local function fractalNoise(x, z)
    local freq = noiseCfg.BaseFrequency or 0.04
    local amp = 1
    local total = 0
    local norm = 0
    local seed = noiseCfg.Seed or 0

    for octave = 1, (noiseCfg.Octaves or 4) do
        local nx = (x + seed * 0.37) * freq
        local nz = (z + seed * 0.73) * freq
        -- math.noise is deterministic and cheap; use Z as octave separator.
        total += math.noise(nx, nz, seed + octave * 0.33) * amp
        norm += amp
        amp *= noiseCfg.Persistence or 0.5
        freq *= 2
    end

    if norm <= 1e-5 then
        return 0.5
    end

    -- Normalize to 0..1
    return 0.5 + (total / norm) * 0.5
end

local function hash01(x, z, salt)
    local s = salt or 0
    local seed = noiseCfg.Seed or 0
    local n = math.noise(
        (x + seed * 0.1 + s) * 0.163,
        (z + seed * 0.2 + s) * 0.271,
        seed * 0.37 + s * 1.17
    )
    return math.abs(n % 1)
end

function TerrainNoise.RandomOffset(x, z, range, salt)
    return (hash01(x, z, salt) * 2 - 1) * range
end

local function pickTileType(elevation)
    if elevation < noiseCfg.WaterThreshold then
        return "Water"
    end
    if elevation < noiseCfg.WaterThreshold + (noiseCfg.BeachBand or 0.05) then
        return "Sand"
    end
    if elevation < noiseCfg.ForestThreshold then
        return "Grass"
    end
    if elevation < noiseCfg.RockThreshold then
        return "Forest"
    end
    return "Rock"
end

local function pickColor(tileType, elevation, x, z)
    if tileType == "Water" then
        local t = hash01(x, z, 3)
        return tileCfg.WaterColor:Lerp(tileCfg.WaterFoamColor, t * 0.15)
    elseif tileType == "Sand" then
        local shades = tileCfg.SandColors or { tileCfg.RockColor }
        return shades[(math.floor(hash01(x, z, 5) * #shades) % #shades) + 1]
    elseif tileType == "Forest" then
        local t = hash01(x, z, 7)
        local darker = tileCfg.ForestColor or tileCfg.GrassColors[1]
        local lighter = tileCfg.GrassColors[#tileCfg.GrassColors]
        return darker:Lerp(lighter, t * 0.25)
    elseif tileType == "Rock" then
        return tileCfg.RockColor
    end

    local shades = tileCfg.GrassColors
    return shades[(math.floor(hash01(x, z, 11) * #shades) % #shades) + 1]
end

local function plateauHeight(tileType, elevation)
    if tileType == "Water" then
        return tileCfg.BaseHeight + (tileCfg.WaterDepth or -6)
    end

    local steps = math.max(tileCfg.HeightSteps or 1, 1)
    local normalized = math.clamp(
        (elevation - noiseCfg.WaterThreshold) / math.max(1 - noiseCfg.WaterThreshold, 1e-4),
        0,
        1
    )
    local tier = math.floor(normalized * steps + 0.25)
    return tileCfg.BaseHeight + tier * (tileCfg.ElevationStep or 4)
end

function TerrainNoise.Sample(tileX, tileZ)
    local elevation = fractalNoise(tileX, tileZ)
    local tileType = pickTileType(elevation)
    local tileHeight = plateauHeight(tileType, elevation)
    local color = pickColor(tileType, elevation, tileX, tileZ)

    local hotspotChance = (hotspotCfg and hotspotCfg.Chance) or 0
    local isHotspot = tileType == "Water" and hash01(tileX, tileZ, 19) < hotspotChance

    return {
        type = tileType,
        elevation = elevation,
        height = tileHeight,
        color = color,
        hotspot = isHotspot,
    }
end

function TerrainNoise.SampleFromWorldPosition(position: Vector3)
    local size = tileCfg.TileSize
    local tileX = math.floor(position.X / size + 0.5)
    local tileZ = math.floor(position.Z / size + 0.5)
    local sample = TerrainNoise.Sample(tileX, tileZ)
    sample.tileX = tileX
    sample.tileZ = tileZ
    return sample
end

function TerrainNoise.ShouldPlace(tileX, tileZ, chance, salt)
    if chance <= 0 then
        return false
    end
    return hash01(tileX, tileZ, salt or 0) < chance
end

return TerrainNoise
