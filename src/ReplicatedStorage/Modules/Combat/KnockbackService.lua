--ReplicatedStorage.Modules.Combat.KnockbackService

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local KnockbackConfig = require(script.Parent.KnockbackConfig)
local Config = require(game:GetService("ReplicatedStorage").Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

local KnockbackService = {}

KnockbackService.DirectionType = KnockbackConfig.Type

-- Backwards compatible helper
function KnockbackService.ComputeDirection(directionType, attackerRoot, enemyRoot, hitboxDir)
    return KnockbackConfig.GetDirection(directionType, attackerRoot, enemyRoot, hitboxDir)
end

-- Utility to check active knockback forces on a root part
function KnockbackService.IsKnockbackActive(root)
    if not root then return false end
    if root:GetAttribute("KnockbackActive") then return true end
    if root:FindFirstChildOfClass("BodyVelocity") then return true end
    if root:FindFirstChildOfClass("VectorForce") then return true end
    return false
end

local function clearForces(root)
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("BodyMover") or child:IsA("VectorForce") then
            child:Destroy()
        end
    end
end

-- Applies a knockback impulse and force to the humanoid
function KnockbackService.ApplyKnockback(humanoid, direction, distance, duration, lift)
    if not humanoid then return end
    local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if DEBUG then
        print("[KnockbackService] Applying knockback to", humanoid.Parent.Name,
            "dir", direction, "distance", distance, "duration", duration, "lift", lift)
    end

    direction = typeof(direction) == "Vector3" and direction or root.CFrame.LookVector
    if direction.Magnitude == 0 then
        direction = root.CFrame.LookVector
    else
        direction = direction.Unit
    end
    distance = distance or 25
    duration = duration or 0.4
    lift = lift or 3



    humanoid.PlatformStand = false
    root.Anchored = false

    local previousOwner = nil
    if root.GetNetworkOwner then
        previousOwner = root:GetNetworkOwner()
    end

    root:SetNetworkOwner(nil)
    clearForces(root)

    -- Flag that knockback is active so other systems can recognize it
    root:SetAttribute("KnockbackActive", true)

    local velocity = direction * (distance / duration)
    velocity = Vector3.new(velocity.X, lift, velocity.Z)

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = velocity
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1500
    bv.Parent = root
    Debris:AddItem(bv, duration)

    root.CFrame = CFrame.new(root.Position, root.Position - direction)

    task.delay(duration, function()
        if root.Parent then
            root:SetAttribute("KnockbackActive", nil)
            if previousOwner then
                root:SetNetworkOwner(previousOwner)
            else
                local char = humanoid.Parent
                local player = char and Players:GetPlayerFromCharacter(char)
                if player then
                    root:SetNetworkOwner(player)
                end
            end
            if DEBUG then
                print("[KnockbackService] Knockback ended for", humanoid.Parent.Name)
            end
        end
    end)
end

-- Convenience API to compute direction internally
function KnockbackService.ApplyDirectionalKnockback(humanoid, options)
    options = options or {}
    local dir = KnockbackService.ComputeDirection(
        options.DirectionType,
        options.AttackerRoot,
        options.TargetRoot,
        options.HitboxDirection
    )
    local params = KnockbackConfig.Params and KnockbackConfig.Params[options.DirectionType] or {}
    local distance = options.Distance or params.Distance
    local duration = options.Duration or params.Duration
    local lift = options.Lift or params.Lift
    if DEBUG then
        print("[KnockbackService] Dir computed", dir, "distance", distance, "duration", duration, "lift", lift)
    end
    KnockbackService.ApplyKnockback(humanoid, dir, distance, duration, lift)
end

return KnockbackService
