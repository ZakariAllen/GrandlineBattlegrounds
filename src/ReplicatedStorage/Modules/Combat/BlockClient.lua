--ReplicatedStorage.Modules.Combat.BlockClient

local BlockClient = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local CombatAnimations = require(ReplicatedStorage.Modules.Animations.Combat)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
-- Lazy reference to avoid circular require with MovementClient
local MovementClient

-- ✅ Fixed remote path
local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")

-- State
local isBlocking = false
local lastBlockEnd = 0
local blockCooldown = CombatConfig.Blocking.BlockCooldown or 2
local blockTrack: AnimationTrack? = nil

local function playBlockAnimation()
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local animId = CombatAnimations.Blocking.BlockHold
        if not humanoid or not animId then return end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end

        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        local track = animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        track:Play()
        blockTrack = track
        ToolController.PauseStance()
end

local function stopBlockAnimation()
        if blockTrack then
                blockTrack:Stop()
                blockTrack:Destroy()
                blockTrack = nil
        end
        ToolController.ResumeStance()
end

-- Sync from server when block state is forcibly ended (broken or cancelled)
BlockEvent.OnClientEvent:Connect(function(active)
        isBlocking = active
        if active then
                -- Avoid starting the animation twice if we already began locally
                if not blockTrack then
                        playBlockAnimation()
                end
        else
                lastBlockEnd = tick()
                stopBlockAnimation()
        end
end)

-- Checks if the current tool allows blocking
local function HasValidBlockingTool()
        local tool = ToolController.GetEquippedTool()
        if not tool then return false end

        local styleKey = ToolController.GetEquippedStyleKey()
        if not styleKey then return false end

        local stats = ToolConfig.ToolStats[styleKey]
        if stats and stats.AllowsBlocking == false then
                return false
        end

        return ToolController.IsValidCombatTool()
end

-- Input began: handle F key press
function BlockClient.OnInputBegan(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode ~= Enum.KeyCode.F then return end

        -- Don't attempt to block if we're stunned or locked
        if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then
                return
        end

	if isBlocking then return end

	local now = tick()
	if now - lastBlockEnd < blockCooldown then
		warn("[BlockClient] Block is on cooldown")
		return
	end

	if not HasValidBlockingTool() then
		warn("[BlockClient] Invalid tool for blocking")
		return
	end

        isBlocking = true
        if not MovementClient then
                MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
        end
        MovementClient.StopSprint()
        playBlockAnimation()
        BlockEvent:FireServer(true)
end

-- Input ended: stop blocking
function BlockClient.OnInputEnded(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode ~= Enum.KeyCode.F then return end

	if not isBlocking then return end

        isBlocking = false
        lastBlockEnd = tick()
        stopBlockAnimation()
        BlockEvent:FireServer(false)
end

function BlockClient.IsBlocking()
	return isBlocking
end

return BlockClient
