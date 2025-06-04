--ReplicatedStorage.Modules.Combat.HighlightEffect

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Modules.Config.Config)

local HighlightEffect = {}

function HighlightEffect.ApplyHitHighlight(character, durationOverride)
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local oldHighlight = character:FindFirstChild("HitHighlight")
	if oldHighlight then
		oldHighlight:Destroy() -- 🔧 Removed any attempt to access _CleanupConnection
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "HitHighlight"
	highlight.Adornee = character
	highlight.FillColor = Config.HitEffect.FillColor
	highlight.OutlineColor = Config.HitEffect.OutlineColor
	highlight.FillTransparency = Config.HitEffect.FillTransparency
	highlight.OutlineTransparency = Config.HitEffect.OutlineTransparency
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character

	local duration = durationOverride or Config.HitEffect.Duration
	Debris:AddItem(highlight, duration)
end

return HighlightEffect
