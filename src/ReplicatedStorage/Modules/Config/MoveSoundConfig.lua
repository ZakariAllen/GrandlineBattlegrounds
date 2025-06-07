local Tools = {
    BlackLeg = require(script.Parent.Tools.BlackLeg),
    BasicCombat = require(script.Parent.Tools.BasicCombat),
}

local MoveSoundConfig = {
    PartyTableKick = Tools.BlackLeg.PartyTableKick.Sound,
    PowerPunch = Tools.BasicCombat.PowerPunch.Sound,
    PowerKick = Tools.BlackLeg.PowerKick.Sound,
}

return MoveSoundConfig
