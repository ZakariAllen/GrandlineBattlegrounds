--ReplicatedStorage.Modules.AI.ActionQueue
-- Schedules and executes actions with human-like delays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local M1Service = require(game.ServerScriptService.Combat.M1Service)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)
local ActorAdapter = require(ReplicatedStorage.Modules.AI.ActorAdapter)

local ActionQueue = {}
ActionQueue.__index = ActionQueue

function ActionQueue.new(model, bb)
    local self = {
        Model = model,
        Blackboard = bb,
        Queue = {},
        ComboStep = 0,
    }
    return setmetatable(self, ActionQueue)
end

local function schedule(self, fn)
    local cfg = self.Blackboard.Config or {}
    local rt = cfg.ReactionTimeMs or {min = 200, max = 300}
    local jitter = cfg.MicroJitterMs or {min = 0, max = 0}
    local delayTime = math.random(rt.min, rt.max) / 1000
    delayTime += math.random(jitter.min, jitter.max) / 1000
    table.insert(self.Queue, {Time = tick() + delayTime, Fn = fn})
end

function ActionQueue:PressM1()
    schedule(self, function()
        self.ComboStep += 1
        M1Service.ProcessM1Request(self.Model, {step = self.ComboStep})
        if self.ComboStep >= CombatConfig.M1.ComboHits then
            self.ComboStep = 0
        end
    end)
end

function ActionQueue:StartBlock()
    schedule(self, function()
        if BlockService.StartBlocking(self.Model) then
            self.Blackboard.IsBlocking = true
        end
    end)
end

function ActionQueue:ReleaseBlock()
    schedule(self, function()
        BlockService.StopBlocking(self.Model)
        self.Blackboard.IsBlocking = false
    end)
end

function ActionQueue:Dash(direction)
    schedule(self, function()
        local info = ActorAdapter.Get(self.Model)
        if not info then return end
        DashModule.ExecuteDashForModel(info.Character, direction, nil, info.StyleKey)
    end)
end

-- Process due actions
function ActionQueue:Run()
    local now = tick()
    local q = self.Queue
    for i = #q, 1, -1 do
        local item = q[i]
        if now >= item.Time then
            table.remove(q, i)
            task.spawn(item.Fn)
        end
    end
end

return ActionQueue
