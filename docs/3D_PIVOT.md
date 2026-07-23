# 3D Pivot — standing decision D-014

Date: 2026-07-23  
Status: accepted and binding

THE FIRST NIGHT moves from the behavioral Phaser prototype to a production
Godot 4.6.3 project with first-person 3D embodiment. Android is the primary
runtime; desktop and browser remain first-class test surfaces. The camera,
physical interaction, and spatial construction are now part of the game's
identity.

The prototype remains a behavioral reference only for world time, warmth, fire
fuel, persistence, offline reconciliation, and morning reports. Its 2D
top-down presentation, Phaser runtime, permanent UI panels, and menu-driven
world actions are superseded.

## Why

The premise needs the player to read distance, exposure, cover, material, and
the campfire's physical safety directly in the world. First-person embodiment
turns gathering, tool use, shelter construction, and darkness into survival
decisions rather than menu operations.

## Guardrails

- Grounded first; strangeness arrives through restrained authored clues.
- The world stays visible. Interface is contextual and compact.
- Simulation ownership stays in a deterministic, scene-free brain.
- The world is authored before procedural systems are considered.
- Android performance governs rendering budgets.
- Browser, Windows, and Android builds are exported from one commit.
- Offline reconciliation never kills the player or destroys major progress.

## GitHub-first test pipeline

Every push and pull request imports the project headlessly, validates scripts,
runs brain/integration tests, and exports web, Windows, and Android. Passing
`main` deploys GitHub Pages; version tags create immutable prerelease artifacts
and checksums. This pipeline is a standing production constraint, not optional
release polish.

## Reversal cost and exit path

The deterministic brain, data definitions, and versioned save schema are
renderer-independent. A future engine or camera pivot can replace the body
without rewriting world rules. The first-person 3D identity itself requires a
Director-level design decision to reverse.

