--ReplicatedStorage.Modules.Combat.StunService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes (may not exist during tests)
local StunStatusEvent
local success, remotes = pcall(function()
    return ReplicatedStorage:WaitForChild("Remotes")
end)
if success and remotes then
    local stunFolder = remotes:FindFirstChild("Stun")
    if stunFolder then
        StunStatusEvent = stunFolder:FindFirstChild("StunStatusRequestEvent")
    end
end

local Config = require(ReplicatedStorage.Modules.Config.Config)
local CombatAnimations = require(ReplicatedStorage.Modules.Animations.Combat)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)

local StunService = {}

local StunnedPlayers = {}
local AttackerLockouts = {}
local HitReservations = {}
local ActiveAnimations = {}

local function sendStatus(player)
    if RunService:IsServer() and StunStatusEvent and player then
        local data = {
            Stunned = StunnedPlayers[player] ~= nil,
            AttackerLock = AttackerLockouts[player] ~= nil and tick() < (AttackerLockouts[player] or 0)
        }
        StunStatusEvent:FireClient(player, data)
    end
end

local function getPlayer(thing)
	if typeof(thing) == "Instance" then
		if thing:IsA("Player") then return thing end
		local model = thing:IsA("Model") and thing or thing:FindFirstAncestorOfClass("Model")
		if model then return Players:GetPlayerFromCharacter(model) end
	end
	return nil
end

function StunService:IsStunned(player)
	return StunnedPlayers[player] ~= nil
end

function StunService:IsAttackerLocked(player)
	return AttackerLockouts[player] ~= nil and tick() < AttackerLockouts[player]
end

function StunService:WasRecentlyHit(targetPlayer)
	local t = HitReservations[targetPlayer]
	return t and (tick() - t < 0.1)
end

function StunService:CanBeHitBy(attacker, target)
        -- Currently all attackers may hit a stunned target
        if not attacker or not target then return false end
        return true
end

--[[@
        ApplyStun applies a stun to the target humanoid for the given duration.
        The third parameter can either be:
                * boolean true/false to indicate if the default animation should be skipped
                * a string/number representing a custom animation id to play
]]
function StunService:ApplyStun(targetHumanoid, duration, animOrSkip, attacker)
        local targetPlayer = getPlayer(targetHumanoid)
        local attackerPlayer = getPlayer(attacker)
        if not targetPlayer or not attackerPlayer then return end

       BlockService.StopBlocking(targetPlayer)

        if self:WasRecentlyHit(targetPlayer) then return end
        HitReservations[targetPlayer] = tick()

        local existing = StunnedPlayers[targetPlayer]
        if existing then
                if existing.Conn then existing.Conn:Disconnect() end
                StunnedPlayers[targetPlayer] = nil
        end

        if ActiveAnimations[targetPlayer] then
                ActiveAnimations[targetPlayer]:Stop()
                ActiveAnimations[targetPlayer]:Destroy()
                ActiveAnimations[targetPlayer] = nil
        end

    targetHumanoid.WalkSpeed = 0
    targetHumanoid.JumpPower = 0
    local hrp = targetHumanoid.Parent and targetHumanoid.Parent:FindFirstChild("HumanoidRootPart")
    local prevAutoRotate
    if hrp then
        prevAutoRotate = targetHumanoid.AutoRotate
        targetHumanoid.AutoRotate = false
        -- Clear all momentum on hit so gravity takes over
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end

        local skipAnim = false
        local stunAnimId
        if typeof(animOrSkip) == "boolean" then
                skipAnim = animOrSkip
        elseif typeof(animOrSkip) == "string" or typeof(animOrSkip) == "number" then
                stunAnimId = animOrSkip
        end
        stunAnimId = stunAnimId or CombatAnimations.Stun.Default

        if not skipAnim then
                local animator = targetHumanoid:FindFirstChildOfClass("Animator")
                if animator and stunAnimId then
                        local anim = Instance.new("Animation")
                        if tostring(stunAnimId):match("^rbxassetid://") then
                                anim.AnimationId = tostring(stunAnimId)
                        else
                                anim.AnimationId = "rbxassetid://" .. tostring(stunAnimId)
                        end
                        local track = animator:LoadAnimation(anim)
                        track.Priority = Enum.AnimationPriority.Action
                        track.Looped = false
                        track:Play()
                        ActiveAnimations[targetPlayer] = track
                end
        end
        local conn
        conn = RunService.Heartbeat:Connect(function()
                if targetHumanoid and targetHumanoid.Parent then
                        targetHumanoid.WalkSpeed = 0
                        targetHumanoid.Jump = false
                        if hrp then
                                local v = hrp.AssemblyLinearVelocity
                               -- Preserve applied knockback forces by not
                               -- zeroing horizontal velocity when a knockback force is present
                               if not hrp:FindFirstChildOfClass("BodyVelocity")
                                       and not hrp:FindFirstChildOfClass("VectorForce")
                                       and not hrp:GetAttribute("KnockbackActive") then
                                       hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
                               end
                                hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                        end
                end
        end)

        local endTime = tick() + duration
        StunnedPlayers[targetPlayer] = { EndsAt = endTime, Conn = conn, HRP = hrp, PrevAutoRotate = prevAutoRotate }
        sendStatus(targetPlayer)

	task.delay(duration, function()
		local data = StunnedPlayers[targetPlayer]
		if data and tick() >= data.EndsAt then
                        if data.Conn then data.Conn:Disconnect() end
                        StunnedPlayers[targetPlayer] = nil
                        if data.HRP then
                                targetHumanoid.AutoRotate = data.PrevAutoRotate ~= nil and data.PrevAutoRotate or true
                        end

			targetHumanoid.WalkSpeed = Config.GameSettings.DefaultWalkSpeed
			targetHumanoid.JumpPower = Config.GameSettings.DefaultJumpPower

                        if ActiveAnimations[targetPlayer] then
                                ActiveAnimations[targetPlayer]:Stop()
                                ActiveAnimations[targetPlayer]:Destroy()
                                ActiveAnimations[targetPlayer] = nil
                        end
                        sendStatus(targetPlayer)
                end
        end)

        local lockoutDuration = Config.GameSettings.AttackerLockoutDuration or 0.5
        local unlockTime = tick() + lockoutDuration
        AttackerLockouts[attackerPlayer] = unlockTime
        sendStatus(attackerPlayer)

	task.delay(lockoutDuration, function()
                if AttackerLockouts[attackerPlayer] and tick() >= unlockTime then
                        AttackerLockouts[attackerPlayer] = nil
                        sendStatus(attackerPlayer)
                end
        end)
end

return StunService
