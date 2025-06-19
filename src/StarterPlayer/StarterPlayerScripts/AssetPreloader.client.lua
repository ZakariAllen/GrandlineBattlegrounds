-- StarterPlayerScripts > AssetPreloader

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
-- Load current config modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Cfg = Modules:WaitForChild("Config")
local Animations = Modules:WaitForChild("Animations")
local MovementModules = Modules:WaitForChild("Movement")

local SoundConfig = require(Cfg:WaitForChild("SoundConfig"))
local DashConfig = require(MovementModules:WaitForChild("DashConfig"))
local DashVFX = require(ReplicatedStorage.Modules.Effects.DashVFX)
local CombatAnimations = require(Animations:WaitForChild("Combat"))
local MovementAnimations = require(Animations:WaitForChild("Movement"))
local ToolAnimations = require(Animations:WaitForChild("Tool"))

-- List of asset IDs to preload. Use a set table to avoid duplicates
local assets = {}
local seen = {}

-- Utility: Determines if an ID is valid for preloading
local function isValidAssetId(id)
    if typeof(id) ~= "string" then return false end
    if id == "" then return false end
    if id == "rbxassetid://" then return false end
    if id:lower():find("placeholder") then return false end
    if not id:match("^rbxassetid://%d+$") then return false end
    return true
end

local function addAsset(id)
    if not seen[id] and isValidAssetId(id) then
        seen[id] = true
        table.insert(assets, id)
    end
end

-- 🔊 Preload all valid sound IDs from SoundConfig
for _, category in pairs(SoundConfig) do
    for _, soundInfo in pairs(category) do
        local id = typeof(soundInfo) == "table" and soundInfo.Id or soundInfo
        addAsset(id)
    end
end

-- Dash sound from DashConfig
local dashId = typeof(DashConfig.Sound) == "table" and DashConfig.Sound.Id or DashConfig.Sound
addAsset(dashId)

-- Dash VFX texture
addAsset(DashVFX.WIND_TEXTURE)

-- Power Punch VFX texture
local POWER_PUNCH_TEXTURE = "rbxassetid://14049479051"
addAsset(POWER_PUNCH_TEXTURE)

-- 🎞️ Helper: Recursively collect animation IDs
local function collectAnimationsFrom(tbl)
    for _, v in pairs(tbl) do
        if typeof(v) == "string" then
            addAsset(v)
        elseif typeof(v) == "table" then
            collectAnimationsFrom(v)
        end
    end
end

-- 🎞️ Preload animation IDs from all modules
collectAnimationsFrom(CombatAnimations)
collectAnimationsFrom(MovementAnimations)
collectAnimationsFrom(ToolAnimations)

-- 🧠 Preload all assets
print("[AssetPreloader] Preloading", #assets, "assets...")
ContentProvider:PreloadAsync(assets)

print("[AssetPreloader] All valid assets preloaded successfully.")
