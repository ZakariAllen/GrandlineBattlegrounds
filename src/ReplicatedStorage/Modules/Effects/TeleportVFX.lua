local TeleportVFX = {}

local Debris = game:GetService("Debris")

-- Placeholder texture asset. Replace with actual effect when available
TeleportVFX.TEXTURE = "rbxassetid://0"

function TeleportVFX.Play(position)
    if typeof(position) == "CFrame" then
        position = position.Position
    elseif typeof(position) ~= "Vector3" then
        return
    end

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(1,1,1)
    part.CFrame = CFrame.new(position)

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = TeleportVFX.TEXTURE
    emitter.Speed = NumberRange.new(0)
    emitter.Lifetime = NumberRange.new(0.3)
    emitter.Rate = 0
    emitter.Enabled = false
    emitter.Parent = part

    emitter:Emit(20)
    part.Parent = workspace
    Debris:AddItem(part, 1)
end

return TeleportVFX
