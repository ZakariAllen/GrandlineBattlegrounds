local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local DashConfig = require(ReplicatedStorage.Modules.Movement.DashConfig)
local Animations = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)

local Helpers = {}

--[=[
    Returns distance band between attacker and target based on tool metadata.
    @param attacker Model
    @param target Model
    @param toolName string
    @return string "TooClose"|"Ideal"|"Long"
]=]
function Helpers.GetDistanceBand(attacker, target, toolName)
    local meta = ToolConfig.ToolMeta[toolName]
    local band = meta and meta.IdealDistanceBand
    if not band then return "Long" end
    local aRoot = attacker and attacker:FindFirstChild("HumanoidRootPart")
    local tRoot = target and target:FindFirstChild("HumanoidRootPart")
    if not aRoot or not tRoot then return "Long" end
    local dist = (aRoot.Position - tRoot.Position).Magnitude
    if dist < band.TooClose then
        return "TooClose"
    elseif dist < band.Ideal then
        return "Ideal"
    end
    return "Long"
end

--[=[
    Check if a wall exists behind the target within the given radius.
    @param target Model
    @param radius number
    @param angle number -- currently unused but kept for future expansion
    @return boolean
]=]
function Helpers.HasWallBehind(target, radius)
    local root = target and target:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { target }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local dir = -root.CFrame.LookVector
    local result = workspace:Raycast(root.Position, dir * radius, params)
    return result ~= nil
end

--[=[
    Projects a desired dash direction while avoiding immediate collisions.
    @param attacker Model
    @param desiredDir Vector3
    @return Vector3
]=]
function Helpers.SafeDashVector(attacker, desiredDir)
    desiredDir = (desiredDir.Magnitude > 0 and desiredDir.Unit) or Vector3.new(0, 0, -1)
    local root = attacker and attacker:FindFirstChild("HumanoidRootPart")
    if not root then return desiredDir end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { attacker }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local dist = DashConfig.MaxDistance or 0
    local hit = workspace:Raycast(root.Position, desiredDir * dist, params)
    if hit then
        local hitDir = (hit.Position - root.Position)
        if hitDir.Magnitude > 0 then
            return hitDir.Unit
        end
    end
    return desiredDir
end

--[=[
    Returns a table describing the observable pose state of a character.
    @param character Model
    @return table
]=]
function Helpers.GetPoseState(character)
    local tags = Animations.GetCurrentTags(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return {
        Blocking = tags.Blocking or false,
        Dashing = tags.Dashing or false,
        InWindup = (tags.Windup and not tags.Active) or false,
        InRecovery = tags.Recovery or false,
        Airborne = humanoid and humanoid.FloorMaterial == Enum.Material.Air or false,
        Stunned = StunService:IsStunned(character),
    }
end

return Helpers
