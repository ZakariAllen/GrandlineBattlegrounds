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
local EvasiveService = require(ReplicatedStorage.Modules.Stats.EvasiveService)
local SoundUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local RagdollKnockback = require(ReplicatedStorage.Modules.Combat.RagdollKnockback)
local HakiService = require(ReplicatedStorage.Modules.Stats.HakiService)
local UltService = require(ReplicatedStorage.Modules.Stats.UltService)
local UltConfig = require(ReplicatedStorage.Modules.Config.UltConfig)
local XPService = require(ReplicatedStorage.Modules.Stats.ExperienceService)
local XPConfig = require(ReplicatedStorage.Modules.Config.XPConfig)
local PersistentStats = require(ReplicatedStorage.Modules.Stats.PersistentStatsService)
local AnimationUtils = require(ReplicatedStorage.Modules.Effects.AnimationUtils)
local M1Service = require(script.Parent.M1Service)
local comboTimestamps = M1Service.ComboTimestamps -- shared state for attack timings

-- 🔁 Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemotes = Remotes:WaitForChild("Combat")
local M1Event = CombatRemotes:WaitForChild("M1Event")
local HitConfirmEvent = CombatRemotes:WaitForChild("HitConfirmEvent")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

-- 🧠 State
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

    -- Cancel simultaneous attacks if the defender initiated their swing first
    local atk = comboTimestamps[attacker]
    local def = comboTimestamps[defender]
    if atk and def then
        local diff = atk.LastClick - def.LastClick
        if diff > 0 and math.abs(diff) <= CombatConfig.M1.ClashWindow then
            -- Defender's earlier attack connected, so ignore this hit
            if StunService:WasRecentlyHit(attacker) then
                return false
            end
        end
    end
    return true
end

-- Resolve arbitrary instances into combat targets
local function resolveTarget(entry)
    if typeof(entry) ~= "Instance" then return nil end
    if entry:IsA("Player") then
        local char = entry.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            return {Key = entry, Player = entry, Humanoid = hum}
        end
        return nil
    end
    local model = entry:IsA("Model") and entry or entry:FindFirstAncestorOfClass("Model")
    if model then
        local player = Players:GetPlayerFromCharacter(model)
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum then
            return {Key = player or hum, Player = player, Humanoid = hum}
        end
    end
    return nil
end

-- 🧹 Ensure targets are valid and remove duplicates
local function sanitizeTargets(list)
        local cleaned = {}
        local added = {}
        for _, entry in ipairs(list) do
                local target = resolveTarget(entry)
                if target and not added[target.Key] then
                        added[target.Key] = true
                        table.insert(cleaned, target)
                end
        end
        return cleaned
end

local function getStyleKeyFromTool(tool)
        if tool and ToolConfig.ValidCombatTools[tool.Name] then
                return tool.Name
        end
        return "BasicCombat"
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
M1Event.OnServerEvent:Connect(function(player, payload)
        M1Service.ProcessM1Request(player, payload)
end)

-- ✅ Client confirms hit
HitConfirmEvent.OnServerEvent:Connect(function(player, targetPlayers, comboIndex, isFinal, originCF, size, travelDistance)
        if typeof(comboIndex) ~= "number" then return end
        comboIndex = math.floor(comboIndex)
        if comboIndex < 1 or comboIndex > CombatConfig.M1.ComboHits then return end

        if typeof(targetPlayers) ~= "table" then
                targetPlayers = {}
        end

        local char = player.Character
        if not char then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return end

        travelDistance = (typeof(travelDistance) == "number") and travelDistance or 0

        if typeof(originCF) ~= "CFrame" then originCF = nil end
        if typeof(size) ~= "Vector3" then size = nil end

        local serverTargets = sanitizeTargets(targetPlayers)
        if originCF and size then
                local castCF = originCF
                if travelDistance ~= 0 then
                        castCF = castCF + castCF.LookVector * travelDistance
                end

                local params = OverlapParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { char }

                serverTargets = {}
                local added = {}
                for _, part in ipairs(workspace:GetPartBoundsInBox(castCF, size, params)) do
                        local target = resolveTarget(part)
                        if target and target.Key ~= player and not added[target.Key] then
                                added[target.Key] = true
                                table.insert(serverTargets, target)
                        end
                end
        end

        local tool = char:FindFirstChildOfClass("Tool")
       local styleKey = getStyleKeyFromTool(tool)
       local damage = ToolConfig.ToolStats[styleKey] and ToolConfig.ToolStats[styleKey].M1Damage or CombatConfig.M1.DefaultM1Damage
       if HakiService.IsActive(player) then
               damage *= 1.025
       end

        local hitLanded = false
        local blockHit = false
	local animSet = AnimationData.M1[styleKey]

        local maxRange = CombatConfig.M1.ServerHitRange or 12
        local attackPos
        if originCF then
                attackPos = originCF.Position
                if travelDistance ~= 0 then
                        attackPos = attackPos + originCF.LookVector * travelDistance
                end
        end
        for _, target in ipairs(serverTargets) do
                local enemyPlayer = target.Player
                local enemyHumanoid = target.Humanoid
                if not enemyHumanoid or enemyHumanoid.Health <= 0 then continue end
                if enemyPlayer and EvasiveService and EvasiveService.IsActive(enemyPlayer) then
                        continue
                end
                if not StunService:CanBeHitBy(player, target.Key) then continue end
                if not ShouldApplyHit(player, target.Key) then continue end

                local enemyRoot = enemyHumanoid.Parent and enemyHumanoid.Parent:FindFirstChild("HumanoidRootPart")
                if not enemyRoot then continue end

                local distOrigin = hrp.Position
                if attackPos then
                        distOrigin = attackPos
                end
                if (enemyRoot.Position - distOrigin).Magnitude > maxRange then
                        continue
                end

               local blockResult = BlockService.ApplyBlockDamage(target.Key, damage, false, hrp)
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
                        if enemyPlayer then
                                BlockEvent:FireClient(enemyPlayer, false)
                        end
                        local soundId = SoundConfig.Blocking.BlockBreak
                        if soundId then
                                SoundUtils:PlaySpatialSound(soundId, hrp)
                        end
                        -- fallthrough to apply damage on block break
               end

		-- ✅ Deal damage and apply stun
                enemyHumanoid:TakeDamage(damage)
                DamageText.Show(enemyHumanoid, damage)
                PersistentStats.RecordHit(player, enemyHumanoid, damage)
                UltService.RegisterHit(player, enemyHumanoid, UltConfig.M1s)
                XPService.RegisterHit(player, enemyHumanoid, XPConfig.M1)
                hitLanded = true

                local stunDuration = isFinal and CombatConfig.M1.M1_5StunDuration or CombatConfig.M1.M1StunDuration
                local preserve = isFinal and 0.5 or false
                StunService:ApplyStun(enemyHumanoid, stunDuration, isFinal, player, preserve)

                -- 💥 Knockback logic
                local enemyDied = enemyHumanoid.Health <= 0
                if (isFinal or enemyDied) and enemyRoot then
                        RagdollKnockback.ApplyDirectionalKnockback(enemyHumanoid, {
                                DirectionType = RagdollKnockback.DirectionType.AttackerFacingDirection,
                                AttackerRoot = hrp,
                                TargetRoot = enemyRoot,
                        })
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
