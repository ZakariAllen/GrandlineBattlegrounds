--ReplicatedStorage.Modules.Effects.PartyTableKickVFX

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Modules.Config.Config)

local PartyTableKickVFX = {}

local TEMPLATE = ReplicatedFirst
    :WaitForChild("VFX")
    :WaitForChild("PartyTableKickVFX")

function PartyTableKickVFX.Create(parent: Instance)
    if not parent or not parent:IsA("BasePart") then
        return nil
    end

    local cfg = Config.VFX.PartyTableKickVFX or {}
    local vfx = TEMPLATE:Clone()
    vfx.Anchored = false

    -- The hitbox for PartyTableKick is rotated 90 degrees on the Z axis. When
    -- the VFX is parented to that hitbox it inherits the same rotation which
    -- results in the effect playing sideways. If the parent is the hitbox,
    -- counter rotate so the effect appears upright.
    local cf = parent.CFrame * CFrame.new(cfg.Position.X or 0, cfg.Position.Y or 0, cfg.Position.Z or 0)
    if parent.Name == "ClientHitbox" then
        cf = cf * CFrame.Angles(0, 0, math.rad(-90))
    end
    vfx.CFrame = cf
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
