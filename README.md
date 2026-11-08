<div align="center">

# NewScriptUI

### A compact, dark Roblox UI project built with Luau.

A minimal dark interface with animated controls, draggable and resizable windows, responsive groupboxes, dropdowns, sliders, and an HSV color picker.

<p>
  <img alt="Prototype status" src="https://img.shields.io/badge/status-prototype-8b8b98?style=for-the-badge">
  <img alt="Platform Roblox" src="https://img.shields.io/badge/platform-Roblox-20232a?style=for-the-badge&logo=roblox&logoColor=white">
  <img alt="Language Luau" src="https://img.shields.io/badge/language-Luau-00A2FF?style=for-the-badge">
  <img alt="License not selected" src="https://img.shields.io/badge/license-not%20selected-lightgrey?style=for-the-badge">
</p>

[Features](#features) · [Quick start](#quick-start) · [Project structure](#project-structure) · [Roadmap](#roadmap)

</div>

---

## About

**NewScriptUI** is an experimental Roblox UI project focused on a clean dark appearance, compact spacing, and polished interactions.

The current release is a **single-file UI prototype**. It creates one configured demo interface when run. The project is being developed toward a reusable UI library, but the public `CreateWindow` / `AddToggle` style API is not implemented yet.

> [!NOTE]
> This repository is in an early prototype stage. Features listed below describe the current demo, not a stable, versioned library API.

## Features

| Area | Current prototype |
|---|---|
| Window | Dark rounded window with draggable title bar |
| Resizing | Resizable window with minimum and maximum bounds |
| Minimize | Compact profile bar with drag and restore controls |
| Visibility | `RightShift` toggle |
| Navigation | Sidebar with animated tab selection |
| Layout | Two-column upper groupboxes and a lower groupbox |
| Toggles | Animated switches and a conditional nested row |
| Dropdown | Floating options menu with six demo options |
| Slider | Draggable 0–100 slider with numeric text input |
| Color picker | HSV saturation/value square, hue bar, opacity bar, HEX/RGB input |
| Profile | Player avatar and username in the footer and compact bar |

### Default demo values

- Dropdown: `alfa`
- Options: `alfa`, `delta`, `foxtrot`, `november`, `bravo`, `charlie`
- Slider: minimum `0`, maximum `100`, default `50`, integer rounding
- Initial picker color: `#FF2828`
- Visibility key: `RightShift`

## Quick start

### Test in Roblox Studio

1. Open your Roblox Studio experience.
2. In Explorer, add a **LocalScript** under `StarterPlayer > StarterPlayerScripts`.
3. Open [`src/NewScriptUI.txt`](src/NewScriptUI.txt), copy its contents, and paste them into the LocalScript.
4. Start a client play test and try the UI. Press `RightShift` to hide or show it.

The current source is a standalone preset script. It does not yet return a reusable ModuleScript table or expose configurable methods such as `CreateWindow()` and `AddToggle()`.

See [examples/StudioSetup.md](examples/StudioSetup.md) for more detail and [docs/API_STATUS.md](docs/API_STATUS.md) for the current API status.

## Project structure

```text
NewScriptUI/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── question.md
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   ├── API_STATUS.md
│   └── ROADMAP.md
├── examples/
│   ├── README.md
│   └── StudioSetup.md
├── src/
│   └── NewScriptUI.txt
├── CHANGELOG.md
├── CONTRIBUTING.md
├── README.md
└── SECURITY.md
```

## Roadmap

- [x] Establish the dark visual theme and demo window
- [x] Add dragging, resizing, minimizing, restoring, and visibility toggle
- [x] Add example toggles, dropdown, slider, and color picker
- [ ] Refactor the preset into a reusable library entry point
- [ ] Add configurable windows, tabs, and groupboxes
- [ ] Add reusable control constructors and change callbacks
- [ ] Add component values, setters, and validation
- [ ] Centralize popup/input handling and connection cleanup
- [ ] Add a reliable `Destroy()` lifecycle
- [ ] Document and test each public API method
- [ ] Select a license and publish a tested release

See [API status](docs/API_STATUS.md) and the [roadmap](docs/ROADMAP.md) for details.

## Contributing

Bug reports and focused suggestions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and use the issue templates. Include reproducible steps and remove private information from screenshots or logs.

## Safety and trust

- Review the source before using it in an experience.
- Never commit passwords, cookies, session tokens, API keys, or other private information.
- Do not use the project to interfere with other players, bypass experience rules, or disrupt Roblox experiences.
- NewScriptUI is an independent community project and is not affiliated with, sponsored by, or endorsed by Roblox Corporation.

## License

No license has been selected yet. Until a license is added, the code is publicly viewable but other people do not automatically receive permission to reuse, modify, or redistribute it. A license should be chosen before advertising the project as open source.

---

<div align="center">

**NewScriptUI** · Luau · Early prototype

</div>
