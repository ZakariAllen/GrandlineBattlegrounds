--ReplicatedStorage.Modules.Combat.M1InputClient
local M1InputClient = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local CombatRemotes = Remotes:WaitForChild("Combat")
local M1Event = CombatRemotes:WaitForChild("M1Event")

-- 📦 Modules
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local MoveHitboxConfig = require(ReplicatedStorage.Modules.Config.MoveHitboxConfig)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local HitboxClient = require(ReplicatedStorage.Modules.Combat.HitboxClient)
local M1AnimationClient = require(ReplicatedStorage.Modules.Combat.M1AnimationClient)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)

-- 📌 State
local comboIndex = 1
local lastClick = 0
local isAwaitingServer = false

-- 🥊 Main input handler
function M1InputClient.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end

	-- 🖱️ Handle M1
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local now = tick()
                if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() or BlockClient.IsBlocking() or isAwaitingServer then return end
		if now - lastClick < CombatConfig.M1.DelayBetweenHits then return end

		local tool = ToolController.GetEquippedTool()
		local styleKey = ToolController.GetEquippedStyleKey()
		if not tool or not styleKey or not ToolController.IsValidCombatTool() then
			warn("[M1InputClient] Invalid tool or style")
			return
		end

		print("[M1InputClient] Valid tool:", tool.Name)

		-- Reset combo if delay was too long
		if now - lastClick > CombatConfig.M1.ComboResetTime then
			comboIndex = 1
		end

                lastClick = now
                isAwaitingServer = true
                CombatConfig._lastUsedComboIndex = comboIndex

                -- 📨 Fire to server using normalized payload
                M1Event:FireServer({
                        toolName = styleKey,
                        step = comboIndex,
                        -- aimDir can be added by AI consumers; humans don't use it yet
                })
                print("[M1InputClient] ComboIndex:", comboIndex)

                -- Temporarily lock other actions only for the base delay
                -- so follow-up attacks can start exactly at DelayBetweenHits
                local lockDur = CombatConfig.M1.DelayBetweenHits
                StunStatusClient.LockFor(lockDur)

                -- 🎬 Local animation
                local animLength = M1AnimationClient.Play(styleKey, comboIndex)
                if animLength then
                        BlockClient.DisableFor(animLength)
                end

		-- 🧊 Trigger hitbox
                task.delay(CombatConfig.M1.HitDelay, function()
                        if StunStatusClient.IsStunned() then return end
                        HitboxClient.CastHitbox(
                                MoveHitboxConfig.M1.Offset,
                                MoveHitboxConfig.M1.Size,
                                MoveHitboxConfig.M1.Duration,
                                nil,
                                nil,
                                MoveHitboxConfig.M1.Shape,
                                true -- ensure miss is reported to server
                        )
                end)

		-- ⏱️ Combo advance / cooldown
		task.delay(CombatConfig.M1.DelayBetweenHits, function()
			if comboIndex == CombatConfig.M1.ComboHits then
				task.delay(CombatConfig.M1.ComboCooldown, function()
					comboIndex = 1
					isAwaitingServer = false
				end)
			else
				comboIndex += 1
				isAwaitingServer = false
			end
		end)
	end
end

-- 🧹 Input end handler
function M1InputClient.OnInputEnded(input, _)
	-- No movementKeys tracking needed anymore
end

return M1InputClient
