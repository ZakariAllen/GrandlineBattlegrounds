local CombatConstants = {
    ATTACK_COOLDOWN = 0.55,
    BLOCK_STAMINA_DRAIN_PER_SECOND = 20,
    STAMINA_REGEN_PER_SECOND = 15,
    DAMAGE = {
        Light = 12,
        Heavy = 28,
    },
    STAMINA = {
        Max = 100,
        AttackCost = {
            Light = 12,
            Heavy = 32,
        },
        BlockStartCost = 8,
    },
    RANGE = {
        Light = 10,
        Heavy = 12,
    },
    NPC_ATTACK_INTERVAL = 2.5,
    NPC_DETECTION_RADIUS = 45,
}

return CombatConstants
