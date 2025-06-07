--ReplicatedStorage.Modules.UI.OverheadBarService

local OverheadBarService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStats = require(ReplicatedStorage.Modules.Config.PlayerStats)

local assets = ReplicatedStorage:WaitForChild("Assets")
local healthTemplate = assets:WaitForChild("HealthBar")
local blockTemplate = assets:WaitForChild("BlockBar")
local tekkaiTemplate = assets:FindFirstChild("TekkaiBar")

local barInfo = {} --[player] = {healthFrame, healthBase, blockGui, blockFrame, blockBase, tekkaiGui, tekkaiFrame, tekkaiBase}

-- Forward declare to allow usage before definition
local onCharacterAdded

local function updateHealth(player, humanoid)
    local info = barInfo[player]
    if not info then return end
    local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local base = info.healthBase
    info.healthFrame.Size = UDim2.new(
        base.X.Scale * ratio,
        base.X.Offset * ratio,
        base.Y.Scale,
        base.Y.Offset
    )
end

function OverheadBarService.UpdateBlock(player, hp)
    local info = barInfo[player]
    if not info and player and player.Character then
        onCharacterAdded(player, player.Character)
        info = barInfo[player]
    end
    if not info then return end
    local ratio = math.clamp(hp / PlayerStats.BlockHP, 0, 1)
    local base = info.blockBase
    info.blockFrame.Size = UDim2.new(
        base.X.Scale * ratio,
        base.X.Offset * ratio,
        base.Y.Scale,
        base.Y.Offset
    )
end

function OverheadBarService.SetBlockActive(player, active)
    local info = barInfo[player]
    if not info and player and player.Character then
        onCharacterAdded(player, player.Character)
        info = barInfo[player]
    end
    if info and info.blockGui then
        info.blockGui.Enabled = active
    end
end

function OverheadBarService.UpdateTekkai(player, hp, max)
    local info = barInfo[player]
    if not info and player and player.Character then
        onCharacterAdded(player, player.Character)
        info = barInfo[player]
    end
    if not info or not info.tekkaiFrame then return end
    max = max or PlayerStats.BlockHP
    local ratio = math.clamp(hp / max, 0, 1)
    local base = info.tekkaiBase
    info.tekkaiFrame.Size = UDim2.new(
        base.X.Scale * ratio,
        base.X.Offset * ratio,
        base.Y.Scale,
        base.Y.Offset
    )
end

function OverheadBarService.SetTekkaiActive(player, active)
    local info = barInfo[player]
    if not info and player and player.Character then
        onCharacterAdded(player, player.Character)
        info = barInfo[player]
    end
    if info and info.tekkaiGui then
        info.tekkaiGui.Enabled = active
    end
end

function onCharacterAdded(player, char)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not hrp or not humanoid then return end

    -- Hide the default Roblox health bar so only the custom bar is visible
    pcall(function()
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end)

    local healthGui = healthTemplate:Clone()
    healthGui.Name = "HealthBillboard"
    healthGui.Adornee = hrp
    pcall(function()
        healthGui.PlayerToHideFrom = player
    end)
    healthGui.Parent = char

    local healthFrame = healthGui:WaitForChild("BarBGMiddle"):WaitForChild("HealthBar")
    local healthBase = healthFrame.Size

    local blockGui = blockTemplate:Clone()
    blockGui.Name = "BlockBillboard"
    blockGui.Adornee = hrp
    blockGui.Enabled = false
    blockGui.Parent = char

    local blockFrame = blockGui:WaitForChild("BarBGMiddle"):WaitForChild("BlockBar")
    local blockBase = blockFrame.Size

    local tekkaiGui
    local tekkaiFrame
    local tekkaiBase
    if tekkaiTemplate then
        tekkaiGui = tekkaiTemplate:Clone()
        tekkaiGui.Name = "TekkaiBillboard"
        tekkaiGui.Adornee = hrp
        tekkaiGui.Enabled = false
        tekkaiGui.Parent = char

        tekkaiFrame = tekkaiGui:WaitForChild("BarBGMiddle"):WaitForChild("TekkaiBar")
        tekkaiBase = tekkaiFrame.Size
    end

    barInfo[player] = {
        healthFrame = healthFrame,
        healthBase = healthBase,
        blockGui = blockGui,
        blockFrame = blockFrame,
        blockBase = blockBase,
        tekkaiGui = tekkaiGui,
        tekkaiFrame = tekkaiFrame,
        tekkaiBase = tekkaiBase,
    }

    updateHealth(player, humanoid)
    humanoid.HealthChanged:Connect(function()
        updateHealth(player, humanoid)
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        onCharacterAdded(p, p.Character)
    end
end

Players.PlayerRemoving:Connect(function(player)
    barInfo[player] = nil
end)

return OverheadBarService
