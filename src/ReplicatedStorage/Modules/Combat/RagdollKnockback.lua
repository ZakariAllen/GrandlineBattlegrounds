local Players = game:GetService("Players")
local RagdollUtils = require(script.Parent.RagdollUtils)

local RagdollKnockback = {}

RagdollKnockback.DirectionType = {
    AttackerFacingDirection = "AttackerFacingDirection",
    AwayFromAttacker = "AwayFromAttacker",
}

local DEFAULT_FORCE = 50
local DEFAULT_LIFT = 0.5
local DEFAULT_DURATION = 0.5

local function getRoot(humanoid)
    local char = humanoid and humanoid.Parent
    return char and char:FindFirstChild("HumanoidRootPart")
end

function RagdollKnockback.ComputeDirection(directionType, attackerRoot, targetRoot)
    if directionType == RagdollKnockback.DirectionType.AwayFromAttacker then
        if attackerRoot and targetRoot then
            local rel = targetRoot.Position - attackerRoot.Position
            rel = Vector3.new(rel.X, 0, rel.Z)
            if rel.Magnitude > 0 then
                return rel.Unit
            end
        end
    end
    if attackerRoot then
        local look = attackerRoot.CFrame.LookVector
        if look.Magnitude > 0 then
            return look.Unit
        end
    end
    if targetRoot then
        local look = targetRoot.CFrame.LookVector
        if look.Magnitude > 0 then
            return look.Unit
        end
    end
    return Vector3.new(0,0,-1)
end

function RagdollKnockback.IsKnockbackActive(root)
    return root and root:GetAttribute("KnockbackActive") ~= nil
end

function RagdollKnockback.ApplyKnockback(humanoid, direction, force, lift, duration)
    local root = getRoot(humanoid)
    if not root then return end

    direction = typeof(direction) == "Vector3" and direction or root.CFrame.LookVector
    if direction.Magnitude == 0 then
        direction = root.CFrame.LookVector
    else
        direction = direction.Unit
    end
    force = force or DEFAULT_FORCE
    lift = lift or DEFAULT_LIFT
    duration = duration or DEFAULT_DURATION

    RagdollUtils.Enable(humanoid)
    root.Anchored = false
    local prevOwner = root.GetNetworkOwner and root:GetNetworkOwner()
    root:SetNetworkOwner(nil)
    root:SetAttribute("KnockbackActive", true)

    -- The vertical lift should be independent of the horizontal knockback force
    local impulse = Vector3.new(direction.X * force, lift, direction.Z * force) * root.AssemblyMass
    if root.ApplyImpulse then
        root:ApplyImpulse(impulse)
    else
        root.AssemblyLinearVelocity = impulse / root.AssemblyMass
    end

    task.delay(duration, function()
        if root.Parent then
            root:SetAttribute("KnockbackActive", nil)
            if prevOwner then
                root:SetNetworkOwner(prevOwner)
            else
                local player = Players:GetPlayerFromCharacter(root.Parent)
                if player then
                    root:SetNetworkOwner(player)
                end
            end
        end
        RagdollUtils.Disable(humanoid)
    end)
end

function RagdollKnockback.ApplyDirectionalKnockback(humanoid, options)
    options = options or {}
    local dir = RagdollKnockback.ComputeDirection(options.DirectionType, options.AttackerRoot, options.TargetRoot)
    RagdollKnockback.ApplyKnockback(humanoid, dir, options.Force, options.Lift, options.Duration)
end

return RagdollKnockback
