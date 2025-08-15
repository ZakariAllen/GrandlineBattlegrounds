--ReplicatedStorage.Modules.AI.ActorAdapter
-- Utility to normalize players and NPC models into a common actor record.
-- Returns: { Character, Humanoid, Root, Player, IsPlayer, StyleKey }

local ActorAdapter = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)

-- Resolves the equipped style based on an attribute or equipped tool
local function resolveStyle(char)
    if not char then
        return "BasicCombat"
    end
    local style = char:GetAttribute("StyleKey")
    if style and ToolConfig.ValidCombatTools[style] then
        return style
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and ToolConfig.ValidCombatTools[tool.Name] then
        return tool.Name
    end
    return "BasicCombat"
end

-- Normalize a player or model into an actor table
-- @param actor Instance Player|Model|Humanoid
function ActorAdapter.Get(actor)
    if not actor then
        return nil
    end

    if actor:IsA("Player") then
        local char = actor.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        return {
            Character = char,
            Humanoid = hum,
            Root = root,
            Player = actor,
            IsPlayer = true,
            StyleKey = resolveStyle(char),
        }
    end

    local model
    if actor:IsA("Humanoid") then
        model = actor.Parent
    elseif actor:IsA("Model") then
        model = actor
    else
        model = actor:FindFirstAncestorOfClass("Model")
    end

    if model then
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        local player = Players:GetPlayerFromCharacter(model)
        return {
            Character = model,
            Humanoid = hum,
            Root = root,
            Player = player,
            IsPlayer = player ~= nil,
            StyleKey = resolveStyle(model),
        }
    end

    return nil
end

-- Convenience helpers mirroring the original spec --------------------------

function ActorAdapter.GetCharacter(actor)
    local info = ActorAdapter.Get(actor)
    return info and info.Character or nil
end

function ActorAdapter.GetHumanoid(actor)
    local info = ActorAdapter.Get(actor)
    return info and info.Humanoid or nil
end

function ActorAdapter.GetRoot(actor)
    local info = ActorAdapter.Get(actor)
    return info and info.Root or nil
end

function ActorAdapter.IsPlayer(actor)
    local info = ActorAdapter.Get(actor)
    return info and info.IsPlayer or false
end

function ActorAdapter.GetPlayer(actor)
    local info = ActorAdapter.Get(actor)
    return info and info.Player or nil
end

function ActorAdapter.GetStyleKey(actor)
    local info = ActorAdapter.Get(actor)
    return info and info.StyleKey or "BasicCombat"
end

return ActorAdapter
