local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local WorldConfig = require(Modules.Config.WorldConfig)
local TerrainNoise = require(Modules.World.TerrainNoise)
local FishingRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FishingRemotes"))
local RodConfig = require(Modules.Fishing:WaitForChild("RodConfig"))
local FishCatalog = require(Modules.Fishing:WaitForChild("FishCatalog"))
local MiniGameConfig = require(Modules.Fishing:WaitForChild("MiniGameConfig"))
local CastConfig = require(Modules.Fishing:WaitForChild("CastConfig"))
local LineConfig = require(Modules.Fishing:WaitForChild("LineConfig"))

local sessions: { [Player]: any } = {}
local rng = Random.new()

local DEFAULT_COOLDOWN = 1.25
local SUCCESS_COOLDOWN = 0.85

local RARITIES = FishCatalog.Rarities or {}
local LOCATIONS = FishCatalog.Locations or {}
local FISH = FishCatalog.Fish or {}
local DEFAULT_LOCATION_ID = FishCatalog.DefaultLocation or "Shores"

local function setLineState(player: Player, enabled: boolean)
    player:SetAttribute("FishingLineOut", enabled)
end

local function setCooldown(player: Player, seconds: number)
    player:SetAttribute("NextCastTime", os.clock() + seconds)
end

local function destroyBobber(session)
    if session and session.bobber then
        session.bobber:Destroy()
        session.bobber = nil
    end
end

local function cleanupSession(player: Player)
    local session = sessions[player]
    if not session then
        return
    end
    destroyBobber(session)
    setLineState(player, false)
    sessions[player] = nil
end

local function resolveLocation(sample): string
    if sample.type ~= "Water" then
        return DEFAULT_LOCATION_ID
    end
    local depth = math.clamp((WorldConfig.Noise.WaterThreshold - sample.elevation) * 6, 0, 1)
    if depth > 0.35 then
        return "Deep"
    end
    return "Shores"
end

local function rollRarity(): (string?, any?)
    local entries = {}
    local total = 0
    for rarityId, rarity in pairs(RARITIES) do
        local chance = rarity.chance or 0
        if chance > 0 then
            total += chance
            table.insert(entries, { id = rarityId, threshold = total, def = rarity })
        end
    end
    if total <= 0 then
        return entries[1] and entries[1].id or nil, entries[1] and entries[1].def or nil
    end
    local pick = rng:NextNumber(0, total)
    for _, entry in ipairs(entries) do
        if pick <= entry.threshold then
            return entry.id, entry.def
        end
    end
    local fallback = entries[#entries]
    return fallback and fallback.id or nil, fallback and fallback.def or nil
end

local function matchesLocation(fish, locationId: string): boolean
    if locationId == "Shores" then
        return true
    end
    if fish.locations and #fish.locations > 0 then
        for _, locId in ipairs(fish.locations) do
            if locId == locationId then
                return true
            end
        end
        return false
    end
    return true
end

local function gatherFish(locationId: string, rarityId: string?)
    local results = {}
    for _, fish in pairs(FISH) do
        if (not rarityId or fish.rarity == rarityId) and matchesLocation(fish, locationId) then
            table.insert(results, fish)
        end
    end
    return results
end

local function chooseFish(luckBonus: number?, locationId: string?): (any, any)
    local rarityId, rarityDef = rollRarity()
    local resolvedLocation = locationId or DEFAULT_LOCATION_ID
    local candidates = gatherFish(resolvedLocation, rarityId)
    if #candidates == 0 then
        candidates = gatherFish(resolvedLocation, nil)
    end
    if #candidates == 0 then
        for _, fish in pairs(FISH) do
            table.insert(candidates, fish)
        end
    end
    assert(#candidates > 0, "Fish catalog is empty")

    local luck = math.max(luckBonus or 0, 0)
    local total = 0
    local weights = table.create(#candidates)
    for index, fish in ipairs(candidates) do
        local chanceMultiplier = math.max(fish.chanceMultiplier or 1, 0)
        local fishBias = fish.luckBias or 0
        local modifier = math.max(1 + luck * fishBias, 0)
        local weight = chanceMultiplier * modifier
        weights[index] = weight
        total += weight
    end

    if total <= 0 then
        return candidates[1], rarityDef
    end
    local pick = rng:NextNumber(0, total)
    local running = 0
    for index, fish in ipairs(candidates) do
        running += weights[index]
        if pick <= running then
            return fish, rarityDef
        end
    end
    return candidates[#candidates], rarityDef
end

local function makeBobber(target: Vector3)
    local bobber = Instance.new("Part")
    bobber.Anchored = true
    bobber.Shape = Enum.PartType.Ball
    bobber.Material = Enum.Material.Neon
    bobber.Size = Vector3.new(0.8, 0.8, 0.8)
    bobber.Color = Color3.fromRGB(255, 174, 92)
    bobber.CanCollide = false
    bobber.CanQuery = false
    bobber.CanTouch = false
    bobber.Name = "Bobber"
    bobber.Position = target + Vector3.new(0, LineConfig.Casting.FloatOffset or 0.4, 0)
    bobber.Parent = Workspace
    return bobber
end

local function beginMinigame(player: Player)
    local session = sessions[player]
    if not session or session.state ~= "waiting" then
        return
    end
    session.state = "minigame"

    local rarityDef = RARITIES[session.rarityId or ""] or {}
    local goalScale = rarityDef.goalScale or 1
    local captureGoal = (MiniGameConfig.Capture and MiniGameConfig.Capture.Goal or 10) * goalScale

    FishingRemotes.BeginMinigame:FireClient(player, {
        fish = session.fish,
        rarity = session.rarityId,
        rod = session.rod,
        captureGoal = captureGoal,
    })
end

local function startBiteTimer(player: Player)
    local session = sessions[player]
    if not session then
        return
    end
    local rod = session.rod
    local biteRange = rod.biteTime or LineConfig.BiteDefaults or MiniGameConfig.BiteTimeRange or NumberRange.new(12, 18)
    local waitTime = rng:NextNumber(biteRange.Min, biteRange.Max)
    local lureSpeed = rod.lureSpeed or 10
    waitTime = math.max(waitTime / math.max(lureSpeed, 1), biteRange.Min * 0.35)
    if session.sample and session.sample.hotspot then
        waitTime *= 0.6
    end
    task.delay(waitTime, function()
        if sessions[player] == session then
            beginMinigame(player)
        end
    end)
end

local function handleRequestCast(player: Player, rodId: string, target: Vector3, payload)
    local rod = RodConfig[rodId]
    if not rod then
        return
    end

    local now = os.clock()
    local nextAllowed = player:GetAttribute("NextCastTime") or 0
    if now < nextAllowed then
        return
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp and rod.castRange then
        local dist = (target - hrp.Position).Magnitude
        if dist > rod.castRange * 1.2 then
            setCooldown(player, DEFAULT_COOLDOWN)
            return
        end
    end

    cleanupSession(player)

    local sample = TerrainNoise.SampleFromWorldPosition(target)
    if sample.type ~= "Water" then
        FishingRemotes.CatchResult:FireClient(player, {
            success = false,
            reason = "Cast into water to fish.",
        })
        setCooldown(player, DEFAULT_COOLDOWN)
        return
    end

    local locationId = resolveLocation(sample)
    local luckBonus = (payload and payload.luckBonus) or 0
    if sample.hotspot then
        luckBonus += CastConfig.MaxLuckBonus or 0.1
    end

    local fish, rarityDef = chooseFish(luckBonus, locationId)
    local bobber = makeBobber(target)
    setLineState(player, true)
    setCooldown(player, 0.25)

    sessions[player] = {
        state = "waiting",
        rodId = rodId,
        rod = rod,
        fish = fish,
        rarityId = fish and fish.rarity,
        rarityDef = rarityDef,
        sample = sample,
        bobber = bobber,
    }

    startBiteTimer(player)
end

local function handleMinigameResult(player: Player, data)
    local session = sessions[player]
    if not session or session.state ~= "minigame" then
        return
    end

    local success = data and data.success
    if success then
        FishingRemotes.CatchResult:FireClient(player, {
            success = true,
            fish = session.fish and session.fish.displayName or "a fish",
            value = session.fish and session.fish.value or 0,
        })
        setCooldown(player, SUCCESS_COOLDOWN)
    else
        FishingRemotes.CatchResult:FireClient(player, {
            success = false,
            reason = "The fish escaped.",
        })
        setCooldown(player, DEFAULT_COOLDOWN)
    end

    cleanupSession(player)
end

local function handleReel(player: Player)
    cleanupSession(player)
    setCooldown(player, DEFAULT_COOLDOWN * 0.5)
end

FishingRemotes.RequestCast.OnServerEvent:Connect(handleRequestCast)
FishingRemotes.RequestReel.OnServerEvent:Connect(handleReel)
FishingRemotes.MinigameResult.OnServerEvent:Connect(handleMinigameResult)

local function onPlayerRemoving(player: Player)
    cleanupSession(player)
end

local function onPlayerAdded(player: Player)
    player:SetAttribute("GameplayUnlocked", true)
    player:SetAttribute("NextCastTime", 0)
    setLineState(player, false)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
