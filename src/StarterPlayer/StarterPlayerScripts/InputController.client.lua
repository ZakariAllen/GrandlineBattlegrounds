-- InputController.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config.Config)
local DEBUG = Config.GameSettings.DebugEnabled

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Track when a TextBox (like the chat bar) is focused so inputs aren't
-- processed while the player is typing.
local typingInChat = false
UserInputService.TextBoxFocused:Connect(function()
    typingInChat = true
end)
UserInputService.TextBoxFocusReleased:Connect(function()
    typingInChat = false
end)

-- 🔁 Client Modules
local M1InputClient = require(ReplicatedStorage.Modules.Combat.M1InputClient)
local DashClient = require(ReplicatedStorage.Modules.Movement.DashClient) -- updated path: Movement folder
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)

local MovesFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Combat"):WaitForChild("Moves")
local Moves = require(MovesFolder:WaitForChild("MovesConfig"))
if DEBUG then
    print("[InputController] Loaded moves:", #Moves)
end

-- 🔁 Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Stun = Remotes:WaitForChild("Stun") -- Confirmed no "Remotes" suffix in folder name

local StunStatusEvent = Stun:WaitForChild("StunStatusRequestEvent")

-- Update stun status using the provided helper instead of overwriting the API
StunStatusEvent.OnClientEvent:Connect(function(data)
        StunStatusClient.SetStatus(data.Stunned, data.AttackerLock)
end)

-- 🔗 Tool event connection
local function connectToolEvents(tool)
	print("[InputController] Connecting tool:", tool.Name)
	ToolController.SetEquippedTool(tool)

	tool.Equipped:Connect(function()
		ToolController.SetEquippedTool(tool)
	end)

	tool.Unequipped:Connect(function()
		ToolController.SetEquippedTool(nil)
	end)
end

-- 🔁 Detect tools added/removed from character
local function setupToolDetection(char)
        if DEBUG then
                print("[InputController] Setting up tool detection for", char.Name)
        end
        for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Tool") then
                        connectToolEvents(child)
                end
	end

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			connectToolEvents(child)
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			ToolController.SetEquippedTool(nil)
		end
	end)
end

-- 👤 Character listener
player.CharacterAdded:Connect(setupToolDetection)
if player.Character then
	setupToolDetection(player.Character)
end

-- 🕹️ Route all input through controllers
UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local typing = typingInChat or UserInputService:GetFocusedTextBox() ~= nil
        if typing then
                return
        end
        gameProcessed = gameProcessed or typing
        if DEBUG and input.UserInputType == Enum.UserInputType.Keyboard then
                print("[InputController] InputBegan:", input.KeyCode.Name, "GP:", gameProcessed)
        end
        M1InputClient.OnInputBegan(input, gameProcessed)
        DashClient.OnInputBegan(input, gameProcessed)
        BlockClient.OnInputBegan(input, gameProcessed)
        MovementClient.OnInputBegan(input, gameProcessed)
        for _, move in ipairs(Moves) do
                if move.OnInputBegan then
                        move.OnInputBegan(input, gameProcessed)
                end
        end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
        local typing = typingInChat or UserInputService:GetFocusedTextBox() ~= nil
        if typing then
                return
        end
        gameProcessed = gameProcessed or typing
        if DEBUG and input.UserInputType == Enum.UserInputType.Keyboard then
                print("[InputController] InputEnded:", input.KeyCode.Name, "GP:", gameProcessed)
        end
        M1InputClient.OnInputEnded(input, gameProcessed)
        DashClient.OnInputEnded(input, gameProcessed)
        BlockClient.OnInputEnded(input, gameProcessed)
        MovementClient.OnInputEnded(input, gameProcessed)
        for _, move in ipairs(Moves) do
                if move.OnInputEnded then
                        move.OnInputEnded(input, gameProcessed)
                end
        end
end)

if DEBUG then print("[InputController] Initialized") end
