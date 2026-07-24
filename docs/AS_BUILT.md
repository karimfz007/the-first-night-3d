# As-built report — vertical slice 0.1

The source forms one playable first-person survival loop: dusk advances while
the player gathers visible beach resources, crafts a stone tool, harvests more
efficiently, spends material on a snapped shelter and campfire, and manages
warmth through exposure, enclosure, and fuel. State persists and absence is
reconciled deterministically with a causal morning report.

The slice uses engine primitives so interaction, scale, lighting, and system
ownership can be judged before an art package hardens the visual direction.

## Web control repair as built

The exported browser surface now expands to the usable viewport and owns
gesture handling only on the game surface. Desktop control is opt-in through a
canvas click and is visibly released by Escape or any modal. Touch-capable
landscape viewports receive persistent, bounded movement/look/action controls
instead of relying on a hidden first gesture.

Hotbar item definitions now drive use behavior. A selected fire kit opens
campfire placement directly, shows validity and instructions, exposes explicit
desktop/touch confirmation and cancellation, consumes once, and returns to
normal control after a persistent placement.

| Repair gate | Evidence |
|---|---|
| A1 | Desktop 1440×900/1280×800 and mobile 740×360/915×412/1024×600 plus portrait rotation checks assert a full canvas with no document overflow. |
| A2 | Desktop and touch tests open and close the persistent top-right Settings surface. |
| A3 | Browser assertions cover pre-capture prompt, deliberate canvas capture, modal safety, Escape release, and restored prompt. |
| A4 | Android-landscape emulation verifies visible bounded controls and simultaneous movement/look touches. |
| A5–A6 | Touch automation selects the fixture fire kit, enters placement, checks instructions and controls, cancels, re-enters, previews, places, and ignites. Godot live-scene acceptance covers the same semantic selection foundation. |
| A7 | The existing live-scene route still covers physical gathering/crafting/fire use; the browser fixture deterministically isolates the repaired selection-through-ignition UI route. |
| A8 | Desktop/mobile resize, portrait/landscape transition, focus release, background/resume, and released touch state are automated. |
| A9 | Six PNGs are committed in `docs/evidence/web-control-repair`. |
| A10 | Protected CI runs Godot verification, browser verification, all exports, Pages, and tag-release jobs from source commits. |

## Acceptance mapping

| Gate | Source evidence |
|---|---|
| A1–A3 | public repository, protected `main`, live Pages deployment, and hosted artifacts for audited SHA |
| A4 | desktop/full-scene and touch-contract checks pass; Android runtime remains not verified |
| A5 | `main.tscn`, player controller, authored world, interactable resources, and acceptance playthrough |
| A6 | inventory, item/recipe data, crafting UI, save codec |
| A7 | building definitions, preview validation, placed records, six piece types |
| A8 | fire object, heat/fuel loop, shelter protection, HUD feedback |
| A9–A10 | versioned save manager, reconciler, morning report, headless tests |
| A11 | 77 passing assertions, 240-case property sweep, full-scene smoke, 19-check acceptance playthrough, browser suite, and CI workflow |
| A12 | fails only because A4 has no physical/emulated Android runtime evidence |
| A13 | dependency, architecture, pivot, limitation, performance, and as-built docs |

## Recommended next vertical slice

**0.2 — The Water Run:** add a physically readable freshwater route from the
first shelter to an inland catchment, including thirst, container filling,
boiling at the campfire, a second authored landmark, and weather pressure. It
extends survive → operate, exercises inventory/use behaviors and fire stations,
and makes the existing island spatially meaningful without introducing combat
or procedural scope.
