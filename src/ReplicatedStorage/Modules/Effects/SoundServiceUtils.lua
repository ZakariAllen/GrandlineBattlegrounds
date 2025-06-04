--ReplicatedStorage.Modules.Effects.SoundServiceUtils

local SoundServiceUtils = {}

local MAX_HEARING_DISTANCE = 100 -- studs
local MIN_HEARING_DISTANCE = 5   -- studs
local DEFAULT_VOLUME = 1
local DEFAULT_EMITTER_SIZE = 10

function SoundServiceUtils:PlaySpatialSound(soundId: string, parent: Instance)
	if typeof(soundId) ~= "string" or not parent or not parent:IsA("Instance") then return end

	-- Normalize asset ID format
	if not soundId:match("^rbxassetid://") then
		soundId = "rbxassetid://" .. soundId
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = DEFAULT_VOLUME
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = MAX_HEARING_DISTANCE
	sound.RollOffMinDistance = MIN_HEARING_DISTANCE
	sound.EmitterSize = DEFAULT_EMITTER_SIZE
	sound.Parent = parent

	sound:Play()

	-- Cleanup after playback
	sound.Ended:Once(function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

return SoundServiceUtils
