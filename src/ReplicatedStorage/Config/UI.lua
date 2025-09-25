local UIConfig = {
    Theme = {
        Primary = Color3.fromRGB(18, 18, 26),
        Secondary = Color3.fromRGB(32, 36, 48),
        Accent = Color3.fromRGB(255, 126, 20),
        AccentDim = Color3.fromRGB(160, 74, 18),
        Text = Color3.fromRGB(239, 239, 239),
        TextMuted = Color3.fromRGB(175, 182, 198),
        Success = Color3.fromRGB(68, 192, 145),
    },
    Fonts = {
        Header = Enum.Font.GothamBold,
        Body = Enum.Font.Gotham,
        Mono = Enum.Font.Code,
    },
    Hud = {
        Padding = 14,
        CornerRadius = UDim.new(0, 10),
        Height = 56,
        StaminaBarSize = UDim2.new(0.24, 0, 0, 24),
        SmoothFillAlpha = 0.18,
    },
    TargetPanel = {
        Width = 220,
        Height = 72,
        CornerRadius = UDim.new(0, 8),
    },
    Billboard = {
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 2,
    },
}

return UIConfig
