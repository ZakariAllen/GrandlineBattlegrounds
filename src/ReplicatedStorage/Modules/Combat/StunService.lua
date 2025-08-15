--ReplicatedStorage.Modules.Combat.StunService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DashModule = require(ReplicatedStorage.Modules.Movement.DashModule)
local ActorAdapter = require(ReplicatedStorage.Modules.AI.ActorAdapter)

-- Remotes (may not exist during tests)
local StunStatusEvent
local StunChangedEvent
local success, remotes = pcall(function()
    return ReplicatedStorage:WaitForChild("Remotes")
end)
if success and remotes then
    local stunFolder = remotes:FindFirstChild("Stun")
    if stunFolder then
        StunStatusEvent = stunFolder:FindFirstChild("StunStatusRequestEvent")
    end
    local combatFolder = remotes:FindFirstChild("Combat")
    if combatFolder then
        StunChangedEvent = combatFolder:FindFirstChild("StunChangedEvent")
    end
end

-- Lazily fetch the remote if it wasn't available at load time
local fetchedOnce = false
local function fetchStunEvent()
    if StunStatusEvent then return StunStatusEvent end
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then return nil end
    local stunFolder = remotesFolder:FindFirstChild("Stun")
    if not stunFolder then return nil end
    local evt = stunFolder:FindFirstChild("StunStatusRequestEvent")
    if not evt then return nil end
    StunStatusEvent = evt
    if not fetchedOnce then
        fetchedOnce = true
        for _, p in ipairs(Players:GetPlayers()) do
            if sendStatus then
                sendStatus(p)
            end
        end
    end
    return StunStatusEvent
end

-- Attempt to resolve the remote immediately in case RemoteSetup already ran
fetchStunEvent()

local Config = require(ReplicatedStorage.Modules.Config.Config)
local CombatAnimations = require(ReplicatedStorage.Modules.Animations.Combat)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local RagdollKnockback = require(ReplicatedStorage.Modules.Combat.RagdollKnockback)
local AnimationUtils = require(ReplicatedStorage.Modules.Effects.AnimationUtils)

local DEBUG = Config.GameSettings.DebugEnabled

local StunService = {}

-- Tables keyed by character models so players and NPCs share code paths
local StunnedEntities = {}
local AttackerLockouts = {}
local HitReservations = {}
local ActiveAnimations = {}

-- forward declaration for sendStatus so callbacks defined below can reference it
local sendStatus

local function resolveEntity(actor)
    local info = ActorAdapter.Get(actor)
    if not info or not info.Character or not info.Humanoid then
        return nil, nil, nil
    end
    return info.Character, info.Player, info.Humanoid
end

local function cleanupEntity(actor)
    local key = ActorAdapter.GetCharacter(actor) or actor
    local data = StunnedEntities[key]
    if data then
        if data.HRP and data.PreserveVelocity then
            data.HRP:SetAttribute("StunPreserveVelocity", nil)
        end
        StunnedEntities[key] = nil
    end
    AttackerLockouts[key] = nil
    HitReservations[key] = nil
    local track = ActiveAnimations[key]
    if track then
        track:Stop()
        track:Destroy()
        ActiveAnimations[key] = nil
    end
end

if RunService:IsServer() then
    Players.PlayerRemoving:Connect(cleanupEntity)
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            cleanupEntity(p)
            sendStatus(p)
        end)
    end)
    RunService.Heartbeat:Connect(function()
        for key, data in pairs(StunnedEntities) do
            local hum = data.Humanoid
            if hum then
                hum.WalkSpeed = 0
                hum.Jump = false
                hum.JumpPower = 0
            end
            local hrp = data.HRP
            if hrp then
                local v = hrp.AssemblyLinearVelocity
                if not RagdollKnockback.IsKnockbackActive(hrp)
                    and not hrp:GetAttribute("StunPreserveVelocity") then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
                elseif DEBUG then
                    local name = key and key.Name or tostring(key)
                    print("[StunService] Preserving velocity for", name)
                end
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

sendStatus = function(player)
    if RunService:IsServer() and fetchStunEvent() and player then
        local char = player.Character
        local remainingStun = 0
        local guardBroken = false
        local stunData = char and StunnedEntities[char]
        if stunData then
            remainingStun = math.max(0, stunData.EndsAt - tick())
            guardBroken = stunData.GuardBroken or false
        end

        local lockEnd = char and AttackerLockouts[char]
        local lockRemaining = lockEnd and math.max(0, lockEnd - tick()) or 0

        local data = {
            Stunned = stunData ~= nil,
            AttackerLock = lockEnd ~= nil and lockRemaining > 0,
            StunRemaining = remainingStun,
            LockRemaining = lockRemaining,
            GuardBroken = guardBroken,
        }
        if DEBUG then
            print("[StunService] Sending status to", player.Name, data)
        end
        StunStatusEvent:FireClient(player, data)
    end
end

function StunService:IsStunned(entity)
    local key = resolveEntity(entity)
    return key ~= nil and StunnedEntities[key] ~= nil
end

function StunService:IsAttackerLocked(entity)
    local key = resolveEntity(entity)
    return key ~= nil and AttackerLockouts[key] ~= nil and tick() < AttackerLockouts[key]
end

function StunService:GetStunRemaining(entity)
    local key = resolveEntity(entity)
    if key then
        local data = StunnedEntities[key]
        if data then
            return math.max(0, data.EndsAt - tick())
        end
    end
    return 0
end

function StunService:GetLockRemaining(entity)
    local key = resolveEntity(entity)
    if key then
        local endTime = AttackerLockouts[key]
        if endTime then
            return math.max(0, endTime - tick())
        end
    end
    return 0
end

function StunService:IsGuardBroken(entity)
    local key = resolveEntity(entity)
    local data = key and StunnedEntities[key]
    return data and data.GuardBroken or false
end

function StunService:EndsAt(entity)
    local key = resolveEntity(entity)
    local data = key and StunnedEntities[key]
    return data and data.EndsAt or 0
end

function StunService:WasRecentlyHit(target)
    local key = resolveEntity(target)
    local t = key and HitReservations[key]
    return t and (tick() - t < 0.1)
end

function StunService:CanBeHitBy(attacker, target)
    local atkKey = resolveEntity(attacker)
    local tgtKey = resolveEntity(target)
    if not atkKey or not tgtKey then return false end
    -- Currently all attackers may hit a stunned target
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
function StunService:ApplyStun(targetHumanoid, duration, animOrSkip, attacker, preserveVelocity, isGuardBreak)
    local targetKey, targetPlayer, targetHum = resolveEntity(targetHumanoid)
    local attackerKey, attackerPlayer = resolveEntity(attacker)
    if not targetKey or not attackerKey or not targetHum then return end

    if DEBUG then
        local tName = targetPlayer and targetPlayer.Name or targetHum.Parent and targetHum.Parent.Name
        local aName = attackerPlayer and attackerPlayer.Name or tostring(attackerKey)
        print("[StunService] ApplyStun", tName, "duration", duration, "attacker", aName)
    end

    -- Stop any active dash immediately when stunned
    DashModule.CancelDash(targetPlayer or targetHum)
    BlockService.StopBlocking(targetPlayer or targetHum)

    if self:WasRecentlyHit(targetKey) then return end
    HitReservations[targetKey] = tick()

    local prevWalkSpeed = targetHum.WalkSpeed
    local prevJumpPower = targetHum.JumpPower

    local preserveVelocityDuration
    if typeof(preserveVelocity) == "number" then
        preserveVelocityDuration = preserveVelocity
        preserveVelocity = true
    end

    local existing = StunnedEntities[targetKey]
    if existing then
        if existing.Task then
            task.cancel(existing.Task)
        end
        if existing.HRP and existing.PreserveVelocity then
            existing.HRP:SetAttribute("StunPreserveVelocity", nil)
        end
        prevWalkSpeed = existing.PrevWalkSpeed or prevWalkSpeed
        prevJumpPower = existing.PrevJumpPower or prevJumpPower
        StunnedEntities[targetKey] = nil
    end

        if ActiveAnimations[targetKey] then
                ActiveAnimations[targetKey]:Stop()
                ActiveAnimations[targetKey]:Destroy()
                ActiveAnimations[targetKey] = nil
        end

    targetHum.WalkSpeed = 0
    targetHum.JumpPower = 0
    local hrp = targetHum.Parent and targetHum.Parent:FindFirstChild("HumanoidRootPart")
    local prevAutoRotate
    if hrp then
        prevAutoRotate = targetHum.AutoRotate
        targetHum.AutoRotate = false
        -- Clear all momentum on hit so gravity takes over
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        if preserveVelocity then
            hrp:SetAttribute("StunPreserveVelocity", true)
            if preserveVelocityDuration then
                task.delay(preserveVelocityDuration, function()
                    local data = StunnedEntities[targetKey]
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

        if hrp and hrp:GetAttribute("Ragdolled") then
            skipAnim = true
        end

        if not skipAnim then
                local animator = targetHum:FindFirstChildOfClass("Animator")
                if animator and stunAnimId then
                        local track = AnimationUtils.PlayAnimation(animator, stunAnimId)
                        ActiveAnimations[targetKey] = track
                end
        end
        local endTime = tick() + duration
        local taskRef
        taskRef = task.delay(duration, function()
                local data = StunnedEntities[targetKey]
                if data and tick() >= data.EndsAt then
                        StunnedEntities[targetKey] = nil
                        if data.HRP and data.Humanoid then
                                data.Humanoid.AutoRotate = data.PrevAutoRotate ~= nil and data.PrevAutoRotate or true
                                if data.PreserveVelocity then
                                        data.HRP:SetAttribute("StunPreserveVelocity", nil)
                                end
                        end
                        if StunChangedEvent then
                                StunChangedEvent:FireAllClients(targetHum.Parent, false, false, tick())
                        end

                        if DEBUG then
                            local name = targetPlayer and targetPlayer.Name or tostring(targetKey)
                            print("[StunService] Stun ended for", name)
                        end

                        if data.Humanoid then
                            data.Humanoid.WalkSpeed = data.PrevWalkSpeed or Config.GameSettings.DefaultWalkSpeed
                            data.Humanoid.JumpPower = data.PrevJumpPower or Config.GameSettings.DefaultJumpPower
                        end

                        if ActiveAnimations[targetKey] then
                                ActiveAnimations[targetKey]:Stop()
                                ActiveAnimations[targetKey]:Destroy()
                                ActiveAnimations[targetKey] = nil
                        end
                        if targetPlayer then
                            sendStatus(targetPlayer)
                        end
                end
        end)
        StunnedEntities[targetKey] = {
            EndsAt = endTime,
            HRP = hrp,
            Humanoid = targetHum,
            PrevAutoRotate = prevAutoRotate,
            PreserveVelocity = preserveVelocity,
            PrevWalkSpeed = prevWalkSpeed,
            PrevJumpPower = prevJumpPower,
            Task = taskRef,
            GuardBroken = isGuardBreak or false,
        }
        if StunChangedEvent then
            StunChangedEvent:FireAllClients(targetHum.Parent, true, isGuardBreak or false, endTime)
        end
        if targetPlayer then
            sendStatus(targetPlayer)
        end

        local lockoutDuration = Config.GameSettings.AttackerLockoutDuration or 0.5
        local unlockTime = tick() + lockoutDuration
        AttackerLockouts[attackerKey] = unlockTime
        if DEBUG then
            local name = attackerPlayer and attackerPlayer.Name or tostring(attackerKey)
            print("[StunService] Locking attacker", name, "for", lockoutDuration)
        end
        if attackerPlayer then
            sendStatus(attackerPlayer)
        end

        task.delay(lockoutDuration, function()
                if AttackerLockouts[attackerKey] and tick() >= unlockTime then
                        AttackerLockouts[attackerKey] = nil
                        if DEBUG then
                            local name = attackerPlayer and attackerPlayer.Name or tostring(attackerKey)
                            print("[StunService] Attacker lock ended for", name)
                        end
                        if attackerPlayer then
                            sendStatus(attackerPlayer)
                        end
                end
        end)

        if not targetPlayer then
            targetHum.Destroying:Connect(function()
                cleanupEntity(targetKey)
            end)
        end
end

function StunService.ClearStun(entity)
    local key = resolveEntity(entity)
    local data = key and StunnedEntities[key]
    if data then
        if data.Task then
            task.cancel(data.Task)
        end
        StunnedEntities[key] = nil

        local humanoid = data.Humanoid
        if humanoid then
            humanoid.AutoRotate = data.PrevAutoRotate ~= nil and data.PrevAutoRotate or true
            humanoid.WalkSpeed = data.PrevWalkSpeed or Config.GameSettings.DefaultWalkSpeed
            humanoid.JumpPower = data.PrevJumpPower or Config.GameSettings.DefaultJumpPower
        end
        if data.HRP and data.PreserveVelocity then
            data.HRP:SetAttribute("StunPreserveVelocity", nil)
        end
        local track = ActiveAnimations[key]
        if track then
            track:Stop()
            track:Destroy()
            ActiveAnimations[key] = nil
        end
        local _, player = resolveEntity(entity)
        if StunChangedEvent and data.Humanoid then
            StunChangedEvent:FireAllClients(data.Humanoid.Parent, false, false, tick())
        end
        if player then
            sendStatus(player)
        end
    end
end

function StunService.LockAttacker(entity, duration)
    if not RunService:IsServer() then return end
    local key, player = resolveEntity(entity)
    if not key then return end
    duration = duration or (Config.GameSettings.AttackerLockoutDuration or 0.5)
    local unlockTime = tick() + duration
    AttackerLockouts[key] = unlockTime
    if player then
        sendStatus(player)
    end
    task.delay(duration, function()
        if AttackerLockouts[key] and tick() >= unlockTime then
            AttackerLockouts[key] = nil
            if player then
                sendStatus(player)
            end
        end
    end)
end

return StunService
