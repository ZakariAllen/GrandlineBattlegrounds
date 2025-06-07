# GrandlineBattlegrounds

This project contains the core scripts and modules for the game. To ensure all required `RemoteEvent` objects exist when running in a fresh place, the server script at `ServerScriptService/Misc/RemoteSetup.server.lua` will create any missing remotes inside `ReplicatedStorage/Remotes`.

Several core server scripts emit initialization messages to the output so you can confirm they are running.

## Move Configuration

Each combat tool now has a dedicated module under
`ReplicatedStorage/Modules/Config/Tools`. These tool modules contain every
setting for their moves including hitboxes and sound asset IDs. The legacy
files `AbilityConfig.lua`, `MoveHitboxConfig.lua` and `MoveSoundConfig.lua`
simply return values from these tool modules. For example,
`Tools/BlackLeg.lua` defines both `PartyTableKick` and `PowerKick` in a single
table.

### Knockback Types

`ReplicatedStorage.Modules.Combat.KnockbackConfig` defines different
knockback direction modes. A mode called `HitboxTravelDirection`
uses the velocity of the hitbox that triggered the attack. No moves
currently use this mode.

## Hit Effect Settings

The hit highlight shown when a character is damaged is configured in
`ReplicatedStorage/Modules/Config/HitEffectConfig.lua`. These values are loaded
through the main `Config` module and accessible as `Config.HitEffect`.


## Development Setup

This project uses [Rojo](https://github.com/rojo-rbx/rojo) to build place files. The recommended way to install Rojo is with [Aftman](https://github.com/LPGhatguy/aftman).

1. Download the Aftman binary for your platform from the [GitHub releases page](https://github.com/LPGhatguy/aftman/releases) and run `./aftman self-install`.
2. In this repository, run `aftman install` to install the tools listed in `aftman.toml` (including Rojo).

After installation you can build the project with:

```sh
rojo build default.project.json -o game.rbxlx
```

This is the same command used in tests to verify that the project compiles correctly.
