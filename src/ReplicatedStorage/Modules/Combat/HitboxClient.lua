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
local function createWeldedHitbox(hrp, offsetCFrame, size, duration)
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = hrp.CFrame * offsetCFrame
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
function HitboxClient.CastHitbox(offsetCFrame, size, duration, remoteEvent, extraArgs)
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local hitbox = createWeldedHitbox(hrp, offsetCFrame, size, duration)
	if not hitbox then return end

	local alreadyHit = {}
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { char }

	local startTime = tick()
	local connection

	connection = RunService.RenderStepped:Connect(function()
		if tick() - startTime > duration then
			connection:Disconnect()

                        local targets = {}
                        for humanoid in pairs(alreadyHit) do
                                table.insert(targets, humanoid)
                        end

			if #targets > 0 then
				local playerTargets = {}
				for _, humanoid in ipairs(targets) do
					local model = humanoid.Parent
					local enemyPlayer = Players:GetPlayerFromCharacter(model)
					if enemyPlayer then
						table.insert(playerTargets, enemyPlayer)
					end
				end

                                if #playerTargets > 0 then
                                        if remoteEvent then
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
				alreadyHit[humanoid] = true
			end
		end
	end)
end

return HitboxClient
