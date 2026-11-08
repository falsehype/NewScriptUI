# Midnight UI API status

## Current release

The current project is a single-file UI preset stored at `src/MidnightUI.lua`. Running it in a LocalScript creates one preconfigured demo interface.

The demo now includes bottom-right hover tooltips with configurable per-toggle delays (one-second default), and shared pointer-coordinate handling for consistent hit testing. The demo also includes settings gears beside its two primary toggle rows. Each gear opens an overlay with an unassigned-by-default key field and an activation-type dropdown. Available modes are `Always on`, `Hold on`, and `Toggle`. Key capture accepts available keyboard `Enum.KeyCode` values and the first three mouse buttons. See [Toggle settings](TOGGLE_SETTINGS.md) for details.

It currently does **not** return a library table, and these methods do not exist yet:

- `Library:CreateWindow()`
- `Window:CreateTab()`
- `Tab:CreateGroupbox()`
- `Groupbox:AddToggle()`
- `Groupbox:AddDropdown()`
- `Groupbox:AddSlider()`
- `Groupbox:AddColorPicker()`

Code examples that use those methods are design proposals until the refactor is complete. Do not build integrations against the planned API yet.

## Planned public API

The first stable API should support:

- Window creation and configuration
- Tabs and groupboxes
- Toggle, dropdown, slider, and color-picker components
- Optional toggle settings with keybinds and activation modes
- Default values and validated configuration
- `GetValue()`, `SetValue()`, and `OnChanged()`
- Window and component cleanup

When that API is implemented, this document and the README will be updated together with a working Studio example.
