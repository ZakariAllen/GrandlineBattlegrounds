--ReplicatedStorage.Modules.AI.ActionQueue
-- Schedules and executes actions with human-like delays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Time = require(ReplicatedStorage.Modules.Util.Time)

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local M1Service = require(game.ServerScriptService.Combat.M1Service)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)
local ActorAdapter = require(ReplicatedStorage.Modules.AI.ActorAdapter)
local CombatAnimations = require(ReplicatedStorage.Modules.Animations.Combat)

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
    table.insert(self.Queue, {Time = Time.now() + delayTime, Fn = fn})
end

function ActionQueue:PressM1()
    schedule(self, function()
        self.ComboStep += 1
        local comboIndex = self.ComboStep

        local info = ActorAdapter.Get(self.Model)
        if info and info.Humanoid then
            local style = info.StyleKey or "BasicCombat"
            local animSet = CombatAnimations.M1[style]
            if animSet and animSet.Combo then
                local animId = animSet.Combo[comboIndex]
                if animId then
                    local animator = info.Humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = animId
                        local track = animator:LoadAnimation(animation)
                        track.Looped = false
                        track.Priority = Enum.AnimationPriority.Action
                        track:Play()
                    end
                end
            end
        end

        task.delay(CombatConfig.M1.HitDelay or 0.15, function()
            M1Service.ApplyHit(self.Model, comboIndex)
        end)

        if comboIndex >= CombatConfig.M1.ComboHits then
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
    local now = Time.now()
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
