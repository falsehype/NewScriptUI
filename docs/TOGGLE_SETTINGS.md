# Midnight-UI toggle settings menu

The current prototype adds a settings gear to the two main demo toggle rows. The source setting is controlled by `TOGGLE_SETTINGS_ENABLED` near the top of `src/Midnight-UI.txt`.

```lua
local TOGGLE_SETTINGS_ENABLED = true
local TOGGLE_SETTINGS_ICON = "rbxassetid://111506353970498"
```

Set the boolean to `false` to remove the settings buttons. The gear is placed to the right of each switch and has a hover tint/background effect. Clicking it opens a floating panel outside the main window's clipped content area.

## Panel

- **Key** — an unassigned keybind field with the placeholder `Press a key`. Focus the field and press the desired input.
- **Type** — a dropdown with `Always on`, `Hold on`, and `Toggle`.

The chosen key is retained when the panel is closed and reopened. Each of the two demo toggles has its own key and activation type.

## Supported inputs

Keyboard input is captured from non-`Unknown` `Enum.KeyCode` values. This includes available function keys, navigation keys such as `Insert`, modifier keys, and numpad keys/operators. Numpad keys use readable `Numpad` labels.

The first three mouse buttons can also be assigned and are displayed exactly as `Mouse 1`, `Mouse 2`, and `Mouse 3`.

## Activation modes

| Mode | Behavior |
|---|---|
| `Always on` | Forces the toggle on. |
| `Hold on` | Turns the toggle on while the assigned input is held and off after release. |
| `Toggle` | Flips the toggle each time the assigned input is pressed. |

A key is not assigned by default. Until one is selected, the activation mode does not react to keyboard or mouse input; the on-screen switch remains usable.

## Scope and status

This feature is implemented in the current single-file demo for its two primary toggle rows. It is not yet exposed through a reusable `Groupbox:AddToggle()` API because the general library API has not been implemented. The current setup is intended for ordinary Roblox Studio LocalScript testing in an experience you control.

## Tooltip hover delay

Tooltip timing is configured in `CONFIG.TOOLTIP_SETTINGS` in `src/Midnight-UI.txt`:

```lua
TOOLTIP_SETTINGS = {
    DEFAULT_DELAY = 1,
    DELAY_BY_TOGGLE = {
        TooltipToggle = 1,
    },
}
```

Values are seconds. `DEFAULT_DELAY` is the fallback for tooltip-enabled toggles; add or change a toggle's instance name in `DELAY_BY_TOGGLE` to customize that toggle independently.
