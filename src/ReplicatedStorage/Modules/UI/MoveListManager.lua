--ReplicatedStorage.Modules.UI.MoveListManager

local MoveListManager = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- add default keybinds including Q, F and J which are universal
local keys = {"C","Z","X","T","R","E","Q","F","J"}
local entries = {}

local function populateEntries()
    local screenGui = playerGui:FindFirstChild("PlayerGUI")
    if not screenGui then return end
    local moveList = screenGui:FindFirstChild("MoveList")
    if not moveList then return end

    for _, key in ipairs(keys) do
        if not entries[key] then
            local container = moveList:FindFirstChild(key)
            if not container then
                local suffix = "-" .. key
                for _, child in ipairs(moveList:GetChildren()) do
                    if child.Name:sub(-#suffix) == suffix then
                        container = child
                        break
                    end
                end
            end
            if container then
                local bar = container:FindFirstChild("Cooldown")
                local timer = container:FindFirstChild("Timer")
                local move = container:FindFirstChild("Move")
                entries[key] = {
                    bar = bar,
                    timer = timer,
                    move = move,
                    base = bar and bar.Size,
                    color = move and move.TextColor3,
                }
            end
        end
    end
end

local function getEntry(letter)
    if not entries[letter] or entries[letter] and not entries[letter].bar then
        populateEntries()
    end
    return entries[letter]
end

function MoveListManager.StartCooldown(letter, duration)
    local entry = getEntry(letter)
    if not entry or not entry.bar then return end

    if entry.conn then
        entry.conn:Disconnect()
        entry.conn = nil
    end

    local bar = entry.bar
    local timer = entry.timer
    local move = entry.move
    local base = entry.base
    local defaultColor = entry.color

    if duration <= 0 then
        if bar then bar.Visible = false end
        if timer then timer.Text = "" end
        if move and defaultColor then move.TextColor3 = defaultColor end
        return
    end

    if move and defaultColor then
        move.TextColor3 = Color3.fromRGB(80, 0, 0) -- #500000
    end
    if bar then
        bar.Visible = true
        bar.Size = base
    end
    local endTime = tick() + duration

    entry.conn = RunService.RenderStepped:Connect(function()
        local remaining = endTime - tick()
        if remaining <= 0 then
            if bar then
                bar.Visible = false
                bar.Size = base
            end
            if timer then
                timer.Text = ""
            end
            if move and defaultColor then
                move.TextColor3 = defaultColor
            end
            entry.conn:Disconnect()
            entry.conn = nil
            return
        end
        local ratio = remaining / duration
        if timer then
            timer.Text = string.format("%.1f", remaining)
        end
        if bar then
            bar.Size = UDim2.new(
                base.X.Scale * ratio,
                base.X.Offset * ratio,
                base.Y.Scale,
                base.Y.Offset
            )
        end
    end)
end

return MoveListManager
