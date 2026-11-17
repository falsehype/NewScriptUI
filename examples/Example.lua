-- ============================================================================
-- Example — the smallest complete use of MidnightLib
-- ============================================================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/falsehype/NewScriptUI/main/src/MidnightLib.lua"))()

local Window = Library:CreateWindow({
	Title = "my script",
	Size = Vector2.new(600, 400),
	ToggleKey = Enum.KeyCode.RightShift,
	Accent = Color3.fromRGB(70, 180, 255),
})

local Tab = Window:AddTab("Main")

local Group = Tab:AddGroupbox("Player", "Left")

Group:AddToggle("SilentAim", {
	Text = "Silent Aim",
	Default = false,
	Callback = function(value)
		print("SilentAim:", value)
	end,
})

Group:AddSlider("WalkSpeed", {
	Text = "WalkSpeed",
	Default = 16,
	Min = 1,
	Max = 500,
	Callback = function(value)
		local character = game.Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

Library:Notify("Loaded!")

-- Later, from code (no UI digging needed):
-- Library.Toggles.SilentAim:Set(true)
-- print(Library.Options.WalkSpeed:Get())
