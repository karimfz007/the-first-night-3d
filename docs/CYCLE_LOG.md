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

### Verification

Godot 4.6.3 official build `7d41c59c4` passed 76 assertions including a
240-case deterministic property sweep, passed an 18-check live-scene acceptance
playthrough, passed architecture/secret validation, completed a clean
composition-root smoke, booted the complete main scene for 180 frames, and
produced a rendered 1280×720 smoke capture through the Compatibility renderer.
Hosted run
[30047450638](https://github.com/karimfz007/the-first-night-3d/actions/runs/30047450638)
reproduced those checks and exported Web, Windows, and Android packages from
implementation SHA `6921215f4a6f14768f5b2f63f95cfe7a9232a24c`.

### Exceptions

The fresh-context audit passes A1–A3 and A5–A11. A4 remains not verified because
there is no physical/emulated Android runtime session; A12 therefore fails.
Director-device FPS, input latency, memory, and thermal profiling remain
unclaimed until captured on that device.
