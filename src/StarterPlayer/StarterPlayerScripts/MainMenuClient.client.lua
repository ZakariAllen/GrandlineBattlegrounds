-- StarterPlayerScripts > MainMenuClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- 🧩 Clone MainMenu UI if missing
local function ensureUI(name)
	local existing = PlayerGui:FindFirstChild(name)
	if existing then return existing end

    local template = ReplicatedFirst
        :WaitForChild("Assets")
        :WaitForChild(name)
	local clone = template:Clone()
	clone.Name = name
	clone.Parent = PlayerGui
	return clone
end

local menuUI = ensureUI("MainMenu")
menuUI.Enabled = false

local transitionUI = ensureUI("TransitionScreen")
local background = transitionUI:WaitForChild("Background")
local textLabel = background:WaitForChild("Text")

-- 🔁 Module Configs
local MenuCfgs        = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MenuCfgs")
local MenuLogic       = require(MenuCfgs:WaitForChild("MenuLogic"))
local CameraManager   = require(MenuCfgs:WaitForChild("CameraManager"))
local MenuGlobalCfg   = require(MenuCfgs:WaitForChild("MenuGlobalCfg"))
local PlayerGuiManager = require(ReplicatedStorage.Modules.Client.PlayerGuiManager)
local MusicManager    = require(ReplicatedStorage.Modules.Client.MusicManager)
PlayerGuiManager.Hide()

-- 🔁 Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SystemRemotes = Remotes:WaitForChild("System")
local UIRemotes = Remotes:WaitForChild("UI") -- Corrected remote folder for UI events

local SpawnRequestEvent = SystemRemotes:WaitForChild("SpawnRequestEvent")
local PlayerEnteredMenu = UIRemotes:WaitForChild("PlayerEnteredMenu")  -- Moved here from System
local PlayerLeftMenu    = UIRemotes:WaitForChild("PlayerLeftMenu")    -- Moved here from System
local ReturnToMenuEvent = UIRemotes:WaitForChild("ReturnToMenuEvent") -- Correct

-- 🧩 Enable or disable menu buttons
local function setButtonsEnabled(enabled)
	local function apply(container)
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("GuiButton") then
				child.Active = enabled
				child.AutoButtonColor = enabled
				child.Visible = enabled
			end
		end
	end
	apply(menuUI.MainMenuFrame.MainMenuBG)
    apply(menuUI.SelectionFrame.FightingStyles.StyleList)
end

-- 🔁 Transition screen
local function showTransitionScreen(message)
	textLabel.Text = message or "Loading..."
	transitionUI.Enabled = true
	background.BackgroundTransparency = 1
	textLabel.TextTransparency = 1

	TweenService:Create(background, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
	TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
end

local function hideTransitionScreen()
	TweenService:Create(background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	task.wait(0.5)
	transitionUI.Enabled = false
end

-- 🧍 Character spawn + camera follow
local function spawnAndFollow(toolName)
	showTransitionScreen("Spawning character...")

	local duration = MenuGlobalCfg.TransitionScreen and MenuGlobalCfg.TransitionScreen.Duration or 1
	task.delay(duration, hideTransitionScreen)

        PlayerLeftMenu:FireServer()
        SpawnRequestEvent:FireServer(toolName)
        MenuLogic.HideMenu()
        setButtonsEnabled(false)

        player.CharacterAdded:Wait()
	task.wait(0.25)

	local char = player.Character
	if not char then
		warn("[MainMenuClient] Character failed to spawn!")
		return
	end

        local humanoid = char:WaitForChild("Humanoid")
        local hrp = char:WaitForChild("HumanoidRootPart")

        PlayerGuiManager.BindHumanoid(humanoid)
        local stam = player:FindFirstChild("Stamina") or player:WaitForChild("Stamina", 5)
        if stam then
                PlayerGuiManager.BindStamina(stam)
        end
        local hakiVal = player:FindFirstChild("Haki") or player:WaitForChild("Haki", 5)
        if hakiVal then
                PlayerGuiManager.BindHaki(hakiVal)
        end
        local ultVal = player:FindFirstChild("Ult") or player:WaitForChild("Ult", 5)
        if ultVal then
                PlayerGuiManager.BindUlt(ultVal)
        end
        local evasiveVal = player:FindFirstChild("Evasive") or player:WaitForChild("Evasive", 5)
        if evasiveVal then
                PlayerGuiManager.BindEvasive(evasiveVal)
        end
        PlayerGuiManager.Show()

	local camera = workspace.CurrentCamera
	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
	camera.CFrame = hrp.CFrame * CFrame.new(0, 5, 10)

	CameraManager.ClearMenuCamera()

	-- 🔄 Enforce camera following for a short time
	local startTime = tick()
	local conn
        conn = RunService.RenderStepped:Connect(function()
                if tick() - startTime > 2 then
                        conn:Disconnect()
                else
                        camera.CameraSubject = humanoid
                        camera.CameraType = Enum.CameraType.Custom
                end
        end)

        MusicManager.StartGameplayMusic()
        setButtonsEnabled(true)
end

-- 🎬 Initialize main menu
local function initMainMenu()
        print("[MainMenuClient] Initializing Main Menu")
    CameraManager.ApplyMenuCamera()
        PlayerGuiManager.Hide()
        setButtonsEnabled(true)
        MusicManager.PlayMenuMusic()
        PlayerEnteredMenu:FireServer()

	MenuLogic.ShowMainMenu(function(toolName)
		spawnAndFollow(toolName)
	end)
end

-- ⏮ Return to menu
ReturnToMenuEvent.OnClientEvent:Connect(function()
        showTransitionScreen("Returning to menu...")
        PlayerGuiManager.Hide()
        setButtonsEnabled(false)

        local duration = MenuGlobalCfg.TransitionScreen and MenuGlobalCfg.TransitionScreen.Duration or 1
        task.delay(duration, function()
                CameraManager.ClearMenuCamera()
                task.wait(0.1)
                CameraManager.ApplyMenuCamera()
                MusicManager.PlayMenuMusic()
                initMainMenu()
                hideTransitionScreen()
        end)
end)

-- 🚀 Begin game once ReplicatedFirst signals that assets are loaded
-- Wait indefinitely for the LoadingFinished flag to ensure all assets are
-- preloaded before showing the main menu
local flag = ReplicatedFirst:WaitForChild("LoadingFinished")
if flag then
    if flag.Value == false then
        flag.Changed:Wait()
    end
end
initMainMenu()
