local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

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
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)

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

-- 🎬 Play animation server-side for others
local function PlayAnimation(humanoid, animId, category)
	if not animId or not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	animId = tostring(animId)
	if not animId:match("^rbxassetid://") then
		animId = "rbxassetid://" .. animId
	end

	category = category or "Attack"
	local trackStore = activeTracks[category]
	local current = trackStore[humanoid]
	if current and current.IsPlaying then
		current:Stop(0.05)
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	track:Play()

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
	local styleKey = (tool and tool.Name or "Basic Combat"):gsub(" ", "")
	local damage = ToolConfig.ToolStats[styleKey] and ToolConfig.ToolStats[styleKey].M1Damage or Config.GameSettings.DefaultM1Damage

	local hitLanded = false
	local animSet = AnimationData.M1[styleKey]

	for _, enemyPlayer in ipairs(targetPlayers) do
		if not enemyPlayer or not enemyPlayer.Character then continue end

		local enemyChar = enemyPlayer.Character
		local enemyHumanoid = enemyChar:FindFirstChildOfClass("Humanoid")
		if not enemyHumanoid then continue end
		if not StunService:CanBeHitBy(player, enemyPlayer) then continue end

               local blockResult = BlockService.ApplyBlockDamage(enemyPlayer, damage, false)
                if blockResult == "Perfect" then
                        StunService:ApplyStun(humanoid, BlockService.GetPerfectBlockStunDuration(), AnimationData.Stun.PerfectBlock, enemyPlayer)
                        BlockEvent:FireClient(enemyPlayer, false)
                        continue
                elseif blockResult == "Damaged" then
                        continue
                elseif blockResult == "Broken" then
                        StunService:ApplyStun(enemyHumanoid, BlockService.GetBlockBreakStunDuration(), AnimationData.Stun.BlockBreak, player)
                        BlockEvent:FireClient(enemyPlayer, false)
                        continue
                end

		-- ✅ Deal damage and apply stun
		enemyHumanoid:TakeDamage(damage)
		hitLanded = true

		local stunDuration = isFinal and CombatConfig.M1.M1_5StunDuration or CombatConfig.M1.M1StunDuration
		StunService:ApplyStun(enemyHumanoid, stunDuration, isFinal, player)

		-- 💥 Knockback logic
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

				local knockbackAnim = animSet and animSet.Knockback
				if knockbackAnim then
					PlayAnimation(enemyHumanoid, knockbackAnim, "Knockback")
				end
			end
		end

		-- ✨ VFX & Hit SFX
		task.delay(Config.GameSettings.HitSoundDelay, function()
			local hitSfx = SoundConfig.Combat[styleKey] and SoundConfig.Combat[styleKey].Hit
			if hitSfx then
				SoundUtils:PlaySpatialSound(hitSfx, hrp)
			end
			HighlightEffect.ApplyHitHighlight(enemyHumanoid.Parent, Config.HitEffect.Duration)
		end)
	end

	-- ❌ Miss sound
	if not hitLanded then
		task.delay(Config.GameSettings.MissSoundDelay, function()
			local missSfx = SoundConfig.Combat[styleKey] and SoundConfig.Combat[styleKey].Miss
			if missSfx then
				SoundUtils:PlaySpatialSound(missSfx, hrp)
			end
		end)
	end
end)
