--ReplicatedStorage.Modules.MenuCfgs.LoadingManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local MenuGlobalCfg = require(ReplicatedStorage.Modules.MenuCfgs.MenuGlobalCfg)

-- ✅ Correct RemoteEvent path using 'UI'
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UI = Remotes:WaitForChild("UI") -- Correct name is "UI"
local PlayerEnteredMenu = UI:WaitForChild("PlayerEnteredMenu")

local LoadingManager = {}

function LoadingManager.BeginLoading(onComplete)
	print("[LoadingManager] Starting loading screen")

    local loadingTemplate = ReplicatedFirst:WaitForChild("Assets"):WaitForChild("LoadingScreen")
	local config = MenuGlobalCfg.LoadingScreen
	local duration = config.Duration

	local CameraManager = require(ReplicatedStorage.Modules.MenuCfgs.CameraManager)
	CameraManager.ApplyMenuCamera()

	-- Setup UI
	local flag = Instance.new("BoolValue")
	flag.Name = "LoadingFinished"
	flag.Value = false
	flag.Parent = PlayerGui

	local gui = loadingTemplate:Clone()
	gui.Name = "LoadingScreen"
	gui.Enabled = true
	gui.Parent = PlayerGui

	local background = gui:WaitForChild("Background")
	local loadingText = background:WaitForChild("LoadingText")
	local spinner = background:FindFirstChild("Spinner")

	background.BackgroundColor3      = config.BackgroundColor
	background.BackgroundTransparency = config.BackgroundTransparency
	background.Size                  = config.BackgroundSize
	background.Position              = config.BackgroundPosition
	background.AnchorPoint           = config.BackgroundAnchorPoint
	background.BorderSizePixel       = config.BackgroundBorderSize

	loadingText.Text        = config.Text
	loadingText.TextColor3  = config.TextColor
	loadingText.TextSize    = config.TextSize
	loadingText.Font        = config.Font
	loadingText.Position    = config.TextOffset

	if spinner and config.SpinnerAssetId and config.SpinnerSize then
		spinner.Image = config.SpinnerAssetId
		spinner.Size = config.SpinnerSize
	end

	print("[LoadingManager] Waiting", duration, "seconds...")
	task.delay(duration, function()
		print("[LoadingManager] Fading out loading screen...")

		local tweenInfo = TweenInfo.new(0.5)
		TweenService:Create(background, tweenInfo, {BackgroundTransparency = 1}):Play()
		TweenService:Create(loadingText, tweenInfo, {TextTransparency = 1}):Play()
		if spinner then
			TweenService:Create(spinner, tweenInfo, {ImageTransparency = 1}):Play()
		end

		task.delay(0.6, function()
			gui:Destroy()
			local blur = Lighting:FindFirstChild("MainMenuBlur")
			if blur then blur:Destroy() end
			flag.Value = true

			-- ✅ Notify server: player is in menu
			PlayerEnteredMenu:FireServer()

			if typeof(onComplete) == "function" then
				print("[LoadingManager] Loading complete. Proceeding to menu...")
				onComplete()
			end
		end)
	end)
end

return LoadingManager
