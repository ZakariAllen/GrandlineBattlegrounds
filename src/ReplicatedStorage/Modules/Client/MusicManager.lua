--ReplicatedStorage.Modules.Client.MusicManager

local MusicManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local SoundConfig = require(ReplicatedStorage.Modules.Config.SoundConfig)

local currentSound

local function playSound(id: string, looped: boolean)
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
    sound.Volume = 0.5
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
