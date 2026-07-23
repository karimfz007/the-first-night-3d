# Cycle log

## 2026-07-23 — DRIFT vertical slice 0.1

### Intent

Replace the non-production Phaser direction with the first real Rust-like 3D
slice while preserving trusted time, fire, warmth, save, and offline behavior.

### Decisions

- Pinned Godot 4.6.3 stable.
- Mobile renderer and Jolt baseline.
- No third-party runtime package or asset in the bootstrap slice.
- Programmatic prototype geometry keeps the authored world fast, auditable, and
  export-consistent.
- Dependency-free headless tests protect the brain before editor add-ons.

### Delivered in source

Scene-free inventory, crafting, state, reconciliation, stable IDs, migration,
and recovery; 3D beach/treeline/wreck; first-person/touch input; contextual
interaction; resource harvesting; compact inventory/crafting; modular snapped
building; fire/warmth/shelter loop; save/reload; morning report; debug overlay;
CI, Pages, Windows, Android, and tag-release definitions.

### Exceptions

Remote repository, remote artifacts, Pages, branch protection, and physical
Android profiling depend on external account/device state and cannot be claimed
from source alone. They remain explicit acceptance evidence, not silently
treated as complete.

