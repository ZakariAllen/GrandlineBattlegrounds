local font = Enum.Font.GothamBold

return {
    CastMeter = {
        ScreenGui = {
            Name = "CastMeter",
            DisplayOrder = 40,
        },
        Bar = {
            Size = UDim2.fromScale(0.34, 0.04),
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.fromScale(0.5, 0.9),
            BackgroundColor3 = Color3.fromRGB(18, 28, 44),
            BackgroundTransparency = 0.1,
            CornerRadius = UDim.new(0, 8),
        },
        Fill = {
            BackgroundTransparency = 0,
            CornerRadius = UDim.new(0, 8),
            Color = Color3.fromRGB(91, 211, 255),
        },
        GradeLabel = {
            Size = UDim2.fromScale(0.4, 0.05),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.82),
            Font = font,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
        },
    },
    Cursor = {
        EquippedIcon = "rbxasset://SystemCursors/Cross",
        DefaultIcon = "",
    },
}
