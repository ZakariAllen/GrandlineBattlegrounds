local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local StartEvent = CombatRemotes:WaitForChild("ConcasseStart")
local HitEvent = CombatRemotes:WaitForChild("ConcasseHit")
local RunService = game:GetService("RunService")

local AbilityConfig = require(ReplicatedStorage.Modules.Config.AbilityConfig)
local ConcasseConfig = AbilityConfig.BlackLeg.Concasse
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local DamageText = require(ReplicatedStorage.Modules.Effects.DamageText)
local MoveSoundConfig = require(ReplicatedStorage.Modules.Config.MoveSoundConfig)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
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

local function stopAnimation(humanoid)
    local current = activeTracks[humanoid]
    if current and current.IsPlaying then
        current:Stop(0.05)
    end
    activeTracks[humanoid] = nil
end

StartEvent.OnServerEvent:Connect(function(player, targetPos)
    if DEBUG then print("[Concasse] StartEvent from", player.Name) end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        if DEBUG then print("[Concasse] No humanoid") end
        return
    end
    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then
        if DEBUG then print("[Concasse] Player stunned or locked") end
        return
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[Concasse] Invalid tool") end
        return
    end
    if not StaminaService.Consume(player, 20) then
        if DEBUG then print("[Concasse] Not enough stamina") end
        return
    end
    playAnimation(humanoid, AnimationData.SpecialMoves.PowerKick)
    if DEBUG then print("[Concasse] Animation triggered") end

    if typeof(targetPos) == "Vector3" and hrp then
        local start = hrp.Position
        local dir = targetPos - start
        local horiz = Vector3.new(dir.X, 0, dir.Z)
        local dist = horiz.Magnitude
        if dist > (ConcasseConfig.Range or 65) then
            horiz = horiz.Unit * (ConcasseConfig.Range or 65)
            dist = (ConcasseConfig.Range or 65)
        end
        local dest = start + horiz

        -- Temporarily anchor to keep the character stable while the
        -- client animates the actual movement. The server simply
        -- teleports to the final position after the travel time to
        -- avoid fighting against client-side interpolation.
        local prevAnchor = hrp.Anchored
        local prevPlat = humanoid.PlatformStand
        local prevAuto = humanoid.AutoRotate
        hrp.Anchored = true
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false

        -- Travel time is derived from a constant travel speed so the
        -- move feels the same at any distance
        local travelTime = (ConcasseConfig.TravelTime or (dist / (ConcasseConfig.TravelSpeed or 10)))

        task.delay(travelTime, function()
            hrp.CFrame = CFrame.new(dest)
            hrp.Anchored = prevAnchor
            humanoid.PlatformStand = prevPlat
            humanoid.AutoRotate = prevAuto
        end)
    end
end)

HitEvent.OnServerEvent:Connect(function(player, targets, dir)
    if DEBUG then print("[Concasse] HitEvent from", player.Name) end
    if typeof(targets) ~= "table" then
        if DEBUG then print("[Concasse] Invalid targets") end
        return
    end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        if DEBUG then print("[Concasse] Missing humanoid or HRP") end
        return
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BlackLeg" then
        if DEBUG then print("[Concasse] Invalid tool during hit") end
        return
    end
    if humanoid.FloorMaterial == Enum.Material.Air then
        if DEBUG then print("[Concasse] Hit attempted before landing") end
        return
    end

    local hitLanded = false

    for _, enemyPlayer in ipairs(targets) do
        local enemyChar = enemyPlayer.Character
        local enemyHumanoid = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid then
            if DEBUG then print("[Concasse] Target has no humanoid") end
            continue
        end
        if not StunService:CanBeHitBy(player, enemyPlayer) then
            if DEBUG then print("[Concasse] Cannot hit", enemyPlayer.Name) end
            continue
        end

        local blockResult = BlockService.ApplyBlockDamage(enemyPlayer, ConcasseConfig.Damage, false)
        if blockResult == "Perfect" then
            if DEBUG then print("[Concasse] Perfect block by", enemyPlayer.Name) end
            stopAnimation(humanoid)
            StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), AnimationData.Stun.PerfectBlock, player)
            local soundId = SoundConfig.Blocking.PerfectBlock
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end
            continue
        elseif blockResult == "Damaged" then
            if DEBUG then print("[Concasse] Block damaged", enemyPlayer.Name) end
            continue
        elseif blockResult == "Broken" then
            if DEBUG then print("[Concasse] Block broken", enemyPlayer.Name) end
            BlockEvent:FireClient(enemyPlayer, false)

            local soundId = SoundConfig.Blocking.BlockBreak
            if soundId then
                SoundUtils:PlaySpatialSound(soundId, hrp)
            end

            StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), true, player, true)
            -- fallthrough to apply damage on block break
        end

        local dmg = ConcasseConfig.Damage
        if HakiService.IsActive(player) then
            dmg *= 1.025
        end
        enemyHumanoid:TakeDamage(dmg)
        DamageText.Show(enemyHumanoid, dmg)
        if DEBUG then print("[Concasse] Hit", enemyPlayer.Name, "for", dmg) end
        hitLanded = true
        HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent)

        StunService:ApplyStun(enemyHumanoid, ConcasseConfig.StunDuration, false, player, true)
    end

    if hitLanded then
        local hitSfx = MoveSoundConfig.Concasse and MoveSoundConfig.Concasse.Hit
        if hitSfx then
            SoundUtils:PlaySpatialSound(hitSfx, hrp)
        end
    end
end)

return nil
