# GrandlineBattlegrounds

This repository now targets a cozy isometric open world about fishing and exploration. The previous battler codebase has been cleared out and replaced with lightweight generators that build a stylized tile map, tilt the camera into an isometric angle, and surface prototype HUD text.

## What is included
- **Procedural island builder** (`ReplicatedStorage/Modules/World/WorldGenerator.lua`) that scatters trees, rocks, grass tufts, shallow water pools, and glowing fishing hotspots across a configurable grid.
- **Isometric camera** (`StarterPlayer/StarterPlayerScripts/IsometricCamera.client.lua`) that keeps a fixed pitch/yaw above the player for the pixel-art inspired look shown in the reference image.
- **Prototype HUD** (`StarterPlayer/StarterPlayerScripts/FishingHUD.client.lua`) that labels the project and explains the current controls/goals.
- **Server bootstrap** (`ServerScriptService/WorldInit.server.lua`) that seeds the lighting and spawns the world at server start.

## Configuration
Gameplay and visual knobs live in `ReplicatedStorage/Modules/Config/WorldConfig.lua`:
- Tile size, grid dimensions, and elevation steps.
- Color palettes for grass, rocks, water, and dirt.
- Decoration rates (trees, rocks, pebbles, tall grass) and fishing hotspot frequency.
- Camera pitch/yaw, distance, and player spawn height.

## Building
Use Rojo to produce a place file:

```sh
rojo build default.project.json -o game.rbxlx
```

The generated world is intentionally simple but is a clean slate for adding fishing mechanics, collectibles, characters, and quests.
