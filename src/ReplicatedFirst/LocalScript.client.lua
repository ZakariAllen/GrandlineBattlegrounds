--EXAMPLE CODE I FOUND ONLINE THAT WILL NOT WORK WITH MY GAME CURRENTLY

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local loadingScreen = script:WaitForChild("LoadingScreen"):Clone()
loadingScreen.Parent = playerGui

local frame = loadingScreen:WaitForChild("Frame")
local loadingText = frame:WaitForChild("TextLabel")
local bar = frame:WaitForChild("LoadingBar"):WaitForChild("Bar")

local assets = game:GetChildren()

for index, asset in pairs(assets) do
	loadingText.Text = "Loading " .. asset.Name .. "..."
	ContentProvider:PreloadAsync({asset})

	local progress = index / #assets
	bar.Size = UDim2.new(progress, 0, 1, 0)
end