# Test Midnight UI in Roblox Studio

1. Open the place you want to test in Roblox Studio.
2. In Explorer, find `StarterPlayer`.
3. Under `StarterPlayerScripts`, insert a **LocalScript**.
4. Open [`src/Midnight UI.txt`](../src/Midnight UI.txt) in this repository.
5. Copy the complete file contents into the LocalScript.
6. Start a client play test. The UI should appear for the local player.
7. Press `RightShift` to hide or show the interface.
8. Hover the tooltip demo toggle to see its tooltip; its delay defaults to 1 second and is configurable in `CONFIG.TOOLTIP_SETTINGS`.
9. Click the gear beside either primary demo toggle to assign a key and choose its activation mode. Set `TOGGLE_SETTINGS_ENABLED` to `false` near the top of the script to hide the gear buttons.

The current file is a preconfigured prototype, not a reusable ModuleScript. It creates the demo UI directly. Avoid placing it in a server Script because it uses client-only services and the local player's PlayerGui.
