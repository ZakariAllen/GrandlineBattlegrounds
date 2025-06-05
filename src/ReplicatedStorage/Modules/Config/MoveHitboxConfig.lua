local MoveHitboxConfig = {}

MoveHitboxConfig.M1 = {
    Size = Vector3.new(4, 5, 4),
    Offset = CFrame.new(0, 0, -2.4),
    Duration = 0.1,
    Shape = "Block",
}

MoveHitboxConfig.PartyTableKick = {
    Size = Vector3.new(7, 6, 6),
    Offset = CFrame.new(0, 0, 0),
    Duration = 0.1,
    Shape = "Cylinder",
}

MoveHitboxConfig.PowerPunch = {
    Size = Vector3.new(4, 5, 5.5),
    Offset = CFrame.new(0, 0, -3.5),
    Duration = 1,
    Shape = "Block",
}

return MoveHitboxConfig
