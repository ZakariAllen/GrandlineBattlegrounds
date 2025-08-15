--[[
    NPCController.server.lua
    Basic per-NPC loop using the AI modules. This is a lightweight
    demonstration controller and does not aim to be feature complete.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AIConfig = require(ReplicatedStorage.Modules.Config.AIConfig)
local Blackboard = require(ReplicatedStorage.Modules.AI.Blackboard)
local Perception = require(ReplicatedStorage.Modules.AI.Perception)
local Decision = require(ReplicatedStorage.Modules.AI.Decision)
local ActionQueue = require(ReplicatedStorage.Modules.AI.ActionQueue)

local NPCFolder = workspace:FindFirstChild("NPCs")

local function acquireTarget()
    local plrs = Players:GetPlayers()
    if #plrs > 0 then
        return plrs[1].Character
    end
    return nil
end

local function initNPC(model, level)
    if not model then return end
    local bb = Blackboard.new()
    bb.ArchetypeLevel = level or 1
    bb.Target = acquireTarget()

    local fakePlayer = {Character = model}
    local queue = ActionQueue.new(fakePlayer)

    task.spawn(function()
        while model.Parent do
            if not bb.Target then
                bb.Target = acquireTarget()
            end
            Perception.Update(model, bb)
            local actions = Decision.Tick(model, bb)
            for _, act in ipairs(actions) do
                if act == "PressM1" then
                    queue:PressM1(1)
                elseif act == "DashIn" then
                    queue:Dash("Forward", model.PrimaryPart and model.PrimaryPart.CFrame.LookVector)
                elseif act == "DashOut" then
                    queue:Dash("Backward", model.PrimaryPart and -model.PrimaryPart.CFrame.LookVector)
                elseif act == "StartBlock" then
                    queue:StartBlock()
                elseif act == "ReleaseBlock" then
                    queue:ReleaseBlock()
                end
            end
            queue:Run()
            task.wait(1 / AIConfig.DecisionHz)
        end
    end)
end

if NPCFolder then
    for _, npc in ipairs(NPCFolder:GetChildren()) do
        initNPC(npc, 1)
    end
    NPCFolder.ChildAdded:Connect(function(child)
        initNPC(child, 1)
    end)
end
