local Tools = {
    BlackLeg = require(script.Parent.Tools.BlackLeg),
    BasicCombat = require(script.Parent.Tools.BasicCombat),
    Rokushiki = require(script.Parent.Tools.Rokushiki),
}

local MoveHitboxConfig = {}

MoveHitboxConfig.M1 = {
    Size = Vector3.new(4, 5, 4),
    Offset = CFrame.new(0, 0, -2.4),
    Duration = 0.1,
    Shape = "Block",
}

MoveHitboxConfig.PartyTableKick = Tools.BlackLeg.PartyTableKick.Hitbox
MoveHitboxConfig.PowerPunch = Tools.BasicCombat.PowerPunch.Hitbox
MoveHitboxConfig.PowerKick = Tools.BlackLeg.PowerKick.Hitbox
MoveHitboxConfig.Concasse = Tools.BlackLeg.Concasse.Hitbox
MoveHitboxConfig.AntiMannerKickCourse = Tools.BlackLeg.AntiMannerKickCourse.Hitbox
MoveHitboxConfig.Shigan = Tools.Rokushiki.Shigan.Hitbox
MoveHitboxConfig.TempestKick = Tools.Rokushiki.TempestKick.Hitbox
MoveHitboxConfig.Rokugan = Tools.Rokushiki.Rokugan.Hitbox

return MoveHitboxConfig
