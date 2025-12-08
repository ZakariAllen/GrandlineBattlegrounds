local defaultTransparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(1, 0.35),
})

return {
    Assets = {
        BobberFolder = { "Assets", "Bobbers" },
        DefaultBobber = "Default",
    },
    Casting = {
        ArcHeight = 10,
        TravelTime = 0.95,
        ReelDuration = 0.55,
        FloatOffset = 0.35,
    },
    Bobbing = {
        Amplitude = 0.32,
        Frequency = 1.1,
    },
    Line = {
        Width0 = 0.05,
        Width1 = 0.04,
        CurveSize0 = 0.2,
        CurveSize1 = -0.05,
        LightInfluence = 0,
        Texture = "",
        TextureLength = 1,
        TextureMode = Enum.TextureMode.Stretch,
        TextureSpeed = 0,
        Color = ColorSequence.new(Color3.fromRGB(240, 244, 255)),
        Transparency = defaultTransparency,
    },
    BiteDefaults = NumberRange.new(12, 18),
}
