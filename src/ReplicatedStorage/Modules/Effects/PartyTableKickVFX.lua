--ReplicatedStorage.Modules.Effects.PartyTableKickVFX

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Modules.Config.Config)

local PartyTableKickVFX = {}

local TEMPLATE = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("PartyTableKickVFX")

function PartyTableKickVFX.Create(parent: Instance)
    if not parent or not parent:IsA("BasePart") then
        return nil
    end

    local cfg = Config.VFX.PartyTableKickVFX or {}
    local vfx = TEMPLATE:Clone()
    vfx.Anchored = false
    vfx.CFrame = parent.CFrame * CFrame.new(cfg.Position.X or 0, cfg.Position.Y or 0, cfg.Position.Z or 0)
    vfx.Size = Vector3.new(cfg.Scale.X or 1, cfg.Scale.Y or 1, cfg.Scale.Z or 1)
    vfx.Parent = parent

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = vfx
    weld.Part1 = parent
    weld.Parent = vfx

    Debris:AddItem(vfx, 2)
    return vfx
end

function PartyTableKickVFX.Remove(vfx: Instance)
    if vfx and vfx.Parent then
        vfx:Destroy()
    end
end

return PartyTableKickVFX
