# Web control repair report

Date: 2026-07-24
Baseline: `v0.1.0` / `bd8308a37bc864e453b67e7e6aa0c8d16fcc611e`

## Reproduction

The deployed Pages build was inspected at desktop 16:9 and 16:10 sizes and at
915×412 Android-landscape dimensions before source changes.

| Director-observed defect | Root cause |
|---|---|
| No visible settings button | Settings controls existed only as a second column inside the inventory panel. There was no independent settings affordance. |
| Game did not fill the visible frame | The HTML canvas adapted to the page, but Godot's default `keep` stretch aspect retained a 1280×720 internal 16:9 area. A 915×412 canvas showed about 91 pixels of black space on both sides. The default shell also had no explicit dynamic-viewport or safe-area policy. |
| Desktop capture felt active outside the game | The black bars were inside the full-page canvas, so they still delivered game input. Any unhandled left click captured the pointer, there was no pre-capture prompt, and closing a modal immediately recaptured the mouse. |
| Fire kit selection did not lead to placement | Hotbar selection only changed an integer. It never inspected `use_behavior`, never chose the campfire piece, and never entered build mode. Placement required the undiscoverable sequence `B`, repeated piece cycling, and confirmation. |
| Mobile movement was undiscoverable | The virtual stick was drawn only while a movement touch was already active. Touch controls were also gated solely by the `mobile` feature rather than detected touch capability. |
| Mobile interaction extended outside the visible game | Godot treated the internal black letterbox area as part of the canvas. The touch handler also divided the whole viewport into movement/look halves instead of requiring contact inside the visible joystick and excluding UI controls. |

## Repair direction

- Expand the Godot viewport instead of preserving an internal fixed aspect.
- Use a custom full-viewport shell with dynamic viewport units, safe-area
  padding, gesture suppression on the game surface, and visible load failure.
- Make pointer ownership explicit and modal-safe.
- Render a persistent virtual joystick and bounded look region when touch is
  available.
- Give item selection semantic behavior so selecting a fire kit immediately
  starts campfire placement.
- Expose read-only runtime state for deterministic browser assertions while
  retaining all gameplay authority in Godot.

## Implemented verification

The repair is guarded by Playwright 1.61.1 against the real exported Web build.
It checks canvas fill/overflow, persistent Settings, pointer-lock
capture/release, Android-landscape control visibility and multitouch,
narrow/wide/rotated viewport recovery, background/resume, and the touch fire-kit
select/cancel/preview/place/ignite path. Six screenshots are retained under
`docs/evidence/web-control-repair`.
