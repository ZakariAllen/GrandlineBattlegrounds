--ReplicatedStorage.Modules.Effects.DashVFX

local Debris = game:GetService("Debris")

local DashVFX = {}

--\u{1F32C}\u{FE0F} Simple wind texture for dash trails
DashVFX.WIND_TEXTURE = "rbxassetid://6091329339"

-- Mapping of dash direction to emission direction for the trail
DashVFX.DirectionMap = {
    Forward = Enum.NormalId.Back,
    Backward = Enum.NormalId.Front,
    Left = Enum.NormalId.Right,
    Right = Enum.NormalId.Left,
    ForwardLeft = Enum.NormalId.Back,
    ForwardRight = Enum.NormalId.Back,
    BackwardLeft = Enum.NormalId.Front,
    BackwardRight = Enum.NormalId.Front,
}

function DashVFX:PlayDashEffect(direction: string, parent: Instance)
    if not parent or not parent:IsA("BasePart") then return end

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = DashVFX.WIND_TEXTURE
    emitter.LightEmission = 1
    emitter.Speed = NumberRange.new(0)
    emitter.Lifetime = NumberRange.new(0.2)
    emitter.Rate = 0
    emitter.Enabled = false
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.EmissionDirection = DashVFX.DirectionMap[direction] or Enum.NormalId.Back
    emitter.Parent = parent

    emitter:Emit(12)
    Debris:AddItem(emitter, 1)
end

return DashVFX
