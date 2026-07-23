# Performance report — initial budget

Target: stable playable 30 FPS on the Director's Android device.

## Implemented budgets

- Mobile renderer; Compatibility renderer for web.
- ETC2/ASTC VRAM texture import enabled for the Android export path.
- One shadow-casting directional light and at most one small dynamic fire light
  in the normal first-night path.
- Primitive meshes/materials with no texture bandwidth.
- Conservative 70 m directional shadow distance.
- Short fire particle lifetime and low particle count.
- Compact authored island; no procedural generation or terrain extension.
- Physics bodies are simple boxes, capsules, cylinders, and spheres.
- Debug telemetry is disabled by default.

## Current evidence

Pinned Godot 4.6.3 completed the 76-check test suite, an 18-check end-to-end
acceptance playthrough, static validation, a clean composition-root smoke, and
a 180-frame full-scene headless boot on Windows. A
real Compatibility-renderer capture completed at 1280×720 on an NVIDIA GeForce
GTX 1650 without runtime errors. These checks establish source/runtime health,
not Android frame rate. No Android performance number is claimed without a
device/profile capture.

## Device capture protocol

Use a release-like debug APK with overlay enabled only for measurement. Walk
from shoreline through trees, harvest a tree, place six shelter pieces, light a
fire, and rotate in place for two minutes. Record median/worst frame time,
memory, draw calls, input feel, thermal behavior, and APK/download size.
