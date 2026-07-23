# Acceptance audit

Status: **NOT FULLY ACCEPTED**

Audited implementation: `6921215f4a6f14768f5b2f63f95cfe7a9232a24c`

Fresh-context audit completed: 2026-07-23

The independent audit passes A1–A3 and A5–A11. A4 remains **NOT VERIFIED**
because no APK was installed and played on the Director's physical Android
device or an Android emulator. Consequently, aggregate gate A12 fails. This is
an evidence gap, not a substituted desktop claim.

| Gate | Status | Independent evidence |
|---|---|---|
| A1 | **PASS** | The [public repository](https://github.com/karimfz007/the-first-night-3d) has protected `main`: strict required `verify-and-export`, linear history, force-push/deletion disabled, and conversation resolution enabled. |
| A2 | **PASS** | [GitHub Pages](https://karimfz007.github.io/the-first-night-3d/) deployed from the audited SHA. Live evidence confirms Godot 4.6.3, WebGL 2 Compatibility, an active canvas, and successful loader/assets. |
| A3 | **PASS** | [CI run 30047450638](https://github.com/karimfz007/the-first-night-3d/actions/runs/30047450638) produced non-expired Windows, Android APK, checksum, and Pages artifacts tied to the audited SHA. |
| A4 | **NOT VERIFIED** | Desktop/full-scene behavior, touch contracts, and Android export pass. No Android runtime session proves first-person exploration and input on device or emulator. |
| A5 | **PASS** | The live-scene acceptance playthrough physically collects driftwood, stone, and fiber; crafts/equips a tool; and verifies improved tool harvesting. |
| A6 | **PASS** | Inventory, hotbar, crafting, move/split/drop, serialization, and reconstructed dropped items pass. |
| A7 | **PASS** | The playthrough preview-validates and places a foundation, snapped walls, doorway, operable door, roof, and campfire. |
| A8 | **PASS** | The playthrough verifies fueling, ignition, manual extinguishing with fuel preserved, shelter exposure reduction, and fire sanctuary warming. |
| A9 | **PASS** | Schema-3 persistence, migrations, player/inventory/resources/buildings/fire/warmth/time, dynamic drops, and backup-safe round trips pass. |
| A10 | **PASS** | Deterministic reconciliation, the 240-case sweep, spatial fire/shelter effects, capped consequences, causal reporting, and offline floor pass; no offline death path exists. |
| A11 | **PASS** | Hosted CI reports 76/76 tests, full-scene smoke, all 18 acceptance checks, static validation, and Web/Windows/Android exports. |
| A12 | **FAIL** | The independent audit cannot verify A4's Android half without Android runtime/device evidence. |

## Independently reproduced

Using pinned Godot build `4.6.3.stable.official.7d41c59c4`, the auditor
reproduced:

- 76/76 tests and the 240-case deterministic property sweep.
- Full-scene smoke and a 180-frame main-scene boot.
- All 18 vertical-slice acceptance checks.
- Static validation.
- A clean worktree after validation.

The only A1–A11 blocker is physical/emulated Android runtime verification.
Director-device FPS, latency, memory, and thermal measurements also remain
explicit performance evidence gaps.
