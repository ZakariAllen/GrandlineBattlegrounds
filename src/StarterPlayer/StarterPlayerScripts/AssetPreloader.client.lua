-- StarterPlayerScripts > AssetPreloader

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Load current config modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Cfg = Modules:WaitForChild("Config")
local Animations = Modules:WaitForChild("Animations")
local MovementModules = Modules:WaitForChild("Movement")

local SoundConfig = require(Cfg:WaitForChild("SoundConfig"))
local MoveSoundConfig = require(Cfg:WaitForChild("MoveSoundConfig"))
local DashConfig = require(MovementModules:WaitForChild("DashConfig"))
local DashVFX = require(ReplicatedStorage.Modules.Effects.DashVFX)
local CombatAnimations = require(Animations:WaitForChild("Combat"))
local MovementAnimations = require(Animations:WaitForChild("Movement"))
local ToolAnimations = require(Animations:WaitForChild("Tool"))

local assets = {}

-- Utility: Determines if an ID is valid for preloading
local function isValidAssetId(id)
	if typeof(id) ~= "string" then return false end
	if id == "" then return false end
	if id == "rbxassetid://" then return false end
	if id:lower():find("placeholder") then return false end
	if not id:match("^rbxassetid://%d+$") then return false end
	return true
end

-- 🔊 Preload all valid sound IDs from SoundConfig
for _, category in pairs(SoundConfig) do
        for _, soundId in pairs(category) do
                if isValidAssetId(soundId) then
                        local sound = Instance.new("Sound")
                        sound.SoundId = soundId
                        sound.Parent = PlayerGui
                        table.insert(assets, sound)
                end
        end
end

-- 🔊 Preload move-specific sound IDs
for _, move in pairs(MoveSoundConfig) do
       for _, soundId in pairs(move) do
               if isValidAssetId(soundId) then
                       local sound = Instance.new("Sound")
                       sound.SoundId = soundId
                       sound.Parent = PlayerGui
                       table.insert(assets, sound)
               end
       end
end

-- Dash sound from DashConfig
if isValidAssetId(DashConfig.SoundId) then
        local ds = Instance.new("Sound")
        ds.SoundId = DashConfig.SoundId
        ds.Parent = PlayerGui
        table.insert(assets, ds)
end

-- Dash VFX texture
if isValidAssetId(DashVFX.WIND_TEXTURE) then
        local pe = Instance.new("ParticleEmitter")
        pe.Texture = DashVFX.WIND_TEXTURE
        pe.Parent = PlayerGui
        table.insert(assets, pe)
end

-- 🎞️ Helper: Recursively collect animation IDs
local function collectAnimationsFrom(tbl)
	for _, v in pairs(tbl) do
		if typeof(v) == "string" and isValidAssetId(v) then
			local anim = Instance.new("Animation")
			anim.AnimationId = v
			table.insert(assets, anim)
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

-- 🧹 Clean up
for _, asset in ipairs(assets) do
        if asset:IsA("Sound") or asset:IsA("Animation") or asset:IsA("ParticleEmitter") then
                asset:Destroy()
        end
end

print("[AssetPreloader] All valid assets preloaded successfully.")
