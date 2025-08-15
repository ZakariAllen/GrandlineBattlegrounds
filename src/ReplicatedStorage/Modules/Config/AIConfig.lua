--ReplicatedStorage.Modules.Config.AIConfig
-- Configuration for NPC combat AI levels.

return {
  PerceptionHz = 15,
  DecisionHz   = 7,
  SeededRNG    = true,
  Levels = {
    [1] = {Aggression=0.55, FeintChance=0.00, PerfectBlock=0.00, WhiffPunish=0.00, UseAbilities=0.00, DashOffense=0.00, DashDefense=0.05, Strafing=0.10, Predictability=0.80, ComboVariety=0.10, RepetitionPenalty=0.05, ReactionTimeMs={min=260,max=360}, MicroJitterMs={min=40,max=90}},
    [2] = {Aggression=0.55, FeintChance=0.00, PerfectBlock=0.00, WhiffPunish=0.05, UseAbilities=0.00, DashOffense=0.00, DashDefense=0.12, Strafing=0.20, Predictability=0.65, ComboVariety=0.25, RepetitionPenalty=0.12, ReactionTimeMs={min=220,max=300}, MicroJitterMs={min=30,max=80}},
    [3] = {Aggression=0.60, FeintChance=0.10, PerfectBlock=0.10, WhiffPunish=0.20, UseAbilities=0.25, DashOffense=0.10, DashDefense=0.20, Strafing=0.35, Predictability=0.50, ComboVariety=0.55, RepetitionPenalty=0.20, ReactionTimeMs={min=180,max=260}, MicroJitterMs={min=20,max=70}},
    [4] = {Aggression=0.65, FeintChance=0.22, PerfectBlock=0.35, WhiffPunish=0.50, UseAbilities=0.85, DashOffense=0.35, DashDefense=0.35, Strafing=0.55, Predictability=0.32, ComboVariety=0.85, RepetitionPenalty=0.35, ReactionTimeMs={min=150,max=220}, MicroJitterMs={min=12,max=50}},
    [5] = {Aggression=0.70, FeintChance=0.30, PerfectBlock=0.55, WhiffPunish=0.70, UseAbilities=1.00, DashOffense=0.55, DashDefense=0.45, Strafing=0.70, Predictability=0.20, ComboVariety=0.95, RepetitionPenalty=0.50, ReactionTimeMs={min=130,max=190}, MicroJitterMs={min=8,max=40}},
  },
  Caps = {
    [1] = {MaxFeintsPerEngage=0, UseGuardBreak=false, UseComboEnders=false},
    [2] = {MaxFeintsPerEngage=0, UseGuardBreak=false, UseComboEnders=false},
    [3] = {MaxFeintsPerEngage=1, UseGuardBreak=true,  UseComboEnders=false},
    [4] = {MaxFeintsPerEngage=2, UseGuardBreak=true,  UseComboEnders=true},
    [5] = {MaxFeintsPerEngage=3, UseGuardBreak=true,  UseComboEnders=true},
  }
}
