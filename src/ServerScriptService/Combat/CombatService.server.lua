local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 📦 Configs & Modules
local Config = require(ReplicatedStorage.Modules.Config.Config)
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)

print("[CombatService] Loaded")

local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local HighlightEffect = require(ReplicatedStorage.Modules.Combat.HighlightEffect)
local DamageText = require(ReplicatedStorage.Modules.Effects.DamageText)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local KnockbackService = require(ReplicatedStorage.Modules.Combat.KnockbackService)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local AnimationUtils = require(ReplicatedStorage.Modules.Effects.AnimationUtils)

-- 🔁 Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local M1Event = CombatRemotes:WaitForChild("M1Event")
local HitConfirmEvent = CombatRemotes:WaitForChild("HitConfirmEvent")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

-- 🧠 State
local comboTimestamps = {} -- [player] = { LastClick = time, CooldownEnd = time }
local activeTracks = {
        Attack = {},
        Knockback = {},
}

-- Clean up per-player state when they leave or respawn
local function cleanup(player)
    comboTimestamps[player] = nil
end

Players.PlayerRemoving:Connect(cleanup)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        cleanup(player)
    end)
end)

local function ShouldApplyHit(attacker, defender)
    -- If the defender was just hit, ignore further hits for a short window
    if StunService:WasRecentlyHit(defender) then
        return false
    end

    -- Determine which player initiated their attack first
    local atk = comboTimestamps[attacker]
    local def = comboTimestamps[defender]
    if atk and def then
        local diff = def.LastClick - atk.LastClick
        if diff > 0 and diff <= CombatConfig.M1.ClashWindow then
            -- Defender started attacking slightly earlier, so cancel this hit
            return false
        end
    end
    return true
end

-- 🎬 Play animation server-side for others
local function PlayAnimation(humanoid, animId, category)
        if not animId or not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end

        category = category or "Attack"
        local trackStore = activeTracks[category]
        local current = trackStore[humanoid]
        if current and current.IsPlaying then
                current:Stop(0.05)
        end

        local track = AnimationUtils.PlayAnimation(animator, animId)
        trackStore[humanoid] = track
end

-- 🔥 Client triggers animation (server replicates for others)
M1Event.OnServerEvent:Connect(function(player, comboIndex, styleKey)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
       if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then return end
       if BlockService.IsBlocking(player) or BlockService.IsInStartup(player) then return end

	local now = tick()
	comboTimestamps[player] = comboTimestamps[player] or { LastClick = 0, CooldownEnd = 0 }
	local state = comboTimestamps[player]

	if now < state.CooldownEnd then return end
	state.LastClick = now
	if comboIndex == CombatConfig.M1.ComboHits then
		state.CooldownEnd = now + CombatConfig.M1.ComboCooldown
	end

	local animSet = AnimationData.M1[styleKey]
	local animId = animSet and animSet.Combo and animSet.Combo[comboIndex]
	if animId then
		local attackerChar = player.Character
		local attackerHumanoid = attackerChar and attackerChar:FindFirstChildOfClass("Humanoid")
		if attackerHumanoid ~= humanoid then
			PlayAnimation(humanoid, animId, "Attack")
		end
	end
end)

-- ✅ Client confirms hit
HitConfirmEvent.OnServerEvent:Connect(function(player, targetPlayers, comboIndex, isFinal)
	if typeof(targetPlayers) ~= "table" then return end

	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

        local tool = char:FindFirstChildOfClass("Tool")
       local styleKey = tool and tool.Name or "BasicCombat"
       local damage = ToolConfig.ToolStats[styleKey] and ToolConfig.ToolStats[styleKey].M1Damage or CombatConfig.M1.DefaultM1Damage
       if HakiService.IsActive(player) then
               damage *= 1.025
       end

        local hitLanded = false
        local blockHit = false
	local animSet = AnimationData.M1[styleKey]

	for _, enemyPlayer in ipairs(targetPlayers) do
                if not enemyPlayer or not enemyPlayer.Character then continue end

                local enemyChar = enemyPlayer.Character
                local enemyHumanoid = enemyChar:FindFirstChildOfClass("Humanoid")
                if not enemyHumanoid then continue end
                if not StunService:CanBeHitBy(player, enemyPlayer) then continue end


                local blockResult = BlockService.ApplyBlockDamage(enemyPlayer, damage, false)

                -- If the enemy blocked the hit, bypass clash prevention so the
                -- block still registers even if the enemy attacked slightly
                -- earlier.
                if not blockResult and not ShouldApplyHit(player, enemyPlayer) then
                        continue
                end
                if blockResult == "Perfect" then
                        blockHit = true
                        StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), AnimationData.Stun.PerfectBlock, player)
                        local soundId = SoundConfig.Blocking.PerfectBlock
                        if soundId then
                                SoundUtils:PlaySpatialSound(soundId, hrp)
                        end
                        continue
                elseif blockResult == "Damaged" then
                        blockHit = true
                        local soundId = SoundConfig.Blocking.Block
                        if soundId then
                                SoundUtils:PlaySpatialSound(soundId, hrp)
                        end
                        continue
                elseif blockResult == "Broken" then
                        blockHit = true
                        StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), AnimationData.Stun.BlockBreak, player)
                        BlockEvent:FireClient(enemyPlayer, false)
                        local soundId = SoundConfig.Blocking.BlockBreak
                        if soundId then
                                SoundUtils:PlaySpatialSound(soundId, hrp)
                        end
                        -- fallthrough to apply damage on block break
                end

		-- ✅ Deal damage and apply stun
                enemyHumanoid:TakeDamage(damage)
                DamageText.Show(enemyHumanoid, damage)
                hitLanded = true

                local stunDuration = isFinal and CombatConfig.M1.M1_5StunDuration or CombatConfig.M1.M1StunDuration
                local preserve = isFinal and CombatConfig.M1.KnockbackDuration or false
                StunService:ApplyStun(enemyHumanoid, stunDuration, isFinal, player, preserve)

                -- 💥 Knockback logic
                if isFinal then
                        local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
                        if enemyRoot then
                                local knockback = CombatConfig.M1
                                KnockbackService.ApplyDirectionalKnockback(enemyHumanoid, {
                                        DirectionType = knockback.KnockbackDirection,
                                        AttackerRoot = hrp,
                                        TargetRoot = enemyRoot,
                                        Distance = knockback.KnockbackDistance,
                                        Duration = knockback.KnockbackDuration,
                                        Lift = knockback.KnockbackLift,
                                })

                                local knockbackAnim = animSet and animSet.Knockback
                                if knockbackAnim then
                                        PlayAnimation(enemyHumanoid, knockbackAnim, "Knockback")
                                end
                        end
                end

		-- ✨ VFX & Hit SFX
                task.delay(CombatConfig.M1.HitSoundDelay, function()
			local hitSfx = SoundConfig.Combat[styleKey] and SoundConfig.Combat[styleKey].Hit
			if hitSfx then
				SoundUtils:PlaySpatialSound(hitSfx, hrp)
			end
			HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent, Config.HitEffect.Duration)
		end)
	end

	-- ❌ Miss sound
        if not hitLanded and not blockHit then
                task.delay(CombatConfig.M1.MissSoundDelay, function()
			local missSfx = SoundConfig.Combat[styleKey] and SoundConfig.Combat[styleKey].Miss
			if missSfx then
				SoundUtils:PlaySpatialSound(missSfx, hrp)
			end
		end)
	end
end)
