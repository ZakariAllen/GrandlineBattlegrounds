--ReplicatedStorage.Modules.Effects.BlockVFX

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local BlockVFX = {}

local TEMPLATE = ReplicatedFirst
    :WaitForChild("VFX")
    :WaitForChild("BlockVFX")

-- Create and attach the block VFX to the given part
function BlockVFX.Create(parent: Instance)
    if not parent or not parent:IsA("BasePart") then
        return nil
    end

    local vfx = TEMPLATE:Clone()
    vfx.Anchored = false
    vfx.CFrame = parent.CFrame
    vfx.Parent = parent

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = vfx
    weld.Part1 = parent
    weld.Parent = vfx

    local attachment = vfx:FindFirstChild("Main")
    if attachment and attachment:IsA("Attachment") then
        for _, emitter in ipairs(attachment:GetChildren()) do
            if emitter:IsA("ParticleEmitter") then
                emitter.Enabled = true
            end
        end
    end

    return vfx
end

-- Remove a previously created VFX object
function BlockVFX.Remove(vfx: Instance)
    if vfx and vfx.Parent then
        vfx:Destroy()
    end
end

return BlockVFX
