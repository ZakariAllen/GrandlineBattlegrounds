--ReplicatedStorage.Modules.Combat.HitboxClient
local HitboxClient = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

-- Configs
local Config = require(ReplicatedStorage.Modules.Config.Config)
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)

-- ✅ Fixed remote reference
local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local HitConfirmEvent = CombatRemotes:WaitForChild("HitConfirmEvent")

-- ✅ Create visual debug hitbox (attached to HRP)
local function createWeldedHitbox(hrp, offsetCFrame, size, duration, shape)
        local part = Instance.new("Part")
        part.Size = size
        part.CFrame = hrp.CFrame * offsetCFrame
        if shape == "Cylinder" then
                part.Shape = Enum.PartType.Cylinder
                part.Orientation = Vector3.new(0, 0, 90)
        end
        part.Anchored = false
        part.CanCollide = false
	part.Transparency = Config.GameSettings.DebugEnabled and 0.6 or 1
	part.Material = Enum.Material.ForceField
	part.BrickColor = BrickColor.new("Bright red")
	part.Name = "ClientHitbox"
	part.Parent = Workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = part
	weld.Parent = part

	Debris:AddItem(part, duration or 0.25)
	return part
end

-- ✅ Main cast function (runs hit detection client-side)
-- Optional remoteEvent and extraArgs allow reusing this hitbox logic for
-- other attacks. If remoteEvent is nil, the default HitConfirmEvent is used.
function HitboxClient.CastHitbox(
    offsetCFrame,
    size,
    duration,
    remoteEvent,
    extraArgs,
    shape,
    fireOnMiss,
    travelDistance,
    fireOnHit
)
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

    local hitbox = createWeldedHitbox(hrp, offsetCFrame, size, duration, shape)
    if not hitbox then return end
    if Config.GameSettings.DebugEnabled then
        print("[HitboxClient] CastHitbox", offsetCFrame, size, duration, travelDistance)
    end

        local originCF = hitbox.CFrame
        local dir = hrp.CFrame.LookVector
        if travelDistance and travelDistance ~= 0 then
                local weld = hitbox:FindFirstChildOfClass("WeldConstraint")
                if weld then weld:Destroy() end
                hitbox.Anchored = true
        end

    local alreadyHit = {}
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { char }

	local startTime = tick()
	local connection

        connection = RunService.RenderStepped:Connect(function()
                local elapsed = tick() - startTime
                if travelDistance and travelDistance ~= 0 then
                        local progress = math.clamp(elapsed / duration, 0, 1)
                        hitbox.CFrame = originCF + dir * travelDistance * progress
                end
                if elapsed > duration then
                        connection:Disconnect()

                        local targets = {}
                        for humanoid in pairs(alreadyHit) do
                                table.insert(targets, humanoid)
                        end

                        local playerTargets = {}
                        for _, humanoid in ipairs(targets) do
                                local model = humanoid.Parent
                                local enemyPlayer = Players:GetPlayerFromCharacter(model)
                                if enemyPlayer then
                                        table.insert(playerTargets, enemyPlayer)
                                end
                        end

                        if fireOnHit then
                                if #playerTargets == 0 and fireOnMiss and remoteEvent then
                                        if Config.GameSettings.DebugEnabled then
                                                print("[HitboxClient] Miss -> firing remote with dir", extraArgs)
                                        end
                                        remoteEvent:FireServer({}, table.unpack(extraArgs or {}))
                                end
                        else
                                if #playerTargets > 0 or fireOnMiss then
                                        if remoteEvent then
                                                if Config.GameSettings.DebugEnabled then
                                                        print("[HitboxClient] Firing remote with targets", playerTargets, extraArgs)
                                                end
                                                remoteEvent:FireServer(playerTargets, table.unpack(extraArgs or {}))
                                        else
                                                local comboIndex = CombatConfig._lastUsedComboIndex or 1
                                                local isFinal = comboIndex == CombatConfig.M1.ComboHits
                                                HitConfirmEvent:FireServer(playerTargets, comboIndex, isFinal)
                                        end
                                end
                        end
                        return
                end

                local parts = Workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, overlapParams)
                for _, part in ipairs(parts) do
                        local model = part:FindFirstAncestorOfClass("Model")
                        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
                        local otherPlayer = model and Players:GetPlayerFromCharacter(model)

                        if humanoid and otherPlayer and otherPlayer ~= player then
                                local newHit = false
                                if shape == "Cylinder" then
                                        local root = model:FindFirstChild("HumanoidRootPart")
                                        if root then
                                                local center = hitbox.CFrame.Position
                                                local dx = root.Position.X - center.X
                                                local dz = root.Position.Z - center.Z
                                                local radius = hitbox.Size.X * 0.5
                                                local height = hitbox.Size.Y
                                                if math.sqrt(dx * dx + dz * dz) <= radius and math.abs(root.Position.Y - center.Y) <= height * 0.5 then
                                                        newHit = true
                                                end
                                        end
                                else
                                        newHit = true
                                end

                                if newHit and not alreadyHit[humanoid] then
                                        alreadyHit[humanoid] = true
                                        if fireOnHit and remoteEvent then
                                                remoteEvent:FireServer({ otherPlayer }, table.unpack(extraArgs or {}))
                                        end
                                end
                        end
                end
        end)

        return hitbox
end

return HitboxClient
