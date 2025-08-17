--ServerScriptService.AI.NPCController
-- Scans workspace.AI for NPC models and runs simple combat brains.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Time = require(ReplicatedStorage.Modules.Util.Time)
local Workspace = game:GetService("Workspace")

local AIConfig = require(ReplicatedStorage.Modules.Config.AIConfig)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local Blackboard = require(ReplicatedStorage.Modules.AI.Blackboard)
local Perception = require(ReplicatedStorage.Modules.AI.Perception)
local Decision = require(ReplicatedStorage.Modules.AI.Decision)
local ActionQueue = require(ReplicatedStorage.Modules.AI.ActionQueue)

local aiFolder = Workspace:WaitForChild("AI")

local styleKeys = {}
for k in pairs(ToolConfig.ValidCombatTools) do
    table.insert(styleKeys, k)
end

local function createTool(model, styleKey)
    local existing = model:FindFirstChild("_AI")
    if existing then
        existing:Destroy()
    end
    local folder = Instance.new("Folder")
    folder.Name = "_AI"
    folder.Parent = model

    local tool = Instance.new("Tool")
    tool.Name = styleKey
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.Parent = folder
end

local function bindNPC(model)
    local n = tonumber(model.Name:match("Enemy%s*%-%s*(%d+)")) or 1
    n = math.clamp(n, 1, 5)
    model:SetAttribute("AILevel", n)

    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        warn("[NPCController] Missing humanoid or HRP for", model:GetFullName())
        return
    end

    local styleKey = styleKeys[math.random(1, #styleKeys)] or "BasicCombat"
    model:SetAttribute("StyleKey", styleKey)
    createTool(model, styleKey)

    local bb = Blackboard.new(n, AIConfig.Levels[n])
    local queue = ActionQueue.new(model, bb)

    local running = true
    task.spawn(function()
        while running and model.Parent do
            Perception.Update(bb, model)
            bb.LastPerception = Time.now()
            task.wait(1 / AIConfig.PerceptionHz)
        end
    end)

    task.spawn(function()
        while running and model.Parent do
            Decision.Tick(model, bb, queue)
            queue:Run()
            task.wait(1 / AIConfig.DecisionHz)
        end
    end)

    local function cleanup()
        running = false
    end

    hum.Died:Connect(cleanup)
    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanup()
        end
    end)
end

for _, child in ipairs(aiFolder:GetChildren()) do
    bindNPC(child)
end

aiFolder.ChildAdded:Connect(bindNPC)
