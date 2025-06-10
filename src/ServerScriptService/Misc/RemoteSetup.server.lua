local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[RemoteSetup] Ensuring remotes exist")

local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

local function ensureEvent(parent, name)
    local evt = parent:FindFirstChild(name)
    if not evt then
        evt = Instance.new("RemoteEvent")
        evt.Name = name
        evt.Parent = parent
    end
    return evt
end

-- Root Remotes folder
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

-- Combat events
local combat = ensureFolder(remotes, "Combat")
ensureEvent(combat, "M1Event")
ensureEvent(combat, "HitConfirmEvent")
ensureEvent(combat, "BlockEvent")
ensureEvent(combat, "BlockVFX")
ensureEvent(combat, "JumpCooldownEvent")
ensureEvent(combat, "PartyTableKickStart")
ensureEvent(combat, "PartyTableKickHit")
ensureEvent(combat, "PartyTableKickStop")
ensureEvent(combat, "PartyTableKickVFX")
ensureEvent(combat, "PowerPunchStart")
ensureEvent(combat, "PowerPunchHit")
ensureEvent(combat, "PowerPunchVFX")
ensureEvent(combat, "PowerKickStart")
ensureEvent(combat, "PowerKickHit")
ensureEvent(combat, "ConcasseStart")
ensureEvent(combat, "ConcasseHit")
ensureEvent(combat, "ShiganStart")
ensureEvent(combat, "ShiganHit")
ensureEvent(combat, "TempestKickStart")
ensureEvent(combat, "TempestKickHit")
ensureEvent(combat, "TempestKickVFX")
ensureEvent(combat, "HakiEvent")
ensureEvent(combat, "TekkaiEvent")

-- Movement events
local movement = ensureFolder(remotes, "Movement")
ensureEvent(movement, "DashEvent")
ensureEvent(movement, "SprintStateEvent")
ensureEvent(movement, "TeleportEvent")
ensureEvent(movement, "EvasiveEvent")

-- Stun events
local stun = ensureFolder(remotes, "Stun")
ensureEvent(stun, "StunStatusRequestEvent")

-- UI events
local ui = ensureFolder(remotes, "UI")
ensureEvent(ui, "PlayerEnteredMenu")
ensureEvent(ui, "PlayerLeftMenu")
ensureEvent(ui, "ReturnToMenuEvent")

-- System events
local system = ensureFolder(remotes, "System")
ensureEvent(system, "SpawnRequestEvent")

print("[RemoteSetup] Remotes verified")

