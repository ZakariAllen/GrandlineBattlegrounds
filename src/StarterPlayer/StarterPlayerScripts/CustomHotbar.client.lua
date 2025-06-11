
--[[
    This hotbar only changes the visual interface. The actual Tool
    instances in the Backpack still control equipping, unequipping and
    LocalScript execution. Buttons simply move Tools between the Backpack
    and Character just like the default Roblox hotbar.
]]

-- StarterPlayerScripts > CustomHotbar

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

-- Hide the default backpack UI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Clone hotbar template from ReplicatedFirst.Assets
local assets = ReplicatedFirst:WaitForChild("Assets")
local template = assets:WaitForChild("CustomHotbar")

local hotbar = template:Clone()
hotbar.ResetOnSpawn = false
hotbar.Parent = PlayerGui

local toolSelected = hotbar:FindFirstChild("ToolSelected")
if toolSelected then
    toolSelected.Visible = false
end

local basicButton = hotbar:WaitForChild("BasicCombat")
local blackButton = hotbar:WaitForChild("BlackLeg")
local rokuButton = hotbar:FindFirstChild("Rokushiki")

-- Display only the button for the player's current tool
local function updateVisibleButton()
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character

    local hasBasic = (backpack and backpack:FindFirstChild("BasicCombat"))
        or (character and character:FindFirstChild("BasicCombat"))
    local hasBlack = (backpack and backpack:FindFirstChild("BlackLeg"))
        or (character and character:FindFirstChild("BlackLeg"))
    local hasRoku = rokuButton and ((backpack and backpack:FindFirstChild("Rokushiki"))
        or (character and character:FindFirstChild("Rokushiki")))

    basicButton.Visible = not not hasBasic
    blackButton.Visible = not not hasBlack
    if rokuButton then
        rokuButton.Visible = not not hasRoku
    end
end

local function updateSelected()
    if not toolSelected then return end
    local character = player.Character
    if not character then
        toolSelected.Visible = false
        return
    end
    local tool = character:FindFirstChildWhichIsA("Tool")
    if tool then
        local button = hotbar:FindFirstChild(tool.Name)
        if button and button:IsA("GuiObject") then
            toolSelected.Position = button.Position
            toolSelected.Size = button.Size
            toolSelected.Visible = true
            return
        end
    end
    toolSelected.Visible = false
end

updateVisibleButton()
updateSelected()
local function connectCharacter(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            updateVisibleButton()
            updateSelected()
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            updateVisibleButton()
            updateSelected()
        end
    end)
    updateSelected()
end

player.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    connectCharacter(char)
    updateVisibleButton()
    updateSelected()
end)

if player.Character then
    connectCharacter(player.Character)
    updateSelected()
end

player:WaitForChild("Backpack").ChildAdded:Connect(updateVisibleButton)
player.Backpack.ChildRemoved:Connect(updateVisibleButton)

print("[CustomHotbar] Initialized")

-- Moving tools between Backpack and Character ensures Roblox still
-- runs any LocalScripts and animations associated with the Tool.
local function toggleTool(toolName)
    local backpack = player:WaitForChild("Backpack")
    local character = player.Character or player.CharacterAdded:Wait()

    -- Already equipped -> move back to backpack
    local equipped = character:FindFirstChild(toolName)
    if equipped and equipped:IsA("Tool") then
        equipped.Parent = backpack
        updateSelected()
        return
    end

    -- Unequip any other equipped tools
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Tool") then
            obj.Parent = backpack
        end
    end

    -- Equip requested tool if present
    local tool = backpack:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then
        tool.Parent = character
    end

    updateVisibleButton()
    updateSelected()
end

-- Button handlers
hotbar:WaitForChild("BasicCombat").MouseButton1Click:Connect(function()
    toggleTool("BasicCombat")
end)

hotbar:WaitForChild("BlackLeg").MouseButton1Click:Connect(function()
    toggleTool("BlackLeg")
end)

if rokuButton then
    rokuButton.MouseButton1Click:Connect(function()
        toggleTool("Rokushiki")
    end)
end

-- Pressing 1 equips the first available tool, mirroring the default behaviour
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.One then
        local backpack = player:WaitForChild("Backpack")
        local preferred = "BasicCombat"
        if not backpack:FindFirstChild(preferred) and not (player.Character and player.Character:FindFirstChild(preferred)) then
            preferred = "BlackLeg"
            if not backpack:FindFirstChild(preferred) and not (player.Character and player.Character:FindFirstChild(preferred)) then
                preferred = "Rokushiki"
            end
        end
        toggleTool(preferred)
    end
end)

