--ReplicatedStorage.Modules.AI.ActorAdapter
-- Utility to normalize players and NPC models into a common actor record.
-- Returns: {Character, Humanoid, StyleKey, Player, IsPlayer, Key}

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
        return {
            Character = char,
            Humanoid = hum,
            StyleKey = resolveStyle(char),
            Player = actor,
            IsPlayer = true,
            Key = actor,
        }
    end
    if actor:IsA("Humanoid") then
        local char = actor.Parent
        return {
            Character = char,
            Humanoid = actor,
            StyleKey = resolveStyle(char),
            Player = Players:GetPlayerFromCharacter(char),
            IsPlayer = false,
            Key = actor,
        }
    end
    local model = actor:IsA("Model") and actor or actor:FindFirstAncestorOfClass("Model")
    if model then
        local hum = model:FindFirstChildOfClass("Humanoid")
        local player = Players:GetPlayerFromCharacter(model)
        return {
            Character = model,
            Humanoid = hum,
            StyleKey = resolveStyle(model),
            Player = player,
            IsPlayer = player ~= nil,
            Key = player or hum,
        }
    end
    return nil
end

return ActorAdapter
