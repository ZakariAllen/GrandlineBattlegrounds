local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local fishingFolder

local function ensureFolders()
    local root = remotesFolder
    if not root then
        if RunService:IsServer() then
            root = Instance.new("Folder")
            root.Name = "Remotes"
            root.Parent = ReplicatedStorage
            remotesFolder = root
        else
            root = ReplicatedStorage:WaitForChild("Remotes")
            remotesFolder = root
        end
    end

    if root then
        fishingFolder = root:FindFirstChild("Fishing")
        if not fishingFolder then
            if RunService:IsServer() then
                fishingFolder = Instance.new("Folder")
                fishingFolder.Name = "Fishing"
                fishingFolder.Parent = root
            else
                fishingFolder = root:WaitForChild("Fishing")
            end
        end
    end
end

local function getRemote(name: string): RemoteEvent
    ensureFolders()
    if RunService:IsServer() then
        local evt = fishingFolder:FindFirstChild(name)
        if not evt then
            evt = Instance.new("RemoteEvent")
            evt.Name = name
            evt.Parent = fishingFolder
        end
        return evt
    end
    return fishingFolder:WaitForChild(name) :: RemoteEvent
end

return {
    RequestCast = getRemote("RequestCast"),
    RequestReel = getRemote("RequestReel"),
    BeginMinigame = getRemote("BeginMinigame"),
    MinigameResult = getRemote("MinigameResult"),
    CatchResult = getRemote("CatchResult"),
}
