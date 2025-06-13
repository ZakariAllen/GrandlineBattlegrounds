local XPConfig = {}

XPConfig.LevelBase = 500
XPConfig.LevelGrowth = 1.07

XPConfig.M1 = 1
XPConfig.Move = 1
XPConfig.Ult = 25
XPConfig.Kill = 200

function XPConfig.XPForLevel(level)
    return math.floor(XPConfig.LevelBase * (XPConfig.LevelGrowth ^ (level - 1)) * level)
end

return XPConfig
