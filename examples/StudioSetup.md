# Test NewScriptUI in Roblox Studio

1. Open the place you want to test in Roblox Studio.
2. In Explorer, find `StarterPlayer`.
3. Under `StarterPlayerScripts`, insert a **LocalScript**.
4. Open [`src/NewScriptUI.txt`](../src/NewScriptUI.txt) in this repository.
5. Copy the complete file contents into the LocalScript.
6. Start a client play test. The UI should appear for the local player.
7. Press `RightShift` to hide or show the interface.

The current file is a preconfigured prototype, not a reusable ModuleScript. It creates the demo UI directly. Avoid placing it in a server Script because it uses client-only services and the local player's PlayerGui.
