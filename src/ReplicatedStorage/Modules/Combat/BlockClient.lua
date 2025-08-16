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
local MoveListManager = require(ReplicatedStorage.Modules.UI.MoveListManager)
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
local blockDisabledUntil = 0

local function resolveChar(actor)
       if typeof(actor) ~= "Instance" then return nil end
       if actor:IsA("Player") then
               return actor.Character
       elseif actor:IsA("Model") then
               return actor
       elseif actor:IsA("Humanoid") then
               return actor.Parent
       end
       return nil
end

-- Plays the block hold animation. When skipVFX is true the visual effect is not
-- spawned yet, allowing us to wait for server confirmation before showing it.
local function playBlockAnimation(skipVFX)
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

        if hrp and not activeVFX and not skipVFX then
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

                -- Ensure the visual effect starts once the block is truly active
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and not activeVFX then
                        activeVFX = BlockVFX.Create(hrp)
                end
        else
                lastBlockEnd = tick()
                stopBlockAnimation()
                MoveListManager.StartCooldown(Enum.KeyCode.F.Name, blockCooldown)
        end
end)

-- Show or hide block VFX for other actors
BlockVFXEvent.OnClientEvent:Connect(function(blockActor, active)
       if typeof(active) ~= "boolean" then return end

       local char = resolveChar(blockActor)
       if not char or char == player.Character then return end
       local hrp = char:FindFirstChild("HumanoidRootPart")
       local vfx = otherVFX[char]

       if active then
               if hrp and not vfx then
                       vfx = BlockVFX.Create(hrp)
                       otherVFX[char] = vfx
                       char.AncestryChanged:Once(function(_, parent)
                               if parent == nil then
                                       local vv = otherVFX[char]
                                       if vv then BlockVFX.Remove(vv) end
                                       otherVFX[char] = nil
                               end
                       end)
               end
       else
               if vfx then
                       BlockVFX.Remove(vfx)
                       otherVFX[char] = nil
               end
       end
end)

-- Clean up VFX if another player leaves the game
Players.PlayerRemoving:Connect(function(leftPlayer)
       local ch = resolveChar(leftPlayer)
       if ch and otherVFX[ch] then
               BlockVFX.Remove(otherVFX[ch])
               otherVFX[ch] = nil
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
       if now < blockDisabledUntil then return end
       if now - lastBlockEnd < blockCooldown then return end
       if not HasValidBlockingTool() then return end

       isBlocking = true
       if not MovementClient then
               MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
       end
       MovementClient.StopSprint()
       -- Play the animation immediately but delay the VFX until the server
       -- confirms the block has started
       playBlockAnimation(true)
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

-- Prevent starting a block for the given duration (in seconds)
function BlockClient.DisableFor(duration)
        if typeof(duration) ~= "number" or duration <= 0 then return end
        local endTime = tick() + duration
        if endTime > blockDisabledUntil then
                blockDisabledUntil = endTime
        end
end

return BlockClient
