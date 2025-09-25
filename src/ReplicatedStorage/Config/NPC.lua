local NPCConfig = {
    DefaultStats = {
        MaxHealth = 150,
        WalkSpeed = 14,
        JumpPower = 0,
    },
    Behavior = {
        AttackInterval = 2.5,
        RetryDelay = 0.5,
        DetectionRadius = 45,
        TrackingUpdateInterval = 0.15,
        BlockedInterval = 1.2,
        GuardBreakFollowUp = 0.35,
        PerfectBlockPenalty = 2.5,
    },
    Spawns = {
        Vector3.new(0, 5, 0),
        Vector3.new(12, 5, 8),
        Vector3.new(-14, 5, -6),
    },
    Appearance = {
        BodyColor = Color3.fromRGB(33, 43, 54),
        HeadColor = Color3.fromRGB(210, 95, 64),
    },
}

return NPCConfig
