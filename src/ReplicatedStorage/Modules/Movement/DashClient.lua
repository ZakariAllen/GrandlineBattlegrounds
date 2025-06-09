-- ReplicatedStorage.Modules.Movement.DashClient

local DashClient = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local DashEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement"):WaitForChild("DashEvent")
local DashConfig = require(ReplicatedStorage.Modules.Movement.DashConfig)
local MovementAnimations = require(ReplicatedStorage.Modules.Animations.Movement)
local StunStatusClient = require(ReplicatedStorage.Modules.Combat.StunStatusClient)
local BlockClient = require(ReplicatedStorage.Modules.Combat.BlockClient)
local MovementClient = require(ReplicatedStorage.Modules.Client.MovementClient)
local SoundServiceUtils = require(ReplicatedStorage.Modules.Effects.SoundServiceUtils)
local DashVFX = require(ReplicatedStorage.Modules.Effects.DashVFX)
local StaminaService = require(ReplicatedStorage.Modules.Stats.StaminaService)
local ToolController = require(ReplicatedStorage.Modules.Combat.ToolController)

local lastDashTime = 0
local DASH_KEY = Enum.KeyCode.Q
local currentTrack = nil
local dashConn = nil

-- Immediately stop any active dash and clear velocity
function DashClient.CancelDash()
    if dashConn then
        dashConn:Disconnect()
        dashConn = nil
    end
    local character, humanoid, _, hrp = getCharacterComponents()
    if hrp then
        local v = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
    end
    if humanoid then
        humanoid.AutoRotate = true
    end
end
-- Cancel active dash on stun

-- Store original Enabled states for Gui objects so we can restore them
local originalGuiState = setmetatable({}, {__mode = "k"})
local originalHidePlayer = setmetatable({}, {__mode = "k"})

-- Utility used for RokuDash to hide or show a character model
local function setCharacterInvisible(character, invisible, owner)
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Decal") then
            if obj.Name == "HumanoidRootPart" then
                obj.Transparency = 1
            else
                obj.Transparency = invisible and 1 or 0
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = not invisible
        elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            if invisible then
                -- Remember previous state so it can be restored later. Only
                -- capture it once in case multiple dash calls overlap.
                if originalGuiState[obj] == nil then
                    originalGuiState[obj] = obj.Enabled
                end
                if obj:IsA("BillboardGui") then
                    if originalHidePlayer[obj] == nil then
                        originalHidePlayer[obj] = obj.PlayerToHideFrom
                    end
                    pcall(function()
                        obj.PlayerToHideFrom = player
                    end)
                end
            else
                local prev = originalGuiState[obj]
                if prev ~= nil and obj.Enabled == false then
                    obj.Enabled = prev
                end
                originalGuiState[obj] = nil

                if obj:IsA("BillboardGui") then
                    local prevPlayer = originalHidePlayer[obj]
                    originalHidePlayer[obj] = nil
                    pcall(function()
                        obj.PlayerToHideFrom = prevPlayer
                    end)
                end
            end
        elseif obj:IsA("Highlight") then
            obj.Enabled = not invisible
        end
    end
end

local function getCharacterComponents()
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, animator, hrp
end

-- 🚨 CAMERA-RELATIVE DASHING!
local function getDashInputAndVector()
	local keys = MovementClient.GetMovementKeys and MovementClient.GetMovementKeys() or {}
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	local camLook = camera.CFrame.LookVector
	local camRight = camera.CFrame.RightVector

	camLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
	camRight = Vector3.new(camRight.X, 0, camRight.Z).Unit

	if keys.W and keys.A then
		return "ForwardLeft", (camLook - camRight).Unit
	elseif keys.W and keys.D then
		return "ForwardRight", (camLook + camRight).Unit
	elseif keys.S and keys.A then
		return "BackwardLeft", ((-camLook) - camRight).Unit
	elseif keys.S and keys.D then
		return "BackwardRight", ((-camLook) + camRight).Unit
	elseif keys.W then
		return "Forward", camLook
	elseif keys.A then
		return "Left", (-camRight).Unit
	elseif keys.D then
		return "Right", camRight
	elseif keys.S then
		return "Backward", (-camLook).Unit
	end
	return nil
end

local function playDashAnimation(direction)
	local _, _, animator = getCharacterComponents()
	if not animator then return end

	local animId = MovementAnimations.Dash[direction] or MovementAnimations.Dash["Forward"]
	if not animId then return end

	if currentTrack and currentTrack.IsPlaying then
		currentTrack:Stop()
		currentTrack:Destroy()
		currentTrack = nil
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animId

	local track = animator:LoadAnimation(anim)
	track:Play()
	currentTrack = track
end

function DashClient.OnInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= DASH_KEY then return end

    if tick() - lastDashTime < DashConfig.Cooldown then return end
    if StunStatusClient.IsStunned() or StunStatusClient.IsAttackerLocked() or BlockClient.IsBlocking() then return end
    -- Basic dashing should be available even when no tool is equipped. We only
    -- restrict dashing if a tool is equipped and specifically disallowed by the
    -- game (none at the moment). The style key will determine if any special
    -- dash settings apply.
    if StaminaService.GetStamina(player) < 10 then return end

        local direction, dashVector = getDashInputAndVector()
        if not direction or not dashVector then return end

        -- Only the Rokushiki tool changes the dash behaviour. Any other tool
        -- (or no tool) should result in a normal dash, so we ignore the style
        -- key unless it is explicitly Rokushiki.
        local styleKey = ToolController.GetEquippedStyleKey()
        if styleKey ~= "Rokushiki" then
                styleKey = nil
        end

        lastDashTime = tick()
        playDashAnimation(direction)

        local character, humanoid, _, hrp = getCharacterComponents()
        if hrp then
                if DashConfig.Sound then
                        SoundServiceUtils:PlaySpatialSound(DashConfig.Sound, hrp)
                end
                DashVFX:PlayDashEffect(direction, hrp)
        end
        if styleKey == "Rokushiki" and character then
                setCharacterInvisible(character, true, player)
        end
        local dashSet = DashConfig.Settings
        if styleKey == "Rokushiki" then
                dashSet = DashConfig.RokuSettings
        end
        local dashSettings = dashSet[direction] or dashSet["Forward"]
        local duration = dashSettings.Duration
        local distance = dashSettings.Distance

        if styleKey == "Rokushiki" and character then
                task.delay(DashConfig.RokuInvisDuration, function()
                        if character then
                                setCharacterInvisible(character, false, player)
                        end
                end)
        end

	local dashSpeed = distance / duration

	-- Stop any ongoing dash update
	if dashConn then dashConn:Disconnect() dashConn = nil end

	-- The only dashes that are steerable (dynamic) are the "Forward" and "ForwardLeft/Right" ones.
	if direction == "Forward" or direction == "ForwardLeft" or direction == "ForwardRight" then
		local start = tick()
		dashConn = RunService.RenderStepped:Connect(function()
			if not hrp or not humanoid then return end
			if tick() - start > duration then
				if dashConn then dashConn:Disconnect() dashConn = nil end
				return
			end

			local camera = Workspace.CurrentCamera
			local camLook = camera.CFrame.LookVector
			local camRight = camera.CFrame.RightVector
			camLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
			camRight = Vector3.new(camRight.X, 0, camRight.Z).Unit

			local liveDashDir =
				(direction == "Forward" and camLook)
				or (direction == "ForwardLeft" and (camLook - camRight).Unit)
				or (direction == "ForwardRight" and (camLook + camRight).Unit)
				or dashVector

			local curVel = hrp.AssemblyLinearVelocity
			local dashVel = Vector3.new(liveDashDir.X * dashSpeed, curVel.Y, liveDashDir.Z * dashSpeed)
			hrp.AssemblyLinearVelocity = dashVel
		end)

		task.delay(duration, function()
			if dashConn then dashConn:Disconnect() dashConn = nil end
		end)
	else
		-- For left, right, backward, backwardleft, backwardright: one-time velocity, lock rotation
		local curVel = hrp.AssemblyLinearVelocity
		local dashVel = Vector3.new(dashVector.X * dashSpeed, curVel.Y, dashVector.Z * dashSpeed)
		hrp.AssemblyLinearVelocity = dashVel
		humanoid.AutoRotate = false
		task.delay(duration, function()
			humanoid.AutoRotate = true
		end)
	end

        -- Notify server for validation (state only)
        DashEvent:FireServer(direction, dashVector, styleKey)
end

-- Play dash VFX/SFX when another player dashes
DashEvent.OnClientEvent:Connect(function(dashPlayer, direction, styleKey)
        if dashPlayer == player then return end
        if typeof(direction) ~= "string" then return end

        local char = dashPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if DashConfig.Sound then
                SoundServiceUtils:PlaySpatialSound(DashConfig.Sound, hrp)
        end
        DashVFX:PlayDashEffect(direction, hrp)

        if styleKey == "Rokushiki" and char then
                setCharacterInvisible(char, true, dashPlayer)
                task.delay(DashConfig.RokuInvisDuration, function()
                        if char then
                                setCharacterInvisible(char, false, dashPlayer)
                        end
                end)
        end
end)

function DashClient.OnInputEnded() end

return DashClient
