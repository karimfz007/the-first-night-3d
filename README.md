# THE FIRST NIGHT

[![CI](https://github.com/karimfz007/the-first-night-3d/actions/workflows/ci.yml/badge.svg)](https://github.com/karimfz007/the-first-night-3d/actions/workflows/ci.yml)

**DRIFT — vertical slice 0.1**

A first-person, Android-first physical survival slice set on a handcrafted
tropical beach in the Bermuda Triangle. Gather driftwood, stone, and fiber;
craft a primitive tool; build a small snapped shelter; light a campfire; and
survive the transition from dusk into the first night. The persistent world
continues fairly while the player is away and explains the result on return.

## Play and builds

- Browser build: `https://karimfz007.github.io/the-first-night-3d/` (active after the
  first successful `main` deployment)
- Windows and Android debug builds: see
  [Actions artifacts](https://github.com/karimfz007/the-first-night-3d/actions/workflows/ci.yml)
- Versioned build history: see
  [Releases](https://github.com/karimfz007/the-first-night-3d/releases)

## Controls

| Action | Desktop |
|---|---|
| Move / look | WASD / mouse |
| Sprint / crouch / jump | Shift / C / Space |
| Interact / tool action | E / left mouse |
| Inventory / crafting | I or Tab / K |
| Build mode | B |
| Cycle piece / rotate | mouse wheel / Q and R |
| Place / cancel | left mouse / right mouse or Escape |
| Save / debug overlay | F5 / F3 |

Android presents scalable dual-stick movement/look controls with interact,
action, jump, crouch, hotbar, inventory, and build buttons. Control sides and
scale are adjustable in Settings.

## Development

Use exactly **Godot 4.6.3 stable**, standard (GDScript) build. Open
`project.godot` and run the main scene. The Mobile renderer and Jolt Physics are
the baseline. No asset download is needed.

```text
src/brain  deterministic simulation, inventory, crafting, saves, reconciliation
src/body   scenes, player, world objects, feedback, UI, touch controls
src/data   tuning and data definitions
tests      dependency-free headless test suite
docs       canon, architecture, audits, and cycle records
```

Headless verification:

```sh
godot --headless --path . --editor --quit-after 2
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tools/static_validate.gd
```

Exports are produced from the same commit by `.github/workflows/ci.yml`.
See [Architecture](docs/ARCHITECTURE.md), [3D pivot](docs/3D_PIVOT.md),
[known limitations](docs/KNOWN_LIMITATIONS.md), and
[dependencies](DEPENDENCIES.md).
