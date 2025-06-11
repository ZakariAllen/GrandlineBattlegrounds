-- This script replaces Roblox's default loading screen with a custom one and
-- preloads important assets before the main menu runs.  It is executed from
-- `ReplicatedFirst` so it runs as early as possible on the client.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

-- Remove the default Roblox loading screen immediately
ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clone the LoadingScreen UI stored under this script
local template = script:WaitForChild("LoadingScreen")
local loadingGui = template:Clone()
loadingGui.Parent = playerGui

local background = loadingGui:WaitForChild("Background")
local loadingText = background:WaitForChild("LoadingText")
local assetName = background:WaitForChild("AssetNames")
local loadBar = background
    :WaitForChild("LoadBarBG")
    :WaitForChild("LoadBar")

-- Gather all assets from ReplicatedFirst that should be preloaded
local function gather(folder, list)
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("Decal")
            or obj:IsA("Texture")
            or obj:IsA("ImageLabel")
            or obj:IsA("ImageButton")
            or obj:IsA("ParticleEmitter")
            or obj:IsA("Sound")
            or obj:IsA("Animation") then
            table.insert(list, obj)
        end
    end
end

local assetsToLoad = {}
local assetsFolder = ReplicatedFirst:FindFirstChild("Assets")
if assetsFolder then
    gather(assetsFolder, assetsToLoad)
end

local vfxFolder = ReplicatedFirst:FindFirstChild("VFX")
if vfxFolder then
    gather(vfxFolder, assetsToLoad)
end

-- Preload each asset while updating the progress bar
local total = #assetsToLoad
for i, asset in ipairs(assetsToLoad) do
    assetName.Text = asset.Name
    ContentProvider:PreloadAsync({asset})
    loadBar.Size = UDim2.new(i / total, 0, 1, 0)
end

-- Fade out once finished
local tweenInfo = TweenInfo.new(0.5)
TweenService:Create(background, tweenInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(loadingText, tweenInfo, {TextTransparency = 1}):Play()
TweenService:Create(assetName, tweenInfo, {TextTransparency = 1}):Play()
TweenService:Create(loadBar, tweenInfo, {BackgroundTransparency = 1}):Play()
local bgImage = background:FindFirstChild("BackgroundImage")
if bgImage then
    TweenService:Create(bgImage, tweenInfo, {ImageTransparency = 1}):Play()
end

task.wait(0.6)
loadingGui:Destroy()

-- Signal to other scripts that loading has finished
local flag = Instance.new("BoolValue")
flag.Name = "LoadingFinished"
flag.Value = true
flag.Parent = ReplicatedFirst
