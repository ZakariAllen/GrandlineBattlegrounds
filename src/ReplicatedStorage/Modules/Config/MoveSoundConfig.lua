local Tools = {
    BlackLeg = require(script.Parent.Tools.BlackLeg),
    BasicCombat = require(script.Parent.Tools.BasicCombat),
    Rokushiki = require(script.Parent.Tools.Rokushiki),
}

local MoveSoundConfig = {
    PartyTableKick = Tools.BlackLeg.PartyTableKick.Sound,
    PowerPunch = Tools.BasicCombat.PowerPunch.Sound,
    PowerKick = Tools.BlackLeg.PowerKick.Sound,
    Teleport = Tools.Rokushiki.Teleport.Sound,
    Shigan = Tools.Rokushiki.Shigan.Sound,
}

return MoveSoundConfig
