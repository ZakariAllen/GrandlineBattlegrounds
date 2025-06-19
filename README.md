# GrandlineBattlegrounds

This project contains the core scripts and modules for the game. To ensure all required `RemoteEvent` objects exist when running in a fresh place, the server script at `ServerScriptService/Misc/RemoteSetup.server.lua` will create any missing remotes inside `ReplicatedStorage/Remotes`.

Several core server scripts emit initialization messages to the output so you can confirm they are running.

## Move Configuration

Each combat tool now has a dedicated module under
`ReplicatedStorage/Modules/Config/Tools`. These tool modules contain every
setting for their moves including hitboxes and sound asset IDs. The previous
shim modules `AbilityConfig.lua`, `MoveHitboxConfig.lua` and
`MoveSoundConfig.lua` have been removed; scripts should require the tool
modules directly. For example, `Tools/BlackLeg.lua` defines both
`PartyTableKick` and `PowerKick` in a single table.

All combat and movement sound asset IDs live exclusively in `SoundConfig`.
Tool configuration modules do not contain any sound tables; scripts load
the appropriate sounds directly from `SoundConfig`.

### Ragdoll Knockback

Knockback is now handled through the ragdoll system. The module
`ReplicatedStorage.Modules.Combat.RagdollKnockback` exposes helper
functions for applying a knockback impulse while putting the target in
a ragdolled state. While ragdolled all character motors and active
animations are disabled so the body goes completely limp until the
knockback duration ends.

The vertical lift value is now treated independently from the horizontal
force so moves can launch characters without multiplying the upward
impulse by the knockback force.

## Hit Effect Settings

The hit highlight shown when a character is damaged is configured in
`ReplicatedStorage/Modules/Config/HitEffectConfig.lua`. These values are loaded
through the main `Config` module and accessible as `Config.HitEffect`.

## Day/Night Cycle

The server script `ServerScriptService/Misc/DayNightCycle.server.lua` rotates
`Lighting.ClockTime` to simulate day and night. All servers use the current UTC
time so their cycles stay in sync. The full cycle duration is controlled by
`Config.GameSettings.DayNightCycleMinutes`, which defaults to 15 minutes but can
be adjusted as needed.

## Leveling System

Player levels are stored persistently and increase when enough experience is
earned. Landing basic attacks or moves grants 1 XP, ultimate abilities grant
25 XP and defeating another player awards 200 XP. The XP cost for each new
level scales smoothly according to `XPConfig.XPForLevel`. Reaching level 2
requires 500 XP with costs growing exponentially from there, so very high
levels take considerable time but remain achievable.


## Development Setup

This project uses [Rojo](https://github.com/rojo-rbx/rojo) to build place files. The recommended way to install Rojo is with [Aftman](https://github.com/LPGhatguy/aftman).

1. Download the Aftman binary for your platform from the [GitHub releases page](https://github.com/LPGhatguy/aftman/releases) and run `./aftman self-install`.
2. In this repository, run `aftman install` to install the tools listed in `aftman.toml` (including Rojo).

After installation you can build the project with:

```sh
rojo build default.project.json -o game.rbxlx
```

This is the same command used in tests to verify that the project compiles correctly.
