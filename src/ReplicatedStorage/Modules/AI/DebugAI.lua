--[[
    DebugAI.lua
    Utility helpers for drawing simple debug information. All functions noop
    when debug mode is disabled.
]]
local DebugAI = {Enabled = false}

function DebugAI:SetEnabled(enabled)
    self.Enabled = enabled and true or false
end

function DebugAI:DrawCone(origin, direction, length, color)
    if not self.Enabled then return end
    -- In Roblox this would use Drawing or adornments. Placeholder only.
    print("[DebugAI] Cone", origin, direction, length, color)
end

function DebugAI:Label(position, text)
    if not self.Enabled then return end
    print("[DebugAI] Label", position, text)
end

return DebugAI
