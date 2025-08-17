-- StarterCharacterScripts > AntiRagdollController.lua

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Time = require(ReplicatedStorage.Modules.Util.Time)

local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Constants
local MAX_JUMP_VELOCITY = 50
local FRICTION = 1
local ELASTICITY = 0
local DENSITY = 1
local CORRECTION_DELAY = 0.2

-- Prevent duplicate application
if character:FindFirstChild("AntiRagdollInitialized") then return end
local tag = Instance.new("BoolValue")
tag.Name = "AntiRagdollInitialized"
tag.Parent = character

-- Apply stable physical properties to all parts (except HRP)
for _, part in ipairs(character:GetDescendants()) do
	if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
		part.Massless = true
		part.CustomPhysicalProperties = PhysicalProperties.new(DENSITY, FRICTION, ELASTICITY)
	end
end

-- Remove any leftover alignments
local oldAlign = hrp:FindFirstChild("AntiRagdollAlign")
if oldAlign then oldAlign:Destroy() end
local oldAttach = hrp:FindFirstChild("UprightAttachment")
if oldAttach then oldAttach:Destroy() end

-- Runtime stabilization
local lastCorrection = 0

RunService.Heartbeat:Connect(function()
	if not humanoid or not hrp then return end

    -- Ensure autorotate is always on when not stunned
    if humanoid.AutoRotate == false and not StunStatusClient.IsStunned() then
            humanoid.AutoRotate = true
    end

	-- Reset invalid physics states on delay
        if Time.now() - lastCorrection >= CORRECTION_DELAY then
                local state = humanoid:GetState()
                local knockback = hrp:GetAttribute("KnockbackActive") or hrp:GetAttribute("Ragdolled")
                if not knockback and (state == Enum.HumanoidStateType.Ragdoll
                        or state == Enum.HumanoidStateType.FallingDown
                        or state == Enum.HumanoidStateType.PlatformStanding) then
                        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                        lastCorrection = Time.now()
                end
        end

	-- Prevent sitting from weird physics
	if humanoid.Sit then
		humanoid.Sit = false
	end

	-- Clamp vertical velocity (no skyflinging)
	if hrp.Velocity.Y > MAX_JUMP_VELOCITY then
		local vy = math.clamp(hrp.Velocity.Y, -math.huge, MAX_JUMP_VELOCITY)
		hrp.Velocity = Vector3.new(hrp.Velocity.X, vy, hrp.Velocity.Z)
	end
end)
