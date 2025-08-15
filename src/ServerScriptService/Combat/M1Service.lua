--[[
    M1Service.lua
    Shared helper for processing melee (M1) requests from both players and NPCs.
    Extracted from CombatService so that NPCs can reuse the exact same logic.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)

local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local AnimationUtils = require(ReplicatedStorage.Modules.Effects.AnimationUtils)

local M1Service = {}
local comboTimestamps = {}
M1Service.ComboTimestamps = comboTimestamps

local function getStyleKeyFromTool(tool)
    if tool and ToolConfig.ValidCombatTools[tool.Name] then
        return tool.Name
    end
    return "BasicCombat"
end

local function playAnimation(humanoid, animId)
    if not animId or not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    AnimationUtils.PlayAnimation(animator, animId)
end

-- Processes an M1 request exactly as the RemoteEvent handler would
-- @param player Player-like object (must have Character)
-- @param payload table from client containing combo step and aim info
function M1Service.ProcessM1Request(player, payload)
    local comboIndex
    if typeof(payload) == "table" then
        comboIndex = payload.step or payload[1]
    else
        comboIndex = payload
    end
    if typeof(comboIndex) ~= "number" then return end
    comboIndex = math.floor(comboIndex)
    if comboIndex < 1 or comboIndex > CombatConfig.M1.ComboHits then return end

    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then return end
    if BlockService.IsBlocking(player) or BlockService.IsInStartup(player) then return end

    local now = tick()
    comboTimestamps[player] = comboTimestamps[player] or { LastClick = 0, CooldownEnd = 0 }
    local state = comboTimestamps[player]

    if now < state.CooldownEnd then return end
    state.LastClick = now
    if comboIndex == CombatConfig.M1.ComboHits then
        state.CooldownEnd = now + CombatConfig.M1.ComboCooldown
    end

    local tool = char:FindFirstChildOfClass("Tool")
    local styleKey = getStyleKeyFromTool(tool)
    local animSet = AnimationData.M1[styleKey]
    local animId = animSet and animSet.Combo and animSet.Combo[comboIndex]
    if animId then
        playAnimation(humanoid, animId)
    end
end

return M1Service
