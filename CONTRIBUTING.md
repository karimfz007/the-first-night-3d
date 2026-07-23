# Contributing

THE FIRST NIGHT uses Godot 4.6.3 stable and GDScript. Keep simulation changes in
`src/brain`, rendering and input in `src/body`, and tuning constants in
`src/data/tune.gd`.

Before opening a pull request:

1. Run `godot --headless --path . --editor --quit-after 2`.
2. Run `godot --headless --path . --script tests/run_tests.gd`.
3. Run `godot --headless --path . --script tools/static_validate.gd`.
4. Do not commit generated `.godot`, build products, credentials, or unlicensed
   assets.
5. Update the dependency ledger for every external package or asset.

Small pull requests are preferred. Any save-schema change requires a migration
and test. Tunable gameplay values must not be scattered through body scripts.

