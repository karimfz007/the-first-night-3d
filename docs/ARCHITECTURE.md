# Architecture

## Boundary

`src/brain` contains deterministic rules and serializable data. It may use core
Godot value/file classes but never nodes, scenes, input, camera, rendering, or
audio. `src/body` owns physical presentation and asks the brain to change state.
`src/data` is the single source for gameplay tuning and definitions.

```text
Input / touch ──> Player + world objects ──> Brain operations
                         │                         │
                         v                         v
                 HUD / audio / VFX <──── serializable world state
                                                   │
                                                   v
                                     Save codec + offline reconciler
```

## Runtime ownership

- `Game`: composition root, clock, warmth, objectives, save lifecycle.
- `PlayerController`: locomotion, ray interaction, tool use, build preview.
- `WorldBuilder`: authored primitive island and stable resource IDs.
- `Inventory`: stack rules and serialization.
- `CraftingService`: recipe validation, queue, deterministic output.
- `Reconciler`: pure function of saved state and elapsed seconds.
- `SaveCodec`: schema migration, finite-value sanitization, backup-safe writes.

## Save contract

Every document contains `schema_version`, player transform/settings, inventory,
build records, fires, resources, world time, warmth, stable-ID counter, and a
real Unix timestamp. Writes go to a temporary file, rotate the prior primary to
`.bak`, then promote the temporary file. Load attempts primary, then backup,
then a sanitized new game.

## Building contract

Definitions provide dimensions, cost, snap category, tier, health, upkeep,
decay resistance, and protection. Placed records carry stable save/owner IDs,
type, transform, health, parent relation, and hook fields. The preview alone
owns validity coloring; the confirmed piece becomes ordinary persisted world
state.

## Extension seams

- Replace primitive meshes through item/build `world_model` paths.
- Add Terrain3D behind world-ground queries without moving simulation rules.
- Add stations/knowledge through already-present recipe requirements.
- Add damage, repair, demolition, upkeep, and decay through build record hooks.
- Replace placeholder tones through an audio event map; visual messages remain.

