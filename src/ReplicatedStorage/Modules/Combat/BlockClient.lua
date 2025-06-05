--ReplicatedStorage.Modules.Combat.BlockClient

local BlockClient = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CombatConfig = require(ReplicatedStorage.Modules.Config.CombatConfig)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)
local ToolConfig = require(ReplicatedStorage.Modules.Config.ToolConfig)
local CombatAnimations = require(ReplicatedStorage.Modules.Animations.Combat)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local BlockVFX = require(ReplicatedStorage.Modules.Effects.BlockVFX)
-- Lazy reference to avoid circular require with MovementClient
local MovementClient

-- ✅ Fixed remote path
local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")
local BlockEvent = CombatRemotes:WaitForChild("BlockEvent")
local BlockVFXEvent = CombatRemotes:WaitForChild("BlockVFX")

-- State
local isBlocking = false
local lastBlockEnd = 0
local blockCooldown = CombatConfig.Blocking.BlockCooldown or 2
local blockTrack: AnimationTrack? = nil
local blockHeld = false
local retryConn: RBXScriptConnection? = nil
local activeVFX: Instance? = nil
local otherVFX = {}

local function playBlockAnimation()
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
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

        if hrp and not activeVFX then
                activeVFX = BlockVFX.Create(hrp)
        end
end

local function stopBlockAnimation()
        if blockTrack then
                blockTrack:Stop()
                blockTrack:Destroy()
                blockTrack = nil
        end
        if activeVFX then
                BlockVFX.Remove(activeVFX)
                activeVFX = nil
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

-- Show or hide block VFX for other players
BlockVFXEvent.OnClientEvent:Connect(function(blockPlayer, active)
       if blockPlayer == player then return end
       if typeof(active) ~= "boolean" then return end

       local char = blockPlayer.Character
       local hrp = char and char:FindFirstChild("HumanoidRootPart")
       local vfx = otherVFX[blockPlayer]

       if active then
               if hrp and not vfx then
                       vfx = BlockVFX.Create(hrp)
                       otherVFX[blockPlayer] = vfx
               end
       else
               if vfx then
                       BlockVFX.Remove(vfx)
                       otherVFX[blockPlayer] = nil
               end
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

local function attemptBlock()
       if not blockHeld or isBlocking then return end
       if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() then return end
       local now = tick()
       if now - lastBlockEnd < blockCooldown then return end
       if not HasValidBlockingTool() then return end

       isBlocking = true
       if not MovementClient then
               MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
       end
       MovementClient.StopSprint()
       playBlockAnimation()
       BlockEvent:FireServer(true)

       if retryConn then
               retryConn:Disconnect()
               retryConn = nil
       end
end

-- Input began: handle F key press
function BlockClient.OnInputBegan(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode ~= Enum.KeyCode.F then return end

       blockHeld = true

       attemptBlock()
       if not isBlocking and not retryConn then
               retryConn = RunService.RenderStepped:Connect(function()
                       attemptBlock()
                       if not blockHeld or isBlocking then
                               if retryConn then
                                       retryConn:Disconnect()
                                       retryConn = nil
                               end
                       end
               end)
       end
end

-- Input ended: stop blocking
function BlockClient.OnInputEnded(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode ~= Enum.KeyCode.F then return end
       blockHeld = false
       if retryConn then
               retryConn:Disconnect()
               retryConn = nil
       end

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
