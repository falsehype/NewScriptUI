# API status

## Current release

The current project is a single-file UI preset stored at `src/NewScriptUI.txt`. Running it in a LocalScript creates one preconfigured demo interface.

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
- Default values and validated configuration
- `GetValue()`, `SetValue()`, and `OnChanged()`
- Window and component cleanup

When that API is implemented, this document and the README will be updated together with a working Studio example.
