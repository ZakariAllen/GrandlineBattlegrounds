--[[
    ActionQueue.lua
    Schedules and executes actions for an NPC in a human-like manner.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)

local M1Service

local ActionQueue = {}
ActionQueue.__index = ActionQueue

-- Creates a new queue for the given player-like object
function ActionQueue.new(playerLike)
    local self = setmetatable({
        actor = playerLike,
        queue = {},
    }, ActionQueue)
    return self
end

-- Internal helper to lazily load the M1 service
local function getM1Service()
    if not M1Service then
        M1Service = require(ServerScriptService.Combat.M1Service)
    end
    return M1Service
end

-- Adds an action to the queue
function ActionQueue:Enqueue(fn, delay)
    table.insert(self.queue, {time = tick() + (delay or 0), fn = fn})
end

-- Runs due actions
function ActionQueue:Run()
    local now = tick()
    for i = #self.queue, 1, -1 do
        local item = self.queue[i]
        if now >= item.time then
            item.fn()
            table.remove(self.queue, i)
        end
    end
end

function ActionQueue:PressM1(step)
    self:Enqueue(function()
        getM1Service().ProcessM1Request(self.actor, {step = step or 1})
    end, 0)
end

function ActionQueue:StartBlock()
    self:Enqueue(function()
        BlockService.StartBlocking(self.actor)
    end, 0)
end

function ActionQueue:ReleaseBlock()
    self:Enqueue(function()
        BlockService.StopBlocking(self.actor)
    end, 0)
end

function ActionQueue:Dash(direction, dashVector, styleKey)
    self:Enqueue(function()
        DashModule.ExecuteDash(self.actor, direction, dashVector, styleKey)
    end, 0)
end

return ActionQueue
