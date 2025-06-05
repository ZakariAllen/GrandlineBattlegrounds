# GrandlineBattlegrounds

This project contains the core scripts and modules for the game. To ensure all required `RemoteEvent` objects exist when running in a fresh place, the server script at `ServerScriptService/Misc/RemoteSetup.server.lua` will create any missing remotes inside `ReplicatedStorage/Remotes`.

Several core server scripts emit initialization messages to the output so you can confirm they are running.

## Hitbox Configuration

Hitbox sizes, offsets, durations and shapes for each move are defined in
`ReplicatedStorage/Modules/Config/MoveHitboxConfig.lua`. Adjust the values in
that module to tweak hitboxes without editing the move scripts themselves.

## Move Settings

Move settings such as damage, stun duration and cooldown are defined in
`ReplicatedStorage/Modules/Config/AbilityConfig.lua` under each combat style.
For example, Party Table Kick's values live at `AbilityConfig.BlackLeg.PartyTableKick`
and Power Punch uses `AbilityConfig.BasicCombat.PowerPunch`.
