# As-built report — vertical slice 0.1

The source forms one playable first-person survival loop: dusk advances while
the player gathers visible beach resources, crafts a stone tool, harvests more
efficiently, spends material on a snapped shelter and campfire, and manages
warmth through exposure, enclosure, and fuel. State persists and absence is
reconciled deterministically with a causal morning report.

The slice uses engine primitives so interaction, scale, lighting, and system
ownership can be judged before an art package hardens the visual direction.

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
| A11 | 76 passing assertions, 240-case property sweep, full-scene smoke, 18-check acceptance playthrough, and CI workflow |
| A12 | fails only because A4 has no physical/emulated Android runtime evidence |
| A13 | dependency, architecture, pivot, limitation, performance, and as-built docs |

## Recommended next vertical slice

**0.2 — The Water Run:** add a physically readable freshwater route from the
first shelter to an inland catchment, including thirst, container filling,
boiling at the campfire, a second authored landmark, and weather pressure. It
extends survive → operate, exercises inventory/use behaviors and fire stations,
and makes the existing island spatially meaningful without introducing combat
or procedural scope.
