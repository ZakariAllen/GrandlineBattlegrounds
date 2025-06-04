local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PartyTableKickStart")
local HitEvent = CombatRemotes:WaitForChild("PartyTableKickHit")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)

local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

local activeTracks = {}

local function playAnimation(humanoid, animId)
    if not animId or not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    animId = tostring(animId)
    if not animId:match("^rbxassetid://") then
        animId = "rbxassetid://" .. animId
    end

    local current = activeTracks[humanoid]
    if current and current.IsPlaying then
        current:Stop(0.05)
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action
    track:Play()

    activeTracks[humanoid] = track
end

StartEvent.OnServerEvent:Connect(function(player)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "Black Leg" then return end
    playAnimation(humanoid, AnimationData.SpecialMoves.PartyTableKick)
end)

HitEvent.OnServerEvent:Connect(function(player, targets, isFinal)
    if typeof(targets) ~= "table" then return end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "Black Leg" then return end

    local cfg = AbilityConfig.BlackLeg.PartyTableKick

    for _, enemyPlayer in ipairs(targets) do
        local enemyChar = enemyPlayer.Character
        local enemyHumanoid = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid then continue end
        if not StunService:CanBeHitBy(player, enemyPlayer) then continue end

        local blockResult = BlockService.ApplyBlockDamage(enemyPlayer, cfg.DamagePerHit, false)
        if blockResult == "Perfect" then
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), false, enemyPlayer)
            playAnimation(humanoid, AnimationData.Stun.PerfectBlock)
            BlockEvent:FireClient(enemyPlayer, false)
            continue
        elseif blockResult == "Damaged" then
            continue
        elseif blockResult == "Broken" then
            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), false, player)
            BlockEvent:FireClient(enemyPlayer, false)
            continue
        end

        enemyHumanoid:TakeDamage(cfg.DamagePerHit)
        local stunDur = isFinal and CombatConfig.M1.M1_5StunDuration or cfg.StunDuration
        StunService:ApplyStun(enemyHumanoid, stunDur, isFinal, player)

        if isFinal then
            local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                local dir = hrp.CFrame.LookVector
                local knockback = CombatConfig.M1
                local velocity = dir * (knockback.KnockbackDistance / knockback.KnockbackDuration)
                velocity = Vector3.new(velocity.X, knockback.KnockbackLift, velocity.Z)

                local bv = Instance.new("BodyVelocity")
                bv.Velocity = velocity
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.P = 1500
                bv.Parent = enemyRoot
                Debris:AddItem(bv, knockback.KnockbackDuration)

                enemyRoot.CFrame = CFrame.new(enemyRoot.Position, enemyRoot.Position - dir)
            end
        end

        task.delay(0.05, function()
            local hitSfx = SoundConfig.Combat.BlackLeg and SoundConfig.Combat.BlackLeg.Hit
            if hitSfx then
                SoundUtils:PlaySpatialSound(hitSfx, hrp)
            end
            HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent)
        end)
    end
end)
