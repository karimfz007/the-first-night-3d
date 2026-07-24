# Project state

Updated: 2026-07-24
Cycle: vertical slice 0.1 / DRIFT  
Engine pin: Godot 4.6.3 stable

## Current

- Production pivot: first-person 3D, Godot, Android-first.
- Deterministic brain boundary and versioned save schema established.
- Hand-authored primitive beach slice implemented without third-party assets.
- Physical gathering, starter crafting, modular building, campfire/warmth,
  persistence, offline reconciliation, and morning report implemented.
- Desktop and landscape touch control surfaces implemented.
- Blocking Web UX repair implemented: true full-viewport canvas, safe-area
  shell, explicit click-to-control pointer ownership, persistent settings/help,
  visible bounded touch controls, and semantic fire-kit placement.
- Headless validation and tri-platform CI/export pipeline operational.
- Local Godot 4.6.3 evidence: 77/77 assertions, static validation pass, clean
  full-scene smoke, 19/19 live-scene acceptance checks, 180-frame main-scene
  boot, and a real 1280×720 capture.
- Playwright evidence covers desktop initial/settings/pointer lock/resize,
  Android-landscape bounded multitouch controls, narrow/wide/orientation
  recovery, background/resume, touch hotbar selection, campfire
  preview/cancel/place, and ignition.
- Public repository, protected `main`, Pages deployment, and immutable hosted
  Windows/Android/checksum artifacts verified for implementation SHA
  `6921215f4a6f14768f5b2f63f95cfe7a9232a24c`.

## Remaining external evidence

- A4 Android runtime remains not verified because no APK was installed and
  played on the Director's device or an emulator.
- Touch-capable Chromium emulation verifies the repaired Web control surface,
  but is not evidence of APK runtime behavior, Android thermals, or hardware
  performance.
- Android FPS, latency, memory, and thermal evidence needs an actual
  Director-device run; desktop/headless validation cannot manufacture it.

## Canonical next work

Run the tagged APK on the Director's Android device and record the protocol in
`PERFORMANCE.md`. Then pursue **0.2 — The Water Run** in `AS_BUILT.md`.
