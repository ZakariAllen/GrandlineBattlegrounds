--ServerScriptService.AI.NPCController
-- Scans workspace.AI for NPC models and runs simple combat brains.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Time = require(ReplicatedStorage.Modules.Util.Time)
local Workspace = game:GetService("Workspace")

local AIConfig = require(ReplicatedStorage.Modules.Config.AIConfig)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local Config = require(ReplicatedStorage.Modules.Config.Config)
local MovementAnimations = require(ReplicatedStorage.Modules.Animations.Movement)
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

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local animateScript = model:FindFirstChild("Animate")
    if animateScript then
        animateScript:Destroy()
    end

    hum.WalkSpeed = Config.GameSettings.DefaultWalkSpeed or 10

    local styleKey = styleKeys[math.random(1, #styleKeys)] or "BasicCombat"
    model:SetAttribute("StyleKey", styleKey)
    createTool(model, styleKey)

    local bb = Blackboard.new(n, AIConfig.Levels[n])
    local queue = ActionQueue.new(model, bb)

    local animCache = {}
    local currentTrack
    local currentState

    local function playState(state, animId)
        if currentState == state then
            return
        end
        currentState = state
        if currentTrack then
            currentTrack:Stop(0.15)
        end
        if not animId then
            currentTrack = nil
            return
        end
        local anim = animCache[animId]
        if not anim then
            anim = Instance.new("Animation")
            anim.AnimationId = animId
            animCache[animId] = anim
        end
        currentTrack = animator:LoadAnimation(anim)
        currentTrack.Priority = Enum.AnimationPriority.Movement
        currentTrack.Looped = true
        currentTrack:Play(0.15)
    end

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

    task.spawn(function()
        local defaultWalk = Config.GameSettings.DefaultWalkSpeed or 10
        local sprintSpeed = Config.GameSettings.DefaultSprintSpeed or 20
        while running and model.Parent do
            local engaged = bb.Target ~= nil
            if engaged and (bb.DistanceBand == "Long" or bb.IsClosing) then
                hum.WalkSpeed = sprintSpeed
            else
                hum.WalkSpeed = defaultWalk
            end

            local state
            if hum.MoveDirection.Magnitude < 0.05 then
                state = "Idle"
            elseif hum.WalkSpeed >= sprintSpeed then
                state = "Sprint"
            else
                state = "Walk"
            end

            if state == "Idle" then
                playState(state, MovementAnimations.Idle)
            elseif state == "Sprint" then
                playState(state, MovementAnimations.Sprint)
            else
                playState(state, MovementAnimations.Run or MovementAnimations.Walk)
            end

            task.wait(0.1)
        end

        if currentTrack then
            currentTrack:Stop(0.15)
            currentTrack = nil
        end
    end)

    local function cleanup()
        running = false
        if currentTrack then
            currentTrack:Stop(0.15)
            currentTrack = nil
        end
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
