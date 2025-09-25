local theme = {
    Primary = Color3.fromRGB(18, 18, 26),
    Secondary = Color3.fromRGB(32, 36, 48),
    Accent = Color3.fromRGB(255, 126, 20),
    AccentDim = Color3.fromRGB(160, 74, 18),
    Text = Color3.fromRGB(239, 239, 239),
    TextMuted = Color3.fromRGB(175, 182, 198),
    Success = Color3.fromRGB(68, 192, 145),
    Warning = Color3.fromRGB(255, 92, 92),
}

local fonts = {
    Header = Enum.Font.GothamBold,
    Body = Enum.Font.Gotham,
    Mono = Enum.Font.Code,
}

local UIConfig = {
    Theme = theme,
    Fonts = fonts,
    Hud = {
        Padding = 14,
        CornerRadius = UDim.new(0, 10),
        Height = 56,
        StaminaBarSize = UDim2.new(0.24, 0, 0, 24),
        SmoothFillAlpha = 0.18,
        LowStaminaThreshold = 0.25,
        StaminaHighColor = theme.Accent,
        StaminaLowColor = theme.Warning,
        ComboLabelSize = UDim2.new(0, 160, 0, 24),
        ComboLabelOffset = Vector2.new(0, 8),
        ComboTextFormat = "Combo x%d",
        ComboActiveColor = theme.Accent,
        ComboInactiveColor = theme.TextMuted,
        CooldownColor = theme.TextMuted,
    },
    TargetPanel = {
        Width = 220,
        Height = 72,
        CornerRadius = UDim.new(0, 8),
        HealthBarSize = UDim2.new(1, -24, 0, 10),
        HealthBarPosition = UDim2.new(0, 12, 1, -16),
        HealthBarBackgroundColor = theme.Secondary,
        HealthBarFillColor = theme.Accent,
        HealthCriticalThreshold = 0.3,
    },
    Billboard = {
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 2,
    },
}

return UIConfig
