--ReplicatedStorage.Modules.Client.MusicManager

--[[
    Simple utility for playing menu and gameplay music on the client.
    This version avoids cross-game dependencies and only references
    modules that exist within this project.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local configFolder = modulesFolder:WaitForChild("Config")
local SoundConfig = require(configFolder:WaitForChild("SoundConfig"))

local MusicManager = {}

local currentSound: Sound?

-- Plays the given sound info which can be a string ID or a table { Id, Pitch, Volume }
local function playSound(soundInfo: any, looped: boolean)
    if not soundInfo then
        return nil
    end

    local id = ""
    local pitch = 1
    local volume = 0.5

    if typeof(soundInfo) == "table" then
        id = soundInfo.Id or ""
        pitch = soundInfo.Pitch or 1
        volume = soundInfo.Volume or 0.5
    else
        id = soundInfo
    end

    if id == "" then
        return nil
    end
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
    sound.Parent = SoundService
    sound:Play()

    currentSound = sound
    return sound
end

function MusicManager.PlayMenuMusic()
    playSound(SoundConfig.Music.MainMenuMusic, true)
end

function MusicManager.StartGameplayMusic()
    local pool = SoundConfig.Music.MusicPool
    if typeof(pool) ~= "table" or #pool == 0 then
        return
    end

    local function playRandom()
        local track = pool[math.random(1, #pool)]
        local sound = playSound(track, false)
        if sound then
            sound.Ended:Once(playRandom)
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
