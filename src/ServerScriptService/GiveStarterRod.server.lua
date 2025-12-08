local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RodConfig = require(Modules.Fishing:WaitForChild("RodConfig"))

local DEFAULT_ROD_ID = "Wayfinder"

local function buildRod(rodId: string)
    local rodDef = RodConfig[rodId]
    if not rodDef then
        return nil
    end
    local tool = Instance.new("Tool")
    tool.Name = rodDef.displayName or rodId
    tool.ToolTip = rodDef.description or "Fishing rod"
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.ManualActivationOnly = true
    tool:SetAttribute("RodId", rodId)
    return tool
end

local function giveRod(player: Player)
    local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
    local starterGear = player:FindFirstChild("StarterGear") or player:WaitForChild("StarterGear", 5)
    if not backpack or not starterGear then
        return
    end

    local rodId = DEFAULT_ROD_ID
    local rodDef = RodConfig[rodId]
    if not rodDef then
        return
    end

    local function alreadyHasRod(container: Instance): boolean
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and child:GetAttribute("RodId") == rodId then
                return true
            end
        end
        return false
    end

    if not alreadyHasRod(backpack) then
        local rod = buildRod(rodId)
        if rod then
            rod.Parent = backpack
        end
    end
    if not alreadyHasRod(starterGear) then
        local rod = buildRod(rodId)
        if rod then
            rod.Parent = starterGear
        end
    end
end

local function onPlayerAdded(player: Player)
    giveRod(player)
    player.CharacterAdded:Connect(function()
        giveRod(player)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
