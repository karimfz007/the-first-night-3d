# Dependency ledger

Pinned engine: **Godot 4.6.3 stable**, MIT license. Purpose: editor, runtime,
rendering, Jolt physics, input, serialization, and platform exports.
Modifications: none. Exit path: project source is ordinary GDScript and Godot
text resources; migrate through documented Godot project conversion.

No runtime add-ons or third-party art/audio are adopted in vertical slice 0.1.
All current geometry, UI, particles, and tones are generated from engine
primitives at runtime.

CI uses GitHub-maintained actions pinned to release majors:
`actions/checkout@v4` (MIT), `actions/upload-artifact@v4` (MIT),
`actions/configure-pages@v5` (MIT), `actions/upload-pages-artifact@v3` (MIT),
and `actions/deploy-pages@v4` (MIT). Purpose: source/LFS checkout, immutable
workflow artifacts, and GitHub Pages deployment. Modifications: none. Exit path:
replace each thin workflow step with `git`, the GitHub REST API, or `gh`.

## Evaluated and not adopted

| Candidate | Pin evaluated | License | Decision and exit |
|---|---:|---|---|
| COGITO | 1.0-era Godot 4 project, evaluated 2026-07-23 | MIT | Rejected for 0.1. It brings inventory, quests, attributes, and interaction ownership that would compete with the deterministic brain/save boundary. Re-evaluate its controller/interaction ideas after the slice. |
| Terrain3D | 1.x line, evaluated 2026-07-23 | MIT | Rejected for the small handcrafted 0.1 beach. Native extension/export surface and mobile/web validation cost exceed the benefit for one compact island. Exit: adopt later behind a world-ground adapter. |
| GdUnit4 | 6.x line, evaluated 2026-07-23 | MIT | Rejected for bootstrap. A 120-line dependency-free headless runner covers pure brain behavior and reduces editor-plugin import risk. Exit: wrap existing test cases in GdUnit4 suites when property testing or richer reports justify it. |
| Godot Touch Input Manager / asset-library joystick components | current listings evaluated 2026-07-23 | mixed/varied | Rejected because small components were inconsistently maintained and still required project-specific gesture arbitration. The owned dual-stick control is isolated in one file and has no simulation authority. |
| Kenney / Poly Haven prototype assets | current catalogs evaluated 2026-07-23 | CC0 | Deferred, not rejected. Primitive geometry keeps the first build reproducible and avoids downloading assets before visual direction is approved. |

Versions are deliberately recorded at the decision-line level for rejected
packages: no rejected source is vendored or executed. Before adoption, a future
cycle must pin an immutable commit and repeat Android, web, and maintenance
checks.
