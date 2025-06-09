-- ReplicatedStorage > Modules > MenuCfgs > MenuLogic.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundServiceUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local ButtonCfg = require(ReplicatedStorage.Modules.MenuCfgs.ButtonCfg)

local MainMenu = PlayerGui:WaitForChild("MainMenu")
local MainMenuFrame = MainMenu:WaitForChild("MainMenuFrame")
local MainMenuBG = MainMenuFrame:WaitForChild("MainMenuBG")
local SelectionFrame = MainMenu:WaitForChild("SelectionFrame")
local StyleList = SelectionFrame
    :WaitForChild("FightingStyles")
    :WaitForChild("StyleList")
local ShopFrame = MainMenu:WaitForChild("ShopFrame")
local ShopBG = ShopFrame:WaitForChild("ShopBG")

local MenuLogic = {}
local toolSelectedCallback

local mainMenuWired = false
local selectionWired = false
local shopWired = false

-- Helper to find a button by name in a container
local function safeGet(container, name)
	return container:FindFirstChild(name)
end

-- Generic button connector
local function wireGenericButtons(cfgList, container, callback)
        local defaultHover = SoundConfig.UI.Hover
        local defaultClick = SoundConfig.UI.Click

        for _, btnCfg in ipairs(cfgList) do
                local btn = safeGet(container, btnCfg.Name)
                if btn then
                        local hoverSound = btnCfg.HoverSound or defaultHover
                        local clickSound = btnCfg.ClickSound or defaultClick

                        btn.MouseEnter:Connect(function()
                                SoundServiceUtils:PlayLocalSound(hoverSound)
                        end)

                        btn.MouseButton1Click:Connect(function()
                                SoundServiceUtils:PlayLocalSound(clickSound)
                                if callback then
                                        callback(btnCfg.Name:match("%- (.+)$") or btnCfg.Name)
                                end
                        end)
                end
        end
end

local function wireMainMenuButtons()
        if mainMenuWired then return end
        mainMenuWired = true

        local defaultHover = SoundConfig.UI.Hover
        local defaultClick = SoundConfig.UI.Click

        local function connect(btn, cfg, onClick)
                if not btn then return end

                local hoverSound = cfg.HoverSound or defaultHover
                local clickSound = cfg.ClickSound or defaultClick

                btn.MouseEnter:Connect(function()
                        SoundServiceUtils:PlayLocalSound(hoverSound)
                end)

                btn.MouseButton1Click:Connect(function()
                        SoundServiceUtils:PlayLocalSound(clickSound)
                        if onClick then onClick() end
                end)
        end

        local playBtn      = safeGet(MainMenuBG, "1 - Play")
        local customizeBtn = safeGet(MainMenuBG, "2 - Customize")
        local shopBtn      = safeGet(MainMenuBG, "3 - Shop")
        local settingsBtn  = safeGet(MainMenuBG, "4 - Settings")

        connect(playBtn, ButtonCfg.MainMenu[1], function()
                MenuLogic.ShowToolSelection(toolSelectedCallback)
        end)

        connect(customizeBtn, ButtonCfg.MainMenu[2], function()
                print("[MenuLogic] Customize clicked (placeholder)")
        end)

        connect(shopBtn, ButtonCfg.MainMenu[3], function()
                MenuLogic.ShowShopMenu()
        end)

        connect(settingsBtn, ButtonCfg.MainMenu[4], function()
                print("[MenuLogic] Settings clicked (placeholder)")
        end)
end

local function wireSelectionButtons()
	if selectionWired then return end
	selectionWired = true

    wireGenericButtons(ButtonCfg.Selection, StyleList, function(toolName)
		SelectionFrame.Visible = false
		if toolSelectedCallback then
			toolSelectedCallback(toolName)
		end
	end)
end

local function wireShopButtons()
	if shopWired then return end
	shopWired = true

	wireGenericButtons(ButtonCfg.Shop, ShopBG, function(categoryName)
		print("[MenuLogic] Shop category selected:", categoryName)
		-- Future: Open shop panel for selected category
	end)
end

function MenuLogic.ShowMainMenu(toolSelectedFunc)
	MainMenu.Enabled = true
	MainMenuFrame.Visible = true
	SelectionFrame.Visible = false
	ShopFrame.Visible = false
	toolSelectedCallback = toolSelectedFunc

	wireMainMenuButtons()
end

function MenuLogic.ShowToolSelection(toolSelectedFunc)
	MainMenuFrame.Visible = false
	SelectionFrame.Visible = true
	ShopFrame.Visible = false
	toolSelectedCallback = toolSelectedFunc

	wireSelectionButtons()
end

function MenuLogic.ShowShopMenu()
	MainMenuFrame.Visible = false
	SelectionFrame.Visible = false
	ShopFrame.Visible = true

	wireShopButtons()
end

function MenuLogic.HideMenu()
	MainMenuFrame.Visible = false
	SelectionFrame.Visible = false
	ShopFrame.Visible = false
end

return MenuLogic
