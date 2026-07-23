# Known limitations — vertical slice 0.1

- Geometry and audio are deliberate placeholders; the slice establishes scale,
  composition, dusk lighting, feedback, and budgets, not final art direction.
- Shelter detection uses a nearby-piece completeness rule, not watertight
  volumetric enclosure.
- Snapping uses a reliable half-meter grid and piece offsets; authored socket
  metadata is present but not yet a full graph editor.
- Inventory move/split/drop is keyboard/button oriented and compact; drag/drop
  polish is deferred.
- Crouch checks clearance, but step and steep-slope feel still need physical
  Android device tuning.
- Touch control layout and scale are adjustable; full remapping and controller
  accessibility presets are future work.
- Placeholder audio is synthesized and intentionally sparse.
- Browser persistence depends on the platform completing IndexedDB-backed user
  storage flushes; focus-loss and periodic saves reduce risk.
- CI export configuration exists, but the first GitHub-hosted run is the proof
  of Android SDK/export-template compatibility.
- No measured Director-device FPS, thermal, memory, download-size, or input
  latency result exists until an APK is installed on that device.

