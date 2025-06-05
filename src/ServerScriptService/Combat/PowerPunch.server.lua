local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("PowerPunchStart")
local HitEvent = CombatRemotes:WaitForChild("PowerPunchHit")
local VFXEvent = CombatRemotes:WaitForChild("PowerPunchVFX")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local PowerPunchConfig = AbilityConfig.BasicCombat.PowerPunch
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local MoveSoundConfig = require(ReplicatedStorage.Modules.Config.MoveSoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local KnockbackService = require(ReplicatedStorage.Modules.Combat.KnockbackService)
local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

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

    track.Stopped:Connect(function()
        if activeTracks[humanoid] == track then
            activeTracks[humanoid] = nil
        end
    end)
end

StartEvent.OnServerEvent:Connect(function(player)
    if DEBUG then print("[PowerPunch] StartEvent from", player.Name) end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "Basic Combat" then return end
    if not StaminaService.Consume(player, 20) then return end
    playAnimation(humanoid, AnimationData.SpecialMoves.PowerPunch)
    VFXEvent:FireAllClients(player)
end)

HitEvent.OnServerEvent:Connect(function(player, targets, dir)
    if DEBUG then print("[PowerPunch] HitEvent from", player.Name) end
    if typeof(targets) ~= "table" then return end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "Basic Combat" then return end

    local hitLanded = false

    for _, enemyPlayer in ipairs(targets) do
        local enemyChar = enemyPlayer.Character
        local enemyHumanoid = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid then continue end
        if not StunService:CanBeHitBy(player, enemyPlayer) then continue end

        local blockResult = BlockService.ApplyBlockDamage(enemyPlayer, PowerPunchConfig.Damage, true)
        if blockResult == "Perfect" then
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), false, enemyPlayer)
            BlockEvent:FireClient(enemyPlayer, false)
            continue
        elseif blockResult == "Damaged" then
            continue
        elseif blockResult == "Broken" then
            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), false, player)
            BlockEvent:FireClient(enemyPlayer, false)
            continue
        end

        enemyHumanoid:TakeDamage(PowerPunchConfig.Damage)
        hitLanded = true
        HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent)
        StunService:ApplyStun(enemyHumanoid, PowerPunchConfig.StunDuration, true, player)

        local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
        local knockback = CombatConfig.M1
        local kbDir = KnockbackService.ComputeDirection(
            PowerPunchConfig.KnockbackDirection or knockback.KnockbackDirection,
            hrp,
            enemyRoot,
            typeof(dir) == "Vector3" and dir or nil
        )
        KnockbackService.ApplyKnockback(enemyHumanoid, kbDir, knockback.KnockbackDistance, knockback.KnockbackDuration, knockback.KnockbackLift)

        local knockbackAnim = AnimationData.M1.BasicCombat and AnimationData.M1.BasicCombat.Knockback
        if knockbackAnim then
            playAnimation(enemyHumanoid, knockbackAnim)
        end
    end

    if hitLanded then
        local hitSfx = MoveSoundConfig.PowerPunch and MoveSoundConfig.PowerPunch.Hit
        if hitSfx then
            SoundUtils:PlaySpatialSound(hitSfx, hrp)
        end
    end
end)

return nil
