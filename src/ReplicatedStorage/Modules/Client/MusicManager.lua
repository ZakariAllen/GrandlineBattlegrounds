--ReplicatedStorage.Modules.Client.MusicManager

local MusicManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)

local currentSound

-- Plays the given sound info which can be a string ID or a table { Id, Pitch, Volume }
local function playSound(soundInfo: any, looped: boolean)
    if not soundInfo then return nil end

    local id
    local pitch = 1
    local volume = 0.5

    if typeof(soundInfo) == "table" then
        id = soundInfo.Id
        pitch = soundInfo.Pitch or 1
        volume = soundInfo.Volume or 0.5
    else
        id = soundInfo
    end

    if not id or id == "" then return nil end
    if not id:match("^rbxassetid://") then
        id = "rbxassetid://" .. id
    end

    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end

    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = volume
    sound.PlaybackSpeed = pitch
    sound.Looped = looped or false
    sound.Parent = workspace
    sound:Play()

    currentSound = sound
    return sound
end

function MusicManager.PlayMenuMusic()
    playSound(SoundConfig.Music.MainMenuMusic, true)
end

function MusicManager.StartGameplayMusic()
    local pool = SoundConfig.Music.MusicPool
    if not pool or #pool == 0 then return end

    local function playRandom()
        local index = math.random(1, #pool)
        local track = playSound(pool[index], false)
        if track then
            track.Ended:Once(playRandom)
        end
    end

    playRandom()
end

function MusicManager.Stop()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end
end

return MusicManager
