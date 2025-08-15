# Combat Module Hooks

This directory now exposes a number of small helper APIs intended for AI
controllers.  These APIs surface only information that human players can also
perceive in game and allow NPCs to drive combat using the same inputs as
players.

## Helpers.lua
- `GetDistanceBand(attacker, target, toolName)` – returns `"TooClose"`,
  `"Ideal"` or `"Long"` based on `ToolConfig.ToolMeta` ranges.
- `HasWallBehind(target, radius)` – raycasts behind a target to detect walls for
  planning knockback routes.
- `SafeDashVector(attacker, dir)` – adjusts a desired dash direction to avoid
  immediate collisions using `DashConfig` limits.
- `GetPoseState(character)` – returns a table of observable flags such as
  `Blocking`, `Dashing`, `InWindup` and `Stunned`.

## ToolController.GetUsableMoves
`ToolController.GetUsableMoves(character, distanceBand, targetState)` returns a
list of move identifiers from `AbilityConfig` that satisfy basic observable
preconditions like facing requirements.  The function is read‑only and does not
expose any hidden cooldown or health information.

## StunService and StunStatusClient
Both modules now expose helpers `IsStunned`, `IsGuardBroken` and `EndsAt` so AI
controllers can mirror what players infer from animations.  The server broadcasts
`StunChangedEvent` whenever a character enters or exits stun.

## Hit outcome events
`HitboxClient` emits `WhiffEvent` when an attack misses, and existing
`HitConfirmEvent` messages remain unchanged.  These broadcasts allow AI clients
nearby to observe combat flow without accessing hidden state.

