local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MovementRemotes = Remotes:WaitForChild("Movement")
local TeleportEvent = MovementRemotes:WaitForChild("TeleportEvent")

local RokushikiConfig = require(ReplicatedStorage.Modules.Config.Tools.Rokushiki)
local TeleportConfig = RokushikiConfig.Teleport
local StunService = require(ReplicatedStorage.Modules.Combat.StunService)
local BlockService = require(ReplicatedStorage.Modules.Combat.BlockService)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local SoundServiceUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local TeleportVFX = require(ReplicatedStorage.Modules.Effects.TeleportVFX)
local Config = require(ReplicatedStorage.Modules.Config.Config)

local DEBUG = Config.GameSettings.DebugEnabled

TeleportEvent.OnServerEvent:Connect(function(player, position)
    if typeof(position) ~= "Vector3" then return end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    if StunService:IsStunned(player) or StunService:IsAttackerLocked(player) then return end
    if BlockService.IsBlocking(player) or BlockService.IsInStartup(player) then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "Rokushiki" then return end

    local maxDist = TeleportConfig.MaxDistance or 20
    if (hrp.Position - position).Magnitude > maxDist + 0.1 then
        if DEBUG then print("[TeleportServer] Position too far") end
        return
    end

    if not StaminaService.Consume(player, TeleportConfig.StaminaCost or 0) then
        if DEBUG then print("[TeleportServer] Not enough stamina") end
        return
    end

    TeleportVFX.Play(hrp.CFrame)
    hrp.CFrame = CFrame.new(position)
    TeleportVFX.Play(CFrame.new(position))

    local soundId = SoundConfig.Combat.Rokushiki.TeleportUse
    SoundServiceUtils:PlaySpatialSound(soundId, hrp)
end)

print("[TeleportServer] Ready")
