local Tools = {
    BlackLeg = require(script.Parent.Tools.BlackLeg),
    BasicCombat = require(script.Parent.Tools.BasicCombat),
    Rokushiki = require(script.Parent.Tools.Rokushiki),
}

local MoveSoundConfig = {
    PartyTableKick = Tools.BlackLeg.PartyTableKick.Sound,
    PowerPunch = Tools.BasicCombat.PowerPunch.Sound,
    PowerKick = Tools.BlackLeg.PowerKick.Sound,
    Concasse = Tools.BlackLeg.Concasse.Sound,
    AntiMannerKickCourse = Tools.BlackLeg.AntiMannerKickCourse.Sound,
    Teleport = Tools.Rokushiki.Teleport.Sound,
    Shigan = Tools.Rokushiki.Shigan.Sound,
    TempestKick = Tools.Rokushiki.TempestKick.Sound,
    Rokugan = Tools.Rokushiki.Rokugan.Sound,
}

return MoveSoundConfig
