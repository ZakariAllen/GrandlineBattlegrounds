--ReplicatedStorage.Modules.Combat.M1AnimationClient
local M1AnimationClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local AnimationData = require(ReplicatedStorage.Modules.Animations.Combat)

-- 🧠 Animation Track state
local currentTrack: AnimationTrack? = nil
local currentAnimId: string? = nil

-- ✅ Plays a new M1 animation and cancels the previous one
-- Plays the requested M1 animation and returns its length in seconds if
-- successfully started.
function M1AnimationClient.Play(styleKey: string, comboIndex: number)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	local animSet = AnimationData.M1[styleKey]
	if not animSet then
		warn("[M1AnimationClient] Invalid style key:", styleKey)
		return
	end

	local animId = animSet.Combo and animSet.Combo[comboIndex]
	if not animId then
		warn("[M1AnimationClient] No animation found for combo index:", comboIndex)
		return
	end

	if not tostring(animId):match("^rbxassetid://") then
		animId = "rbxassetid://" .. tostring(animId)
	end

	-- Don’t replay the same animation if it’s already playing
	if currentAnimId == animId and currentTrack and currentTrack.IsPlaying then
		return
	end

	-- Stop previous animation
	if currentTrack and currentTrack.IsPlaying then
		currentTrack:Stop(0.05)
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animId

        local track = animator:LoadAnimation(animation)
        track.Priority = Enum.AnimationPriority.Action
        track:Play()

        currentTrack = track
        currentAnimId = animId

        print("[M1AnimationClient] Played animation:", animId)

        return track.Length
end

return M1AnimationClient
