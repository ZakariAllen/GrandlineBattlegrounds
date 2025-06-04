--ReplicatedStorage.Modules.MenuCfgs.MenuGlobalCfg

local MenuGlobalCfg = {
	Sound = {
		Hover = "rbxassetid://92876108656319",
		HoverVolume = 0.3,
		Click = "rbxassetid://6042053626",
		ClickVolume = 0.6,
	},
	Camera = {
		StartCFrame = CFrame.new(0, 50, -80),
		FocusPoint = Vector3.new(0, 40, 0),
		Rotate = true,
		RotationSpeed = 0.25,
		RotationAxis = "Y",
		Zoom = false,
	},
	TransitionScreen = {
		Duration = 2,
	},
	LoadingScreen = {
		Text = "Loading Grandline Battlegrounds...",
		TextColor = Color3.fromRGB(255, 255, 255),
		TextSize = 32,
		Font = Enum.Font.GothamBold,
		TextOffset = UDim2.new(0.5, -150, 0.5, -25),
		Duration = 5,
		BackgroundColor = Color3.fromRGB(5, 16, 30),
		BackgroundTransparency = 0,
		BackgroundSize = UDim2.new(1, 0, 1, 12),
		BackgroundPosition = UDim2.new(0, 0, 0, -12),
		BackgroundAnchorPoint = Vector2.new(0, 0),
		BackgroundBorderSize = 0,
		SpinnerAssetId = "rbxassetid://7734121530",
		SpinnerSize = UDim2.new(0, 50, 0, 50),
	},
}
return MenuGlobalCfg