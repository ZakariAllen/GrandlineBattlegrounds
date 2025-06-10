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

-- Lazily fetch the remote if it wasn't available at load time
local function fetchStunEvent()
    if StunStatusEvent then return StunStatusEvent end
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then return nil end
    local stunFolder = remotesFolder:FindFirstChild("Stun")
    if not stunFolder then return nil end
    StunStatusEvent = stunFolder:FindFirstChild("StunStatusRequestEvent")
    return StunStatusEvent
end

-- Attempt to resolve the remote immediately in case RemoteSetup already ran
fetchStunEvent()

local Config = require(ReplicatedStorage.Modules.Config.Config)
local CombatAnimations = require(ReplicatedStorage.Modules.Animations.Combat)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local KnockbackService = require(ReplicatedStorage.Modules.Combat.KnockbackService)
local AnimationUtils = require(ReplicatedStorage.Modules.Effects.AnimationUtils)

local DEBUG = Config.GameSettings.DebugEnabled

local StunService = {}

local StunnedPlayers = {}
local AttackerLockouts = {}
local HitReservations = {}
local ActiveAnimations = {}

-- forward declaration for sendStatus so callbacks defined below can reference it
local sendStatus

local function cleanupPlayer(player)
    local data = StunnedPlayers[player]
    if data then
        if data.HRP and data.PreserveVelocity then
            data.HRP:SetAttribute("StunPreserveVelocity", nil)
        end
        StunnedPlayers[player] = nil
    end
    AttackerLockouts[player] = nil
    HitReservations[player] = nil
    local track = ActiveAnimations[player]
    if track then
        track:Stop()
        track:Destroy()
        ActiveAnimations[player] = nil
    end
end

if RunService:IsServer() then
    Players.PlayerRemoving:Connect(cleanupPlayer)
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            cleanupPlayer(p)
            sendStatus(p)
        end)
    end)
    RunService.Heartbeat:Connect(function()
        for player, data in pairs(StunnedPlayers) do
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 0
                hum.Jump = false
            end
            local hrp = data.HRP
            if hrp then
                local v = hrp.AssemblyLinearVelocity
                if not KnockbackService.IsKnockbackActive(hrp)
                    and not hrp:GetAttribute("StunPreserveVelocity") then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
                elseif DEBUG then
                    print("[StunService] Preserving velocity for", player.Name)
                end
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

sendStatus = function(player)
    if RunService:IsServer() and fetchStunEvent() and player then
        local data = {
            Stunned = StunnedPlayers[player] ~= nil,
            AttackerLock = AttackerLockouts[player] ~= nil and tick() < (AttackerLockouts[player] or 0)
        }
        if DEBUG then
            print("[StunService] Sending status to", player.Name, data)
        end
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
--[[
    @param preserveVelocity boolean|number? When true, horizontal velocity will not be
    zeroed during the stun. Used for knockback moves so the target continues
    moving while stunned. If a number is supplied, velocity is preserved only for
    the given duration in seconds.
]]
function StunService:ApplyStun(targetHumanoid, duration, animOrSkip, attacker, preserveVelocity)
        local targetPlayer = getPlayer(targetHumanoid)
        local attackerPlayer = getPlayer(attacker)
        if not targetPlayer or not attackerPlayer then return end

        if DEBUG then
            print("[StunService] ApplyStun", targetPlayer.Name, "duration", duration, "attacker", attackerPlayer.Name)
        end

       BlockService.StopBlocking(targetPlayer)

        if self:WasRecentlyHit(targetPlayer) then return end
        HitReservations[targetPlayer] = tick()

    local prevWalkSpeed = targetHumanoid.WalkSpeed
    local prevJumpPower = targetHumanoid.JumpPower

    local preserveVelocityDuration
    if typeof(preserveVelocity) == "number" then
        preserveVelocityDuration = preserveVelocity
        preserveVelocity = true
    end

    local existing = StunnedPlayers[targetPlayer]
    if existing then
            if existing.HRP and existing.PreserveVelocity then
                    existing.HRP:SetAttribute("StunPreserveVelocity", nil)
            end
            prevWalkSpeed = existing.PrevWalkSpeed or prevWalkSpeed
            prevJumpPower = existing.PrevJumpPower or prevJumpPower
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
        if preserveVelocity then
            hrp:SetAttribute("StunPreserveVelocity", true)
            if preserveVelocityDuration then
                task.delay(preserveVelocityDuration, function()
                    local data = StunnedPlayers[targetPlayer]
                    if data and data.HRP == hrp then
                        hrp:SetAttribute("StunPreserveVelocity", nil)
                        data.PreserveVelocity = false
                    end
                end)
            end
        end
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
                        local track = AnimationUtils.PlayAnimation(animator, stunAnimId)
                        ActiveAnimations[targetPlayer] = track
                end
        end
        local endTime = tick() + duration
        StunnedPlayers[targetPlayer] = {
            EndsAt = endTime,
            HRP = hrp,
            PrevAutoRotate = prevAutoRotate,
            PreserveVelocity = preserveVelocity,
            PrevWalkSpeed = prevWalkSpeed,
            PrevJumpPower = prevJumpPower,
        }
        sendStatus(targetPlayer)

        task.delay(duration, function()
                local data = StunnedPlayers[targetPlayer]
                if data and tick() >= data.EndsAt then
                        StunnedPlayers[targetPlayer] = nil
                        if data.HRP then
                                targetHumanoid.AutoRotate = data.PrevAutoRotate ~= nil and data.PrevAutoRotate or true
                                if data.PreserveVelocity then
                                        data.HRP:SetAttribute("StunPreserveVelocity", nil)
                                end
                        end

                        if DEBUG then
                            print("[StunService] Stun ended for", targetPlayer.Name)
                        end

                        targetHumanoid.WalkSpeed = data.PrevWalkSpeed or Config.GameSettings.DefaultWalkSpeed
                        targetHumanoid.JumpPower = data.PrevJumpPower or Config.GameSettings.DefaultJumpPower

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
        if DEBUG then
            print("[StunService] Locking attacker", attackerPlayer.Name, "for", lockoutDuration)
        end
        sendStatus(attackerPlayer)

        task.delay(lockoutDuration, function()
                if AttackerLockouts[attackerPlayer] and tick() >= unlockTime then
                        AttackerLockouts[attackerPlayer] = nil
                        if DEBUG then
                            print("[StunService] Attacker lock ended for", attackerPlayer.Name)
                        end
                        sendStatus(attackerPlayer)
                end
        end)
end

function StunService.ClearStun(player)
    local data = StunnedPlayers[player]
    if data then
        StunnedPlayers[player] = nil

        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = data.PrevAutoRotate ~= nil and data.PrevAutoRotate or true
            humanoid.WalkSpeed = data.PrevWalkSpeed or Config.GameSettings.DefaultWalkSpeed
            humanoid.JumpPower = data.PrevJumpPower or Config.GameSettings.DefaultJumpPower
        end
        if data.HRP and data.PreserveVelocity then
            data.HRP:SetAttribute("StunPreserveVelocity", nil)
        end
        local track = ActiveAnimations[player]
        if track then
            track:Stop()
            track:Destroy()
            ActiveAnimations[player] = nil
        end
        sendStatus(player)
    end
end

function StunService.LockAttacker(player, duration)
    if not RunService:IsServer() then return end
    duration = duration or (Config.GameSettings.AttackerLockoutDuration or 0.5)
    local unlockTime = tick() + duration
    AttackerLockouts[player] = unlockTime
    sendStatus(player)
    task.delay(duration, function()
        if AttackerLockouts[player] and tick() >= unlockTime then
            AttackerLockouts[player] = nil
            sendStatus(player)
        end
    end)
end

return StunService
