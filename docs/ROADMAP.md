# Midnight-UI roadmap

This roadmap separates the current working prototype from planned library features. An unchecked item is not available in the current source.

## Phase 1 — Foundation

- [x] Dark theme and compact window layout
- [x] Window dragging and screen-edge clamping
- [x] Resizing, minimizing, and restoring
- [x] `RightShift` visibility toggle
- [x] Demo groupboxes and animated controls
- [x] HSV color picker with hue, opacity, and HEX/RGB entry
- [x] Optional settings gear beside the two primary demo toggles
- [x] Floating key settings panel with keyboard/mouse capture
- [x] `Always on`, `Hold on`, and `Toggle` activation modes
- [x] Bottom-right hover tooltip placement with configurable per-toggle delay
- [x] Shared mouse/touch coordinate conversion for hit testing and drag interactions

## Phase 2 — Reusable API

- [ ] Refactor the startup script into a ModuleScript library entry point
- [ ] Add `Library:CreateWindow(config)`
- [ ] Add dynamic tab and groupbox creation
- [ ] Add control constructors for toggles, dropdowns, sliders, and color pickers
- [ ] Expose toggle settings as an option in a future `AddToggle()` configuration
- [ ] Return component objects with `GetValue()`, `SetValue()`, and `OnChanged()`
- [ ] Validate user configuration and provide readable errors

## Phase 3 — Reliability

- [ ] Keep window, popup, and component state isolated per window
- [ ] Centralize input connections and make them disconnectable
- [ ] Add a cleanup registry for connections, tweens, and temporary instances
- [ ] Ensure popups render above groupboxes and do not start window dragging
- [ ] Test popup placement near every screen edge
- [ ] Test keyboard, numpad, function-key, mouse, and touch behavior in Studio
- [ ] Add `Window:Destroy()` and component cleanup

## Phase 4 — Documentation and releases

- [ ] Add one working Studio example per component
- [ ] Document defaults, configuration, callbacks, and return values
- [ ] Add screenshots for all controls
- [ ] Select and add an open-source license
- [ ] Tag a tested release and pin stable examples to that tag

## Proposed object hierarchy

```text
Library
└── Window
    └── Tab
        └── Groupbox
            ├── Toggle
            ├── Dropdown
            ├── Slider
            └── ColorPicker
```

The hierarchy above is a design target, not an implemented API.
