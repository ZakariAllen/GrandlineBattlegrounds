--ReplicatedStorage.Modules.Effects.TempestKickVFX

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TempestKickVFX = {}

local TEMPLATE = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("TempestKickVFX")
local Config = require(ReplicatedStorage.Modules.Config.Config)

-- Create and attach the Tempest Kick VFX to the given part
function TempestKickVFX.Create(parent: Instance)
    if not parent or not parent:IsA("BasePart") then
        return nil
    end

    local cfg = Config.VFX.TempestKickVFX or {}
    local vfx = TEMPLATE:Clone()
    vfx.Anchored = false
    vfx.CFrame = parent.CFrame * CFrame.new(cfg.Position.X or 0, cfg.Position.Y or 0, cfg.Position.Z or 0)
    vfx.Size = Vector3.new(cfg.Scale.X or 1, cfg.Scale.Y or 1, cfg.Scale.Z or 1)
    vfx.Parent = parent

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = vfx
    weld.Part1 = parent
    weld.Parent = vfx

    return vfx
end

-- Remove a previously created VFX object
function TempestKickVFX.Remove(vfx: Instance)
    if vfx and vfx.Parent then
        vfx:Destroy()
    end
end

return TempestKickVFX
