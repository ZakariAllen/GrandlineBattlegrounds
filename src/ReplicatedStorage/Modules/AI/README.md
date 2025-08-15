# AI Modules

This folder contains the runtime pieces for the NPC combat AI used in
**Grandline Battlegrounds**.  The system is purposely lightweight and acts
through the same public surfaces as players.

## Levels
The behaviour for NPCs is driven by `Config/AIConfig.lua` which exposes five
archetype levels.  Each level inherits from the previous and tunes aggression,
feints, perfect blocks and more.

## Debugging
A tiny `DebugAI` helper can be toggled on the server using
`DebugAI:SetEnabled(true)` to print simple labels to the output window.
