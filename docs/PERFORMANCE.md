# Performance report — initial budget

Target: stable playable 30 FPS on the Director's Android device.

## Implemented budgets

- Mobile renderer; Compatibility renderer for web.
- One shadow-casting directional light and at most one small dynamic fire light
  in the normal first-night path.
- Primitive meshes/materials with no texture bandwidth.
- Conservative 70 m directional shadow distance.
- Short fire particle lifetime and low particle count.
- Compact authored island; no procedural generation or terrain extension.
- Physics bodies are simple boxes, capsules, cylinders, and spheres.
- Debug telemetry is disabled by default.

## Current evidence

Headless import/test/export results are recorded by CI and local validation.
Those checks establish correctness and exportability, not device frame rate.
No Android performance number is claimed without a device/profile capture.

## Device capture protocol

Use a release-like debug APK with overlay enabled only for measurement. Walk
from shoreline through trees, harvest a tree, place six shelter pieces, light a
fire, and rotate in place for two minutes. Record median/worst frame time,
memory, draw calls, input feel, thermal behavior, and APK/download size.

