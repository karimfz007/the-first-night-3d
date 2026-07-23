# Dependency ledger

Pinned engine: **Godot 4.6.3 stable**, MIT license. Purpose: editor, runtime,
rendering, Jolt physics, input, serialization, and platform exports.
Modifications: none. Exit path: project source is ordinary GDScript and Godot
text resources; migrate through documented Godot project conversion.

No runtime add-ons or third-party art/audio are adopted in vertical slice 0.1.
All current geometry, UI, particles, and tones are generated from engine
primitives at runtime.

CI uses GitHub-maintained actions pinned to release majors:
`actions/checkout@v5` (MIT), `actions/upload-artifact@v4` (MIT),
`actions/configure-pages@v5` (MIT), `actions/upload-pages-artifact@v3` (MIT),
and `actions/deploy-pages@v4` (MIT). Purpose: source/LFS checkout, immutable
workflow artifacts, and GitHub Pages deployment. Modifications: none. Exit path:
replace each thin workflow step with `git`, the GitHub REST API, or `gh`.

## Evaluated and not adopted

| Candidate | Pin evaluated | License | Decision and exit |
|---|---:|---|---|
| [COGITO](https://github.com/Phazorknight/Cogito) | 1.1.0 / Godot 4.4 baseline, evaluated 2026-07-23 | MIT | Rejected for 0.1. It brings inventory, quests, attributes, save slots, and interaction ownership that would compete with the deterministic brain/save boundary; its documented base is older than the pinned 4.6.3 runtime. Re-evaluate controller ideas after the slice. |
| [Terrain3D](https://github.com/TokisanGames/Terrain3D) | 1.0.2-stable, evaluated 2026-07-23 | MIT | Rejected for the small handcrafted 0.1 beach. Its C++ GDExtension, experimental web path, thread/template matching, LOD, and collision validation surface exceed the benefit for one compact island. Exit: adopt later behind a world-ground adapter. |
| [GdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) | 6.1.3, evaluated 2026-07-23 | MIT | Rejected for bootstrap. The compatibility table reaches Godot 4.6.2 but does not yet list pinned 4.6.3. A dependency-free headless runner currently provides 76 assertions plus a 240-case property sweep. Exit: wrap cases in GdUnit4 when 4.6.3 support and richer reports justify it. |
| [Godot Thumbstick Plugin](https://github.com/JoenTNT/godot_thumbstick_addon) | 1.2.1 / Godot 4.4 baseline, evaluated 2026-07-23 | MIT | Rejected because it targets 4.4, supplies one stick rather than coordinated dual-stick/action gesture arbitration, and would still require project-specific integration. The owned control is isolated in one file and has no simulation authority. |
| Kenney / Poly Haven prototype assets | current catalogs evaluated 2026-07-23 | CC0 | Deferred, not rejected. Primitive geometry keeps the first build reproducible and avoids downloading assets before visual direction is approved. |

Versions are deliberately recorded at the decision-line level for rejected
packages: no rejected source is vendored or executed. Before adoption, a future
cycle must pin an immutable commit and repeat Android, web, and maintenance
checks.
