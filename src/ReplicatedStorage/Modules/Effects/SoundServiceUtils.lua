--ReplicatedStorage.Modules.Effects.SoundServiceUtils

local SoundServiceUtils = {}

local MAX_HEARING_DISTANCE = 100 -- studs
local MIN_HEARING_DISTANCE = 5   -- studs
local DEFAULT_VOLUME = 1
local DEFAULT_EMITTER_SIZE = 10

function SoundServiceUtils:PlaySpatialSound(soundInfo: any, parent: Instance)
        if not parent or not parent:IsA("Instance") then return end

        local soundId
        local pitch = 1
        local volume = DEFAULT_VOLUME

        if typeof(soundInfo) == "table" then
                soundId = soundInfo.Id
                pitch = soundInfo.Pitch or 1
                volume = soundInfo.Volume or DEFAULT_VOLUME
        elseif typeof(soundInfo) == "string" then
                soundId = soundInfo
        else
                return
        end

	-- Normalize asset ID format
	if not soundId:match("^rbxassetid://") then
		soundId = "rbxassetid://" .. soundId
	end

	local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume
        sound.PlaybackSpeed = pitch
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

function SoundServiceUtils:PlayLoopingSpatialSound(soundInfo: any, parent: Instance)
       if not parent or not parent:IsA("Instance") then return nil end

       local soundId
       local pitch = 1
       local volume = DEFAULT_VOLUME

       if typeof(soundInfo) == "table" then
               soundId = soundInfo.Id
               pitch = soundInfo.Pitch or 1
               volume = soundInfo.Volume or DEFAULT_VOLUME
       elseif typeof(soundInfo) == "string" then
               soundId = soundInfo
       else
               return nil
       end

       if not soundId:match("^rbxassetid://") then
               soundId = "rbxassetid://" .. soundId
       end

       local sound = Instance.new("Sound")
       sound.SoundId = soundId
       sound.Volume = volume
       sound.PlaybackSpeed = pitch
       sound.RollOffMode = Enum.RollOffMode.Linear
       sound.RollOffMaxDistance = MAX_HEARING_DISTANCE
       sound.RollOffMinDistance = MIN_HEARING_DISTANCE
       sound.EmitterSize = DEFAULT_EMITTER_SIZE
       sound.Looped = true
       sound.Parent = parent

       sound:Play()

       return sound
end

return SoundServiceUtils
