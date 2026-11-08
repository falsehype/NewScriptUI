local scriptLoadStartTime = os.clock()

local F = {}

local SERVICES = {
	Players = game:GetService("Players"),
	UserInputService = game:GetService("UserInputService"),
	TweenService = game:GetService("TweenService"),
	RunService = game:GetService("RunService"),
	GuiService = game:GetService("GuiService"),
}

local PLAYER = {
	LocalPlayer = SERVICES.Players.LocalPlayer,
}
PLAYER.PlayerGui = PLAYER.LocalPlayer:WaitForChild("PlayerGui")

local Existing = PLAYER.PlayerGui:FindFirstChild("MidnightUI")
if Existing then
	Existing:Destroy()
end

local COLORS = {
	Background = Color3.fromRGB(13, 13, 15),
	Sidebar = Color3.fromRGB(11, 11, 13),
	Border = Color3.fromRGB(32, 32, 36),
	Divider = Color3.fromRGB(38, 38, 43),
	Title = Color3.fromRGB(230, 230, 235),
	Muted = Color3.fromRGB(125, 125, 135),
	TabIdle = Color3.fromRGB(150, 150, 155),
	TabHover = Color3.fromRGB(190, 190, 198),
	Accent = Color3.fromRGB(70, 180, 255),
	SelectBg = Color3.fromRGB(38, 38, 43),
	Username = Color3.fromRGB(255, 255, 255),
	Icon = Color3.fromRGB(140, 140, 148),
	IconHover = Color3.fromRGB(210, 210, 218),
	IconActive = Color3.fromRGB(70, 180, 255),
	Gray = Color3.fromRGB(140, 140, 148),
	White = Color3.fromRGB(255, 255, 255),
}

local CONFIG = {
	WINDOW_SIZE = Vector2.new(600, 400),
	MIN_SIZE = Vector2.new(420, 280),
	MAX_SIZE = Vector2.new(1100, 800),
	MINI_SIZE = Vector2.new(236, 42),
	TITLE_H = 36,
	PROFILE_H = 34,
	SIDEBAR_W = 142,
	TAB_H = 28,
	DRAG_SMOOTH = 0.05,
	SELECT_EXPAND_T = 0.32,
	MINI_TRANSITION_T = 0.17,
	spacing = 5,
	DEFAULT_DROPDOWN_OPTION = "alfa",
	SLIDER_SETTINGS = {
		min = 0,
		max = 100,
		rounding = 1,
		default = 50,
	},
	DROPDOWN_OPTIONS = {"alfa", "delta", "foxtrot", "november", "bravo", "charlie"},
	TOGGLE_SETTINGS_ENABLED = true,
	TOGGLE_SETTINGS_ICON = "rbxassetid://111506353970498",
	TOGGLE_SETTINGS_TYPES = {"Always on", "Hold on", "Toggle"},
	-- Tooltip delays are in seconds. Override individual toggle names below;
	-- any toggle without an override uses DEFAULT_DELAY.
	TOOLTIP_SETTINGS = {
		DEFAULT_DELAY = 1,
		DELAY_BY_TOGGLE = {
			TooltipToggle = 1,
		},
		GAP = 14,
		WIDTH = 220,
	},
}

function F.create(className, parent, properties)
	local object = Instance.new(className)
	for property, value in pairs(properties or {}) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

function F.addCorner(object, radius)
	return F.create("UICorner", object, {
		CornerRadius = UDim.new(0, radius),
	})
end

function F.addStroke(object)
	return F.create("UIStroke", object, {
		Color = COLORS.Border,
		Thickness = 1,
		Transparency = 0.15,
	})
end

local activeTweens = {}

function F.tween(key, object, duration, properties, style, direction)
	local oldTween = activeTweens[key]
	if oldTween then
		oldTween:Cancel()
	end

	local newTween = SERVICES.TweenService:Create(
		object,
		TweenInfo.new(
			duration,
			style or Enum.EasingStyle.Quad,
			direction or Enum.EasingDirection.Out
		),
		properties
	)

	activeTweens[key] = newTween
	newTween.Completed:Connect(function()
		if activeTweens[key] == newTween then
			activeTweens[key] = nil
		end
	end)
	newTween:Play()
	return newTween
end

function F.makeText(parent, text, size, position, fontSize, color, font)
	return F.create("TextLabel", parent, {
		BackgroundTransparency = 1,
		Text = text,
		Size = size,
		Position = position,
		Font = font or Enum.Font.GothamMedium,
		TextSize = fontSize,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		BorderSizePixel = 0,
	})
end

local ScreenGui = F.create("ScreenGui", PLAYER.PlayerGui, {
	Name = "MidnightUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 99,
})

local Root = F.create("CanvasGroup", ScreenGui, {
	Name = "Root",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	GroupTransparency = 0,
})

local getPointerPosition

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

local initialPosition = Vector2.new(
	math.max(0, math.floor((viewport.X - CONFIG.WINDOW_SIZE.X) * 0.5)),
	math.max(0, math.floor((viewport.Y - CONFIG.WINDOW_SIZE.Y) * 0.5))
)

local state = {
	minimized = false,
	guiVisible = true,
	animating = false,
	visibilityAnimating = false,
	fullPos = initialPosition,
	fullSize = CONFIG.WINDOW_SIZE,
	miniPos = nil,
}

function F.clampToScreen(position, size)
	local currentCamera = workspace.CurrentCamera
	if not currentCamera then
		return position
	end

	local screenSize = currentCamera.ViewportSize
	return Vector2.new(
		math.clamp(position.X, 0, math.max(0, screenSize.X - size.X)),
		math.clamp(position.Y, 0, math.max(0, screenSize.Y - size.Y))
	)
end

local window = F.create("CanvasGroup", Root, {
	Name = "MainWindow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CONFIG.WINDOW_SIZE.X, CONFIG.WINDOW_SIZE.Y),
	BackgroundColor3 = COLORS.Background,
	BackgroundTransparency = 0,
	GroupTransparency = 0,
	BorderSizePixel = 0,
	ClipsDescendants = true,
})

F.addCorner(window, 6)
F.addStroke(window)

local titleBar = F.create("Frame", window, {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, CONFIG.TITLE_H),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 5,
})

local dragRegion = F.create("TextButton", titleBar, {
	Name = "DragRegion",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(1, -42, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 5,
})

local titleLabel = F.makeText(
	titleBar,
	"Midnight UI",
	UDim2.fromScale(1, 1),
	UDim2.fromOffset(0, 0),
	15,
	COLORS.Title,
	Enum.Font.GothamMedium
)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.ZIndex = 6
titleLabel.Active = false

F.create("Frame", titleBar, {
	Name = "TitleDivider",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	ZIndex = 6,
})

local minimizeBtn = F.create("TextButton", titleBar, {
	Name = "MinimizeButton",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(22, 22),
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 8,
})
F.addCorner(minimizeBtn, 4)

local minimizeIcon = F.create("Frame", minimizeBtn, {
	Name = "MinimizeIcon",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(10, 2),
	BackgroundColor3 = COLORS.Icon,
	BorderSizePixel = 0,
	ZIndex = 9,
})

local body = F.create("Frame", window, {
	Name = "Body",
	Position = UDim2.fromOffset(0, CONFIG.TITLE_H),
	Size = UDim2.new(1, 0, 1, -(CONFIG.TITLE_H + CONFIG.PROFILE_H)),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 2,
})

local sidebar = F.create("Frame", body, {
	Name = "Sidebar",
	Size = UDim2.new(0, CONFIG.SIDEBAR_W, 1, 0),
	BackgroundColor3 = COLORS.Sidebar,
	BorderSizePixel = 0,
})

F.create("Frame", sidebar, {
	Name = "SidebarDivider",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
})

local content = F.create("Frame", body, {
	Name = "Content",
	Position = UDim2.fromOffset(CONFIG.SIDEBAR_W, 0),
	Size = UDim2.new(1, -CONFIG.SIDEBAR_W, 1, 0),
	BackgroundColor3 = COLORS.Background,
	BorderSizePixel = 0,
})

local helloGroupBox = F.create("Frame", content, {
	Name = "HelloGroupBox",
	Position = UDim2.fromOffset(CONFIG.spacing, 16),
	Size = UDim2.new(0.5, -(CONFIG.spacing * 1.5), 0, 100),
	BackgroundColor3 = Color3.fromRGB(16, 16, 19),
	BorderSizePixel = 0,
	ClipsDescendants = false,
	ZIndex = 3,
})
F.addCorner(helloGroupBox, 7)
F.addStroke(helloGroupBox)

local helloShadow = Instance.new("UIShadow")
helloShadow.Name = "GroupBoxShadow"
helloShadow.Color = Color3.fromRGB(0, 0, 0)
helloShadow.Transparency = 0.56
helloShadow.BlurRadius = UDim.new(0, 14)
helloShadow.Offset = UDim2.fromOffset(0, 4)
helloShadow.Spread = UDim2.fromOffset(0, 1)
helloShadow.ShowBehindParent = true
helloShadow.Parent = helloGroupBox

local helloTitle = F.makeText(
	helloGroupBox,
	"hello!",
	UDim2.new(1, -(CONFIG.spacing * 2), 0, 18),
	UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing),
	12,
	COLORS.Muted,
	Enum.Font.GothamBold
)
helloTitle.ZIndex = 4

local headerDivider = F.create("Frame", helloGroupBox, {
	Name = "HeaderDivider",
	Position = UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing + 18 + CONFIG.spacing),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 1),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	ZIndex = 4,
})

local toggleEnabled = false
local helloSettingsMode = "Toggle"

local toggleRowY = CONFIG.spacing + 18 + CONFIG.spacing + 1 + CONFIG.spacing

function F.setToggleHover(hovered, row, label)
	local highlight = row:FindFirstChild("HoverHighlight")
	if not highlight then
		-- Hover box drawn 1px beyond the toggle on every side, so toggles
		-- can be packed tightly while their hover effects stay separated.
		highlight = F.create("Frame", row, {
			Name = "HoverHighlight",
			Position = UDim2.fromOffset(-1, -1),
			Size = UDim2.new(1, 2, 1, 2),
			BackgroundColor3 = COLORS.SelectBg,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 4,
		})
		F.addCorner(highlight, 6)
	end

	F.tween("toggle_hover_" .. row.Name, highlight, 0.14, {
		BackgroundTransparency = hovered and 0.35 or 1,
	})
	F.tween("toggle_text_hover_" .. row.Name, label, 0.14, {
		TextColor3 = hovered and COLORS.Title or COLORS.TabIdle,
	})
end

local toggleRow = F.create("TextButton", helloGroupBox, {
	Name = "ToggleRow",
	Position = UDim2.fromOffset(CONFIG.spacing, toggleRowY),
	Size = UDim2.new(1, -(CONFIG.spacing * 3 + (CONFIG.TOGGLE_SETTINGS_ENABLED and 20 or 0)), 0, 40),
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 5,
})
F.addCorner(toggleRow, 5)

local toggleLabel = F.makeText(
	toggleRow,
	"this is a toggle",
	UDim2.new(1, -66, 1, 0),
	UDim2.fromOffset(0, 0),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
toggleLabel.Name = "ToggleLabel"
toggleLabel.ZIndex = 6
toggleLabel.Active = false

local toggleTrack = F.create("Frame", toggleRow, {
	Name = "ToggleTrack",
	Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10),
	Size = UDim2.fromOffset(36, 20),
	BackgroundColor3 = Color3.fromRGB(57, 57, 64),
	BorderSizePixel = 0,
	ZIndex = 6,
	Active = false,
})
F.addCorner(toggleTrack, 10)

local toggleKnob = F.create("Frame", toggleTrack, {
	Name = "ToggleKnob",
	Position = UDim2.fromOffset(3, 3),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = Color3.fromRGB(190, 190, 198),
	BorderSizePixel = 0,
	ZIndex = 7,
	Active = false,
})
F.addCorner(toggleKnob, 7)

local settingsButton
if CONFIG.TOGGLE_SETTINGS_ENABLED then
	toggleLabel.Size = UDim2.new(1, -66, 1, 0)
	toggleTrack.Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10)
	settingsButton = F.create("ImageButton", helloGroupBox, {
		Name = "SettingsButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -CONFIG.spacing, 0, toggleRowY + 20),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = COLORS.SelectBg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = CONFIG.TOGGLE_SETTINGS_ICON,
		ImageColor3 = COLORS.Icon,
		ImageTransparency = 0,
		AutoButtonColor = false,
		ZIndex = 8,
	})
	F.addCorner(settingsButton, 4)
	settingsButton.MouseEnter:Connect(function()
		F.tween("toggle_settings_hover_" .. toggleRow.Name, settingsButton, 0.13, {
			BackgroundTransparency = 0.25,
			ImageColor3 = COLORS.IconHover,
		})
	end)
	settingsButton.MouseLeave:Connect(function()
		F.tween("toggle_settings_hover_" .. toggleRow.Name, settingsButton, 0.13, {
			BackgroundTransparency = 1,
			ImageColor3 = COLORS.Icon,
		})
	end)
end

function F.setHelloToggle(enabled)
	if helloSettingsMode == "Always on" then
		enabled = true
	end
	toggleEnabled = enabled

	F.tween(
		"hello_toggle_track",
		toggleTrack,
		0.18,
		{
			BackgroundColor3 = enabled and COLORS.Accent or Color3.fromRGB(57, 57, 64),
		},
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	F.tween(
		"hello_toggle_knob",
		toggleKnob,
		0.18,
		{
			Position = enabled
				and UDim2.new(1, -17, 0, 3)
				or UDim2.fromOffset(3, 3),
			BackgroundColor3 = enabled
				and Color3.fromRGB(245, 249, 255)
				or Color3.fromRGB(190, 190, 198),
		},
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
end

toggleRow.MouseEnter:Connect(function()
	F.setToggleHover(true, toggleRow, toggleLabel)
end)

toggleRow.MouseLeave:Connect(function()
	F.setToggleHover(false, toggleRow, toggleLabel)
end)

toggleRow.Activated:Connect(function()
	F.setHelloToggle(not toggleEnabled)
end)

local rightGroupBox = helloGroupBox:Clone()
rightGroupBox.Name = "RightGroupBox"
rightGroupBox.Position = UDim2.new(0.5, CONFIG.spacing / 2, 0, 16)
rightGroupBox.Size = UDim2.new(0.5, -(CONFIG.spacing * 1.5), 0, 100)
rightGroupBox.Parent = content

local rightToggleRow = rightGroupBox:WaitForChild("ToggleRow")
local rightToggleTrack = rightToggleRow:WaitForChild("ToggleTrack")
local rightToggleKnob = rightToggleTrack:WaitForChild("ToggleKnob")
local rightToggleEnabled = false
local rightSettingsMode = "Toggle"

local rightToggleLabel = rightToggleRow:WaitForChild("ToggleLabel")
rightToggleLabel.Position = UDim2.fromOffset(0, 0)
rightToggleLabel.Size = UDim2.new(1, -66, 1, 0)

rightToggleRow.MouseEnter:Connect(function()
	F.setToggleHover(true, rightToggleRow, rightToggleLabel)
end)

rightToggleRow.MouseLeave:Connect(function()
	F.setToggleHover(false, rightToggleRow, rightToggleLabel)
end)

function F.setRightToggle(enabled)
	if rightSettingsMode == "Always on" then
		enabled = true
	end
	rightToggleEnabled = enabled
	F.tween("right_toggle_track", rightToggleTrack, 0.18, {
		BackgroundColor3 = rightToggleEnabled and COLORS.Accent or Color3.fromRGB(57, 57, 64),
	})
	F.tween("right_toggle_knob", rightToggleKnob, 0.18, {
		Position = rightToggleEnabled and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3),
		BackgroundColor3 = rightToggleEnabled and Color3.fromRGB(245, 249, 255) or Color3.fromRGB(190, 190, 198),
	})
end

local rightSettingsButton = CONFIG.TOGGLE_SETTINGS_ENABLED and rightGroupBox:FindFirstChild("SettingsButton") or nil
if rightSettingsButton then
	rightSettingsButton.Name = "RightToggleSettingsButton"
	rightSettingsButton.MouseEnter:Connect(function()
		F.tween("toggle_settings_hover_" .. rightToggleRow.Name, rightSettingsButton, 0.13, {
			BackgroundTransparency = 0.25,
			ImageColor3 = COLORS.IconHover,
		})
	end)
	rightSettingsButton.MouseLeave:Connect(function()
		F.tween("toggle_settings_hover_" .. rightToggleRow.Name, rightSettingsButton, 0.13, {
			BackgroundTransparency = 1,
			ImageColor3 = COLORS.Icon,
		})
	end)
end

rightToggleRow.Activated:Connect(function()
	F.setRightToggle(not rightToggleEnabled)
end)

local toggleSettingsPopup = F.create("CanvasGroup", ScreenGui, {
	Name = "ToggleSettingsPopup",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(224, CONFIG.spacing * 2 + 3 + 26 + CONFIG.spacing * 2 + 28 + CONFIG.spacing * 2),
	BackgroundColor3 = Color3.fromRGB(21, 21, 25),
	BackgroundTransparency = 0,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ClipsDescendants = false,
	ZIndex = 6000,
})
F.addCorner(toggleSettingsPopup, 6)
F.addStroke(toggleSettingsPopup)

local settingsMenuPaddingX = CONFIG.spacing * 2
local settingsMenuPaddingY = CONFIG.spacing + 3
local settingsMenuLabelWidth = 44
local settingsMenuFieldX = settingsMenuPaddingX + settingsMenuLabelWidth + CONFIG.spacing
local settingsMenuFieldRightPadding = CONFIG.spacing * 2
local settingsMenuFieldWidth = UDim2.new(1, -(settingsMenuFieldX + settingsMenuFieldRightPadding), 0, 26)
local settingsMenuTypeY = settingsMenuPaddingY + 26 + CONFIG.spacing * 2

local keyTitle = F.makeText(toggleSettingsPopup, "Key", UDim2.fromOffset(settingsMenuLabelWidth, 26), UDim2.fromOffset(settingsMenuPaddingX, settingsMenuPaddingY), 12, COLORS.TabIdle, Enum.Font.GothamMedium)
keyTitle.ZIndex = 6002

local keybindButton = F.create("TextButton", toggleSettingsPopup, {
	Name = "KeybindButton",
	Position = UDim2.fromOffset(settingsMenuFieldX, settingsMenuPaddingY),
	Size = settingsMenuFieldWidth,
	BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Text = "Press a key",
	TextColor3 = COLORS.TabIdle,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = false,
	AutoButtonColor = false,
	ZIndex = 6002,
})
F.addCorner(keybindButton, 5)
F.addStroke(keybindButton)
F.create("UIPadding", keybindButton, {
	PaddingLeft = UDim.new(0, 9),
})

local typeTitle = F.makeText(toggleSettingsPopup, "Type", UDim2.fromOffset(settingsMenuLabelWidth, 26), UDim2.fromOffset(settingsMenuPaddingX, settingsMenuTypeY), 12, COLORS.TabIdle, Enum.Font.GothamMedium)
typeTitle.ZIndex = 6002

local typeButton = F.create("TextButton", toggleSettingsPopup, {
	Name = "TypeDropdownButton",
	Position = UDim2.fromOffset(settingsMenuFieldX, settingsMenuTypeY),
	Size = UDim2.new(1, -(settingsMenuFieldX + settingsMenuFieldRightPadding), 0, 28),
	BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 6002,
})
F.addCorner(typeButton, 5)
F.addStroke(typeButton)

local typeButtonText = F.makeText(typeButton, "Toggle", UDim2.new(1, -34, 1, 0), UDim2.fromOffset(9, 0), 13, COLORS.TabIdle, Enum.Font.GothamMedium)
typeButtonText.ZIndex = 6003
typeButtonText.Active = false

local typeChevronLeft = F.create("Frame", typeButton, {
	Name = "ChevronLeft",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -17, 0.5, -1),
	Size = UDim2.fromOffset(6, 1.5),
	Rotation = 42,
	BackgroundColor3 = COLORS.Gray,
	BorderSizePixel = 0,
	ZIndex = 6003,
})
local typeChevronRight = F.create("Frame", typeButton, {
	Name = "ChevronRight",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -13, 0.5, -1),
	Size = UDim2.fromOffset(6, 1.5),
	Rotation = -42,
	BackgroundColor3 = COLORS.Gray,
	BorderSizePixel = 0,
	ZIndex = 6003,
})

local typeOptionsPopup = F.create("CanvasGroup", ScreenGui, {
	Name = "ToggleTypeOptions",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(156, 0),
	BackgroundColor3 = Color3.fromRGB(21, 21, 25),
	BackgroundTransparency = 0,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ClipsDescendants = true,
	ZIndex = 6100,
})
F.addCorner(typeOptionsPopup, 5)
F.addStroke(typeOptionsPopup)

local typeOptionsList = F.create("ScrollingFrame", typeOptionsPopup, {
	Name = "OptionsList",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = COLORS.Icon,
	ScrollBarImageTransparency = 0.35,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ZIndex = 6101,
})

F.create("UIPadding", typeOptionsList, {
	PaddingTop = UDim.new(0, CONFIG.spacing),
	PaddingBottom = UDim.new(0, CONFIG.spacing),
	PaddingLeft = UDim.new(0, CONFIG.spacing),
	PaddingRight = UDim.new(0, CONFIG.spacing),
})

local typeOptionsLayout = F.create("UIListLayout", typeOptionsList, {
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, CONFIG.spacing),
})

typeOptionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	typeOptionsList.CanvasSize = UDim2.fromOffset(0, typeOptionsLayout.AbsoluteContentSize.Y + CONFIG.spacing * 2)
end)

local activeToggleSettings = nil
local settingsPopupRevision = 0
local typeOptionButtons = {}
local typeOptionsOpen = false
local typeOptionsRevision = 0
local typeOptionsAnimHeight = Instance.new("NumberValue")
typeOptionsAnimHeight.Name = "ToggleTypeOptionsAnimHeight"
typeOptionsAnimHeight.Value = 0
local typeOptionsTargetX = 0
local typeOptionsTargetY = 0
local typeOptionsTargetWidth = 0
local typeOptionsTargetHeight = 0

function F.refreshTypeOptionColors()
	for mode, elements in pairs(typeOptionButtons) do
		if elements.label and elements.label.Parent then
			F.tween("toggle_type_option_color_" .. mode, elements.label, 0.12, {
				TextColor3 = mode == (activeToggleSettings and activeToggleSettings.mode or "Toggle") and COLORS.Accent or COLORS.TabIdle,
			})
		end
	end
end

function F.applyTypeOptionsPopupLayout()
	typeOptionsPopup.Position = UDim2.fromOffset(typeOptionsTargetX, typeOptionsTargetY)
	typeOptionsPopup.Size = UDim2.fromOffset(typeOptionsTargetWidth, typeOptionsAnimHeight.Value)
end

typeOptionsAnimHeight.Changed:Connect(F.applyTypeOptionsPopupLayout)

local typeConfigs = {
	Main = {button = settingsButton, mode = "Toggle", keyCode = nil, mouseButton = nil, setValue = F.setHelloToggle},
	Right = {button = rightSettingsButton, mode = "Toggle", keyCode = nil, mouseButton = nil, setValue = F.setRightToggle},
}
local keybindCaptureActive = false

function F.getSettingsViewport()
	local size = ScreenGui.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		local currentCamera = workspace.CurrentCamera
		size = currentCamera and currentCamera.ViewportSize or Vector2.new(1280, 720)
	end
	return size
end

function F.positionSettingsPopup(button)
	local screenOrigin = ScreenGui.AbsolutePosition
	local viewportSize = F.getSettingsViewport()
	local buttonPosition = button.AbsolutePosition
	local buttonSize = button.AbsoluteSize
	local edgeSpacing = CONFIG.spacing * 2
	local preferredRightX = buttonPosition.X - screenOrigin.X + buttonSize.X + CONFIG.spacing
	local x = math.max(edgeSpacing, preferredRightX)
	local availableRightWidth = math.max(1, viewportSize.X - x - edgeSpacing)
	local popupWidth = math.min(224, availableRightWidth)
	toggleSettingsPopup.Size = UDim2.fromOffset(popupWidth, toggleSettingsPopup.Size.Y.Offset)
	keybindButton.Size = UDim2.new(1, -(settingsMenuFieldX + settingsMenuFieldRightPadding), 0, 26)
	typeButton.Size = UDim2.new(1, -(settingsMenuFieldX + settingsMenuFieldRightPadding), 0, 28)
	local popupHeight = toggleSettingsPopup.AbsoluteSize.Y
	local y = buttonPosition.Y - screenOrigin.Y + buttonSize.Y + CONFIG.spacing
	y = math.clamp(y, edgeSpacing, math.max(edgeSpacing, viewportSize.Y - popupHeight - edgeSpacing))
	toggleSettingsPopup.Position = UDim2.fromOffset(x, y)
end

function F.positionTypeOptions()
	local screenOrigin = ScreenGui.AbsolutePosition
	local viewportSize = F.getSettingsViewport()
	local buttonPosition = typeButton.AbsolutePosition
	local buttonSize = typeButton.AbsoluteSize
	local popupWidth = math.min(buttonSize.X, math.max(24, viewportSize.X - 16))
	local popupHeight = typeOptionsLayout.AbsoluteContentSize.Y + CONFIG.spacing * 2
	local x = math.clamp(buttonPosition.X - screenOrigin.X, 8, math.max(8, viewportSize.X - popupWidth - 8))
	local y = buttonPosition.Y + buttonSize.Y + 4 - screenOrigin.Y

	typeOptionsTargetX = x
	typeOptionsTargetY = y
	typeOptionsTargetWidth = popupWidth
	typeOptionsTargetHeight = popupHeight
	F.applyTypeOptionsPopupLayout()
end

function F.setTypeDropdownOpen(open)
	if typeOptionsOpen == open then
		return
	end

	typeOptionsOpen = open
	typeOptionsRevision += 1
	local revision = typeOptionsRevision

	if open then
		F.positionTypeOptions()
		typeOptionsPopup.Visible = true
		typeOptionsPopup.GroupTransparency = 1
		typeOptionsAnimHeight.Value = 0
		F.applyTypeOptionsPopupLayout()
		F.refreshTypeOptionColors()

		F.tween("toggle_settings_type_popup", typeOptionsPopup, 0.12, {
			GroupTransparency = 0,
		})
		F.tween("toggle_settings_type_expand", typeOptionsAnimHeight, 0.18, {
			Value = typeOptionsTargetHeight,
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		F.tween("toggle_settings_type_chevron_left", typeChevronLeft, 0.14, {
			Rotation = -42,
			BackgroundColor3 = COLORS.White,
		})
		F.tween("toggle_settings_type_chevron_right", typeChevronRight, 0.14, {
			Rotation = 42,
			BackgroundColor3 = COLORS.White,
		})
	else
		F.tween("toggle_settings_type_popup", typeOptionsPopup, 0.12, {
			GroupTransparency = 1,
		})
		local closeTween = F.tween("toggle_settings_type_expand", typeOptionsAnimHeight, 0.14, {
			Value = 0,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		closeTween.Completed:Connect(function()
			if typeOptionsRevision == revision and not typeOptionsOpen then
				typeOptionsPopup.Visible = false
			end
		end)
		F.tween("toggle_settings_type_chevron_left", typeChevronLeft, 0.14, {
			Rotation = 42,
			BackgroundColor3 = COLORS.Gray,
		})
		F.tween("toggle_settings_type_chevron_right", typeChevronRight, 0.14, {
			Rotation = -42,
			BackgroundColor3 = COLORS.Gray,
		})
	end
end

typeButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	if typeOptionsOpen then
		F.positionTypeOptions()
	end
end)
typeButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if typeOptionsOpen then
		F.positionTypeOptions()
	end
end)

function F.setToggleSettingsOpen(open, config)
	if open and (not config or not config.button) then
		return
	end
	settingsPopupRevision += 1
	local revision = settingsPopupRevision
	if open then
		activeToggleSettings = config
		keybindButton.Text = config.displayName or "Press a key"
		typeButtonText.Text = config.mode
		F.refreshTypeOptionColors()
		F.positionSettingsPopup(config.button)
		F.setTypeDropdownOpen(false)
		typeChevronLeft.Rotation = 42
		typeChevronRight.Rotation = -42
		typeChevronLeft.BackgroundColor3 = COLORS.Gray
		typeChevronRight.BackgroundColor3 = COLORS.Gray
		toggleSettingsPopup.BackgroundTransparency = 0
		if not toggleSettingsPopup.Visible then
			toggleSettingsPopup.GroupTransparency = 1
		end
		toggleSettingsPopup.Visible = true
		F.tween("toggle_settings_popup_fade", toggleSettingsPopup, 0.14, {
			GroupTransparency = 0,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	else
		activeToggleSettings = nil
		keybindCaptureActive = false
		keybindButton.Text = "Press a key"
		keybindButton.TextColor3 = COLORS.TabIdle
		F.setTypeDropdownOpen(false)
		typeChevronLeft.Rotation = 42
		typeChevronRight.Rotation = -42
		typeChevronLeft.BackgroundColor3 = COLORS.Gray
		typeChevronRight.BackgroundColor3 = COLORS.Gray
		if toggleSettingsPopup.Visible then
			local fadeTween = F.tween("toggle_settings_popup_fade", toggleSettingsPopup, 0.12, {
				GroupTransparency = 1,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			fadeTween.Completed:Connect(function()
				if settingsPopupRevision == revision and not activeToggleSettings then
					toggleSettingsPopup.Visible = false
				end
			end)
		end
	end
end

window:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	if activeToggleSettings and toggleSettingsPopup.Visible then
		F.positionSettingsPopup(activeToggleSettings.button)
		if typeOptionsOpen then
			F.positionTypeOptions()
		end
	end
end)

window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if activeToggleSettings and toggleSettingsPopup.Visible then
		F.positionSettingsPopup(activeToggleSettings.button)
		if typeOptionsOpen then
			F.positionTypeOptions()
		end
	end
end)

for _, settingsButtonToWatch in ipairs({settingsButton, rightSettingsButton}) do
	if settingsButtonToWatch then
		settingsButtonToWatch:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			if activeToggleSettings and activeToggleSettings.button == settingsButtonToWatch and toggleSettingsPopup.Visible then
				F.positionSettingsPopup(settingsButtonToWatch)
			end
		end)
		settingsButtonToWatch:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if activeToggleSettings and activeToggleSettings.button == settingsButtonToWatch and toggleSettingsPopup.Visible then
				F.positionSettingsPopup(settingsButtonToWatch)
			end
		end)
	end
end

function F.keyNameFromCode(keyCode)
	local name = keyCode.Name
	local numpadNames = {
		KeypadZero = "Numpad 0", KeypadOne = "Numpad 1", KeypadTwo = "Numpad 2",
		KeypadThree = "Numpad 3", KeypadFour = "Numpad 4", KeypadFive = "Numpad 5",
		KeypadSix = "Numpad 6", KeypadSeven = "Numpad 7", KeypadEight = "Numpad 8",
		KeypadNine = "Numpad 9", KeypadEnter = "Numpad Enter", KeypadDecimal = "Numpad .",
		KeypadDivide = "Numpad /", KeypadMultiply = "Numpad *", KeypadSubtract = "Numpad -",
		KeypadAdd = "Numpad +",
	}
	return numpadNames[name] or name:gsub("(%l)(%u)", "%1 %2")
end

function F.inputDisplayName(input)
	local mouseNames = {
		[Enum.UserInputType.MouseButton1] = "Mouse 1",
		[Enum.UserInputType.MouseButton2] = "Mouse 2",
		[Enum.UserInputType.MouseButton3] = "Mouse 3",
	}
	if mouseNames[input.UserInputType] then
		return mouseNames[input.UserInputType]
	end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
		return F.keyNameFromCode(input.KeyCode)
	end
	return nil
end

function F.inputMatchesConfig(input, config)
	if config.mouseButton then
		return input.UserInputType == config.mouseButton
	end
	return config.keyCode ~= nil and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == config.keyCode
end

function F.captureToggleInput(input)
	local displayName = F.inputDisplayName(input)
	if not displayName or not activeToggleSettings then
		return false
	end
	local config = activeToggleSettings
	if input.UserInputType == Enum.UserInputType.Keyboard then
		config.keyCode = input.KeyCode
		config.mouseButton = nil
	else
		config.mouseButton = input.UserInputType
		config.keyCode = nil
	end
	config.displayName = displayName
	keybindButton.Text = displayName
	keybindButton.TextColor3 = COLORS.TabIdle
	keybindCaptureActive = false
	return true
end

keybindButton.Activated:Connect(function()
	if not activeToggleSettings then
		return
	end
	keybindCaptureActive = true
	keybindButton.Text = "Press a key"
	keybindButton.TextColor3 = COLORS.TabIdle
end)

keybindButton.MouseEnter:Connect(function()
	F.tween("toggle_settings_keybind_text_hover", keybindButton, 0.12, {
		TextColor3 = COLORS.White,
	})
	F.tween("toggle_settings_keybind_bg_hover", keybindButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(51, 51, 58),
	})
end)

keybindButton.MouseLeave:Connect(function()
	F.tween("toggle_settings_keybind_text_hover", keybindButton, 0.12, {
		TextColor3 = COLORS.TabIdle,
	})
	F.tween("toggle_settings_keybind_bg_hover", keybindButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	})
end)

function F.applySettingsType(config, mode)
	config.mode = mode
	if config == typeConfigs.Main then
		helloSettingsMode = mode
	elseif config == typeConfigs.Right then
		rightSettingsMode = mode
	end
	typeButtonText.Text = mode
	F.refreshTypeOptionColors()
	if mode == "Always on" then
		config.setValue(true)
	elseif mode == "Hold on" then
		config.setValue(false)
	end
end

for index, mode in ipairs(CONFIG.TOGGLE_SETTINGS_TYPES) do
	local option = F.create("TextButton", typeOptionsList, {
		Name = "TypeOption_" .. string.gsub(mode, "%\s+", ""),
		Size = UDim2.new(1, -2, 0, 22),
		BackgroundColor3 = COLORS.SelectBg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		ZIndex = 6102,
	})

	local optionLabel = F.makeText(
		option,
		mode,
		UDim2.new(1, -12, 1, 0),
		UDim2.fromOffset(8, 0),
		13,
		mode == "Toggle" and COLORS.Accent or COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	optionLabel.Name = "OptionLabel"
	optionLabel.ZIndex = 6103
	optionLabel.Active = false

	option.MouseEnter:Connect(function()
		local color = activeToggleSettings and activeToggleSettings.mode == mode and COLORS.Accent or COLORS.White
		F.tween("toggle_type_option_hover_" .. index, optionLabel, 0.13, {
			Position = UDim2.fromOffset(12, 0),
			TextColor3 = color,
		})
		F.tween("toggle_type_option_bg_" .. index, option, 0.13, {
			BackgroundTransparency = 0.35,
		})
	end)

	option.MouseLeave:Connect(function()
		local color = activeToggleSettings and activeToggleSettings.mode == mode and COLORS.Accent or COLORS.TabIdle
		F.tween("toggle_type_option_hover_" .. index, optionLabel, 0.13, {
			Position = UDim2.fromOffset(8, 0),
			TextColor3 = color,
		})
		F.tween("toggle_type_option_bg_" .. index, option, 0.13, {
			BackgroundTransparency = 1,
		})
	end)

	option.Activated:Connect(function()
		if activeToggleSettings then
			F.applySettingsType(activeToggleSettings, mode)
		end
		F.setTypeDropdownOpen(false)
	end)

	typeOptionButtons[mode] = {button = option, label = optionLabel}
end

typeButton.Activated:Connect(function()
	if not activeToggleSettings then
		return
	end
	F.setTypeDropdownOpen(not typeOptionsOpen)
end)

typeButton.MouseEnter:Connect(function()
	F.tween("toggle_settings_type_text", typeButtonText, 0.12, {
		TextColor3 = COLORS.White,
	})
	F.tween("toggle_settings_type_hover", typeButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(51, 51, 58),
	})
end)

typeButton.MouseLeave:Connect(function()
	F.tween("toggle_settings_type_text", typeButtonText, 0.12, {
		TextColor3 = COLORS.TabIdle,
	})
	F.tween("toggle_settings_type_hover", typeButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	})
end)

function F.connectSettingsButton(button, config)
	if not button then
		return
	end
	button.Activated:Connect(function()
		if activeToggleSettings == config then
			F.setToggleSettingsOpen(false)
		else
			F.setToggleSettingsOpen(true, config)
		end
	end)
end

F.connectSettingsButton(settingsButton, typeConfigs.Main)
F.connectSettingsButton(rightSettingsButton, typeConfigs.Right)

SERVICES.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if keybindCaptureActive and F.captureToggleInput(input) then
		return
	end
	if gameProcessed or SERVICES.UserInputService:GetFocusedTextBox() then
		return
	end
	for _, config in pairs(typeConfigs) do
		if F.inputMatchesConfig(input, config) then
			if config.mode == "Toggle" then
				if config == typeConfigs.Main then
					config.setValue(not toggleEnabled)
				elseif config == typeConfigs.Right then
					config.setValue(not rightToggleEnabled)
				end
			elseif config.mode == "Hold on" then
				config.setValue(true)
			elseif config.mode == "Always on" then
				config.setValue(true)
			end
		end
	end
end)

SERVICES.UserInputService.InputEnded:Connect(function(input)
	for _, config in pairs(typeConfigs) do
		if config.mode == "Hold on" and F.inputMatchesConfig(input, config) then
			config.setValue(false)
		end
	end
end)

SERVICES.UserInputService.InputBegan:Connect(function(input)
	if not toggleSettingsPopup.Visible or keybindCaptureActive then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local point = getPointerPosition(input)
	local function contains(guiObject)
		local position = guiObject.AbsolutePosition
		local size = guiObject.AbsoluteSize
		return point.X >= position.X and point.X <= position.X + size.X
			and point.Y >= position.Y and point.Y <= position.Y + size.Y
	end
	if not contains(toggleSettingsPopup) and not contains(typeOptionsPopup)
		and not (settingsButton and contains(settingsButton))
		and not (rightSettingsButton and contains(rightSettingsButton)) then
		F.setToggleSettingsOpen(false)
	end
end)

local sliderMin = math.min(CONFIG.SLIDER_SETTINGS.min, CONFIG.SLIDER_SETTINGS.max)
local sliderMax = math.max(CONFIG.SLIDER_SETTINGS.min, CONFIG.SLIDER_SETTINGS.max)
local sliderRounding = math.clamp(math.floor(CONFIG.SLIDER_SETTINGS.rounding), 1, 3)
local sliderDecimals = sliderRounding - 1
local sliderValue = math.clamp(CONFIG.SLIDER_SETTINGS.default, sliderMin, sliderMax)
local sliderDragging = false

function F.roundSliderValue(value)
	local factor = 10 ^ sliderDecimals
	return math.floor(value * factor + 0.5) / factor
end

function F.formatSliderValue(value)
	return string.format("%." .. sliderDecimals .. "f", value)
end

local componentTitleGap = 2
local componentTitleHeight = 18
local sliderHeaderY = toggleRowY + 30 + CONFIG.spacing
local sliderControlsY = sliderHeaderY + componentTitleHeight + componentTitleGap

local sliderTitle = F.makeText(
	rightGroupBox,
	"this is a slider!",
	UDim2.new(1, -(CONFIG.spacing * 2 + 46 + CONFIG.spacing), 0, componentTitleHeight),
	UDim2.fromOffset(CONFIG.spacing, sliderHeaderY),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
sliderTitle.Name = "SliderTitle"
sliderTitle.ZIndex = 6

local sliderValueLabel = F.makeText(
	rightGroupBox,
	F.formatSliderValue(sliderValue),
	UDim2.fromOffset(46, componentTitleHeight),
	UDim2.new(1, -CONFIG.spacing, 0, sliderHeaderY),
	12,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
sliderValueLabel.Name = "SliderValue"
sliderValueLabel.AnchorPoint = Vector2.new(1, 0)
sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Center
sliderValueLabel.ZIndex = 6

local sliderHitArea = F.create("TextButton", rightGroupBox, {
	Name = "SliderHitArea",
	Position = UDim2.fromOffset(CONFIG.spacing, sliderControlsY - 2),
	Size = UDim2.new(1, -(CONFIG.spacing * 3 + 46), 0, 30),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 9,
})

local sliderTrack = F.create("Frame", rightGroupBox, {
	Name = "SliderTrack",
	Position = UDim2.fromOffset(CONFIG.spacing, sliderControlsY + 11),
	Size = UDim2.new(1, -(CONFIG.spacing * 3 + 46), 0, 4),
	BackgroundColor3 = Color3.fromRGB(55, 55, 62),
	BorderSizePixel = 0,
	ZIndex = 6,
})
F.addCorner(sliderTrack, 3)

local sliderFill = F.create("Frame", sliderTrack, {
	Name = "SliderFill",
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = COLORS.Accent,
	BorderSizePixel = 0,
	ZIndex = 7,
})
F.addCorner(sliderFill, 3)

local sliderKnob = F.create("Frame", sliderTrack, {
	Name = "SliderKnob",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	Size = UDim2.fromOffset(12, 12),
	BackgroundColor3 = COLORS.White,
	BorderSizePixel = 0,
	ZIndex = 8,
})
F.addCorner(sliderKnob, 6)

local sliderInput = F.create("TextBox", rightGroupBox, {
	Name = "SliderInput",
	Position = UDim2.new(1, -(CONFIG.spacing + 46), 0, sliderControlsY),
	Size = UDim2.fromOffset(46, 26),
	BackgroundColor3 = Color3.fromRGB(39, 39, 45),
	BorderSizePixel = 0,
	Text = F.formatSliderValue(sliderValue),
	PlaceholderText = "0",
	PlaceholderColor3 = COLORS.Muted,
	TextColor3 = COLORS.Title,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 7,
})
F.addCorner(sliderInput, 5)
F.addStroke(sliderInput)

local sliderTrackStroke = F.create("UIStroke", sliderTrack, {
	Color = COLORS.Accent,
	Thickness = 1,
	Transparency = 1,
})

local sliderHovered = false

function F.setSliderHover(hovered)
	sliderHovered = hovered

	F.tween("slider_track_hover", sliderTrack, 0.14, {
		BackgroundColor3 = hovered
			and Color3.fromRGB(72, 72, 82)
			or Color3.fromRGB(55, 55, 62),
	})

	F.tween("slider_track_outline", sliderTrackStroke, 0.14, {
		Transparency = hovered and 0.45 or 1,
	})

	F.tween("slider_knob_hover", sliderKnob, 0.14, {
		Size = hovered and UDim2.fromOffset(14, 14) or UDim2.fromOffset(12, 12),
		BackgroundColor3 = hovered and Color3.fromRGB(255, 255, 255) or COLORS.White,
	})

	F.tween("slider_fill_hover", sliderFill, 0.14, {
		BackgroundColor3 = hovered
			and Color3.fromRGB(105, 195, 255)
			or COLORS.Accent,
	})
end

sliderInput.MouseEnter:Connect(function()
	F.tween("slider_input_hover", sliderInput, 0.13, {
		BackgroundColor3 = Color3.fromRGB(48, 48, 56),
	})
end)

sliderInput.MouseLeave:Connect(function()
	F.tween("slider_input_hover", sliderInput, 0.13, {
		BackgroundColor3 = Color3.fromRGB(39, 39, 45),
	})
end)

function F.setSliderValue(value, updateInput)
	value = math.clamp(F.roundSliderValue(value), sliderMin, sliderMax)
	sliderValue = value

	local range = sliderMax - sliderMin
	local alpha = range == 0 and 0 or (value - sliderMin) / range

	F.tween("slider_fill", sliderFill, 0.13, {
		Size = UDim2.new(alpha, 0, 1, 0),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	F.tween("slider_knob", sliderKnob, 0.13, {
		Position = UDim2.new(alpha, 0, 0.5, 0),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	sliderValueLabel.Text = F.formatSliderValue(value)

	if updateInput then
		sliderInput.Text = F.formatSliderValue(value)
	end
end

function F.setSliderFromPointer(screenX)
	local trackPosition = sliderTrack.AbsolutePosition.X
	local trackWidth = sliderTrack.AbsoluteSize.X
	local alpha = math.clamp((screenX - trackPosition) / math.max(trackWidth, 1), 0, 1)
	F.setSliderValue(sliderMin + (sliderMax - sliderMin) * alpha, true)
end

function F.beginSliderDrag(input)
	local inputType = input.UserInputType
	if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
		return
	end

	sliderDragging = true
	F.setSliderHover(true)

	F.setSliderFromPointer(getPointerPosition(input).X)
end

sliderHitArea.MouseEnter:Connect(function()
	F.setSliderHover(true)
end)

sliderHitArea.MouseLeave:Connect(function()
	if not sliderDragging then
		F.setSliderHover(false)
	end
end)

SERVICES.UserInputService.InputChanged:Connect(function(input)
	if not sliderDragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		F.setSliderFromPointer(getPointerPosition(input).X)
	end
end)

SERVICES.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = false
		local point = getPointerPosition(input)
		local pos = sliderHitArea.AbsolutePosition
		local size = sliderHitArea.AbsoluteSize
		local stillOver = point.X >= pos.X and point.X <= pos.X + size.X
			and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
		F.setSliderHover(stillOver)
	end
end)

sliderInput.FocusLost:Connect(function()
	local typedValue = tonumber(sliderInput.Text)
	if typedValue then
		F.setSliderValue(typedValue, true)
	else
		sliderInput.Text = F.formatSliderValue(sliderValue)
	end
end)

F.setSliderValue(sliderValue, true)

local dropdownSelected = CONFIG.DEFAULT_DROPDOWN_OPTION
local dropdownOpen = false
local dropdownRevision = 0
local dropdownHovered = false

local dropdownHeaderY = toggleRowY + 30 + CONFIG.spacing

local dropdownTitle = F.makeText(
	helloGroupBox,
	"this is a dropdown",
	UDim2.new(1, -(CONFIG.spacing * 2), 0, componentTitleHeight),
	UDim2.fromOffset(CONFIG.spacing, dropdownHeaderY),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
dropdownTitle.ZIndex = 6

local dropdownButton = F.create("TextButton", helloGroupBox, {
	Name = "DropdownButton",
	Position = UDim2.fromOffset(CONFIG.spacing, dropdownHeaderY + componentTitleHeight + componentTitleGap),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 28),
	BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 7,
})
F.addCorner(dropdownButton, 5)

local dropdownButtonText = F.makeText(
	dropdownButton,
	dropdownSelected,
	UDim2.new(1, -34, 1, 0),
	UDim2.fromOffset(9, 0),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
dropdownButtonText.ZIndex = 8

dropdownButtonText.Active = false

local dropdownChevronLeft = F.create("Frame", dropdownButton, {
	Name = "ChevronLeft",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -17, 0.5, -1),
	Size = UDim2.fromOffset(6, 1.5),
	Rotation = 42,
	BackgroundColor3 = COLORS.Gray,
	BorderSizePixel = 0,
	ZIndex = 8,
})

local dropdownChevronRight = F.create("Frame", dropdownButton, {
	Name = "ChevronRight",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -13, 0.5, -1),
	Size = UDim2.fromOffset(6, 1.5),
	Rotation = -42,
	BackgroundColor3 = COLORS.Gray,
	BorderSizePixel = 0,
	ZIndex = 8,
})

local dropdownPopup = F.create("CanvasGroup", ScreenGui, {
	Name = "DropdownOptions",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(100, 150),
	BackgroundColor3 = Color3.fromRGB(21, 21, 25),
	BackgroundTransparency = 0,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Visible = false,
	ZIndex = 5000,
})
F.addCorner(dropdownPopup, 5)
F.addStroke(dropdownPopup)

local dropdownList = F.create("ScrollingFrame", dropdownPopup, {
	Name = "OptionsList",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = COLORS.Icon,
	ScrollBarImageTransparency = 0.35,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ZIndex = 5001,
})

F.create("UIPadding", dropdownList, {
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 4),
})

local dropdownLayout = F.create("UIListLayout", dropdownList, {
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 2),
})

dropdownLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	dropdownList.CanvasSize = UDim2.fromOffset(
		0,
		dropdownLayout.AbsoluteContentSize.Y + 8
	)
end)

local dropdownOptionButtons = {}

function F.refreshDropdownOptionColors()
	for optionName, optionButton in pairs(dropdownOptionButtons) do
		local optionLabel = optionButton:FindFirstChild("OptionLabel")
		if optionLabel then
			local color = optionName == dropdownSelected and COLORS.Accent or COLORS.TabIdle
			F.tween("dropdown_option_color_" .. optionName, optionLabel, 0.12, {
				TextColor3 = color,
			})
		end
	end
end

local dropdownAnimHeight = Instance.new("NumberValue")
dropdownAnimHeight.Name = "DropdownAnimHeight"
dropdownAnimHeight.Value = 0

local dropdownTargetX = 0
local dropdownTargetY = 0
local dropdownTargetWidth = 0
local dropdownTargetHeight = 0

function F.applyDropdownPopupLayout()
	dropdownPopup.Position = UDim2.fromOffset(dropdownTargetX, dropdownTargetY)
	dropdownPopup.Size = UDim2.fromOffset(dropdownTargetWidth, dropdownAnimHeight.Value)
end

dropdownAnimHeight.Changed:Connect(F.applyDropdownPopupLayout)

function F.updateDropdownPopupGeometry()
	local buttonPosition = dropdownButton.AbsolutePosition
	local buttonSize = dropdownButton.AbsoluteSize
	local overlaySize = ScreenGui.AbsoluteSize
	if overlaySize.X <= 0 or overlaySize.Y <= 0 then
		local currentCamera = workspace.CurrentCamera
		overlaySize = currentCamera and currentCamera.ViewportSize or Vector2.new(1280, 720)
	end

	-- Translate from screen space (AbsolutePosition) into the ScreenGui's own
	-- coordinate space, since IgnoreGuiInset makes the two origins differ.
	local guiOrigin = ScreenGui.AbsolutePosition

	local popupWidth = math.min(buttonSize.X, math.max(24, overlaySize.X - 16))
	local popupHeight = dropdownLayout.AbsoluteContentSize.Y + 8
	local popupX = math.clamp(buttonPosition.X - guiOrigin.X, 8, math.max(8, overlaySize.X - popupWidth - 8))
	local popupY = buttonPosition.Y + buttonSize.Y + 4 - guiOrigin.Y

	dropdownTargetX = popupX
	dropdownTargetY = popupY
	dropdownTargetWidth = popupWidth
	dropdownTargetHeight = popupHeight
	F.applyDropdownPopupLayout()
end

function F.setDropdownOpen(open)
	if dropdownOpen == open then
		return
	end

	dropdownOpen = open
	dropdownRevision += 1
	local revision = dropdownRevision

	if open then
		F.updateDropdownPopupGeometry()
		dropdownPopup.Visible = true
		dropdownPopup.GroupTransparency = 1
		F.refreshDropdownOptionColors()

		-- Start at zero height directly below the button, then grow downward.
		dropdownAnimHeight.Value = 0
		F.applyDropdownPopupLayout()

		F.tween("dropdown_chevron_left", dropdownChevronLeft, 0.14, {
			Rotation = -42,
			BackgroundColor3 = COLORS.White,
		})
		F.tween("dropdown_chevron_right", dropdownChevronRight, 0.14, {
			Rotation = 42,
			BackgroundColor3 = COLORS.White,
		})
		F.tween("dropdown_popup", dropdownPopup, 0.12, {
			GroupTransparency = 0,
		})
		F.tween("dropdown_expand", dropdownAnimHeight, 0.18, {
			Value = dropdownTargetHeight,
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	else
		F.tween("dropdown_chevron_left", dropdownChevronLeft, 0.14, {
			Rotation = 42,
			BackgroundColor3 = COLORS.Gray,
		})
		F.tween("dropdown_chevron_right", dropdownChevronRight, 0.14, {
			Rotation = -42,
			BackgroundColor3 = COLORS.Gray,
		})

		-- Collapse the height back to zero while fading out.
		F.tween("dropdown_popup", dropdownPopup, 0.12, {
			GroupTransparency = 1,
		})
		local closeCollapse = F.tween("dropdown_expand", dropdownAnimHeight, 0.14, {
			Value = 0,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		closeCollapse.Completed:Connect(function()
			if dropdownRevision == revision and not dropdownOpen then
				dropdownPopup.Visible = false
			end
		end)
	end
end

for index, optionName in ipairs(CONFIG.DROPDOWN_OPTIONS) do
	local optionButton = F.create("TextButton", dropdownList, {
		Name = "Option_" .. optionName,
		Size = UDim2.new(1, -2, 0, 22),
		BackgroundColor3 = COLORS.SelectBg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		ZIndex = 5002,
	})

	local optionLabel = F.makeText(
		optionButton,
		optionName,
		UDim2.new(1, -12, 1, 0),
		UDim2.fromOffset(8, 0),
		13,
		optionName == dropdownSelected and COLORS.Accent or COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	optionLabel.Name = "OptionLabel"
	optionLabel.ZIndex = 5003
	optionLabel.Active = false

	optionButton.MouseEnter:Connect(function()
		local color = optionName == dropdownSelected and COLORS.Accent or COLORS.White
		F.tween("dropdown_option_hover_" .. optionName, optionLabel, 0.13, {
			Position = UDim2.fromOffset(12, 0),
			TextColor3 = color,
		})
		F.tween("dropdown_option_bg_" .. optionName, optionButton, 0.13, {
			BackgroundTransparency = 0.35,
		})
	end)

	optionButton.MouseLeave:Connect(function()
		local color = optionName == dropdownSelected and COLORS.Accent or COLORS.TabIdle
		F.tween("dropdown_option_hover_" .. optionName, optionLabel, 0.13, {
			Position = UDim2.fromOffset(8, 0),
			TextColor3 = color,
		})
		F.tween("dropdown_option_bg_" .. optionName, optionButton, 0.13, {
			BackgroundTransparency = 1,
		})
	end)

	optionButton.Activated:Connect(function()
		dropdownSelected = optionName
		dropdownButtonText.Text = optionName
		F.refreshDropdownOptionColors()
		F.setDropdownOpen(false)
	end)

	dropdownOptionButtons[optionName] = optionButton
end

if not table.find(CONFIG.DROPDOWN_OPTIONS, CONFIG.DEFAULT_DROPDOWN_OPTION) then
	dropdownSelected = CONFIG.DROPDOWN_OPTIONS[1]
	dropdownButtonText.Text = dropdownSelected
end

dropdownButton.MouseEnter:Connect(function()
	dropdownHovered = true
	F.tween("dropdown_button_text", dropdownButtonText, 0.12, {
		TextColor3 = COLORS.White,
	})
	F.tween("dropdown_button_bg", dropdownButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(51, 51, 58),
	})
end)

dropdownButton.MouseLeave:Connect(function()
	dropdownHovered = false
	F.tween("dropdown_button_text", dropdownButtonText, 0.12, {
		TextColor3 = COLORS.TabIdle,
	})
	F.tween("dropdown_button_bg", dropdownButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	})
end)

dropdownButton.Activated:Connect(function()
	F.setDropdownOpen(not dropdownOpen)
end)

window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if dropdownOpen then
		F.updateDropdownPopupGeometry()
	end
end)

dropdownButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	if dropdownOpen then
		F.updateDropdownPopupGeometry()
	end
end)

dropdownButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if dropdownOpen then
		F.updateDropdownPopupGeometry()
	end
end)

local MAX_COLORPICKERS_PER_TOGGLE = 3
local colorPickersByToggle = {}
local activeColorPicker = nil
local colorPopupOpen = false
local colorDragControl = nil
local colorDragInputType = nil
local colorDragTouchInput = nil
local colorFormat = "HEX"

local secondGroupBox = F.create("Frame", content, {
	Name = "SecondHelloGroupBox",
	Position = UDim2.fromOffset(CONFIG.spacing, 16),
	Size = UDim2.new(0.5, -(CONFIG.spacing * 1.5), 0, 80),
	BackgroundColor3 = Color3.fromRGB(16, 16, 19),
	BorderSizePixel = 0,
	ClipsDescendants = false,
	ZIndex = 3,
})
F.addCorner(secondGroupBox, 7)
F.addStroke(secondGroupBox)

local secondGroupShadow = Instance.new("UIShadow")
secondGroupShadow.Name = "GroupBoxShadow"
secondGroupShadow.Color = Color3.fromRGB(0, 0, 0)
secondGroupShadow.Transparency = 0.56
secondGroupShadow.BlurRadius = UDim.new(0, 14)
secondGroupShadow.Offset = UDim2.fromOffset(0, 4)
secondGroupShadow.Spread = UDim2.fromOffset(0, 1)
secondGroupShadow.ShowBehindParent = true
secondGroupShadow.Parent = secondGroupBox

local secondGroupTitle = F.makeText(
	secondGroupBox,
	"this is another groupbox",
	UDim2.new(1, -(CONFIG.spacing * 2), 0, 18),
	UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing),
	12,
	COLORS.Muted,
	Enum.Font.GothamBold
)
secondGroupTitle.ZIndex = 4

local secondGroupDividerY = CONFIG.spacing + 18 + CONFIG.spacing
local secondGroupDivider = headerDivider:Clone()
secondGroupDivider.Name = "HeaderDivider"
secondGroupDivider.Position = UDim2.fromOffset(CONFIG.spacing, secondGroupDividerY)
secondGroupDivider.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 1)
secondGroupDivider.Parent = secondGroupBox

local secondToggleRowY = secondGroupDividerY + 1 + CONFIG.spacing
local colorToggleRow = F.create("TextButton", secondGroupBox, {
	Name = "ColorToggleRow",
	Position = UDim2.fromOffset(CONFIG.spacing, secondToggleRowY),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 40),
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 5,
})
F.addCorner(colorToggleRow, 5)

local colorToggleLabel = F.makeText(
	colorToggleRow,
	"this has a color box",
	UDim2.new(1, -60, 1, 0),
	UDim2.fromOffset(0, 0),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
colorToggleLabel.Name = "ToggleLabel"
colorToggleLabel.ZIndex = 6
colorToggleLabel.Active = false

local colorToggleTrack = F.create("Frame", colorToggleRow, {
	Name = "ToggleTrack",
	Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10),
	Size = UDim2.fromOffset(36, 20),
	BackgroundColor3 = Color3.fromRGB(57, 57, 64),
	BorderSizePixel = 0,
	ZIndex = 6,
})
F.addCorner(colorToggleTrack, 10)

local colorToggleKnob = F.create("Frame", colorToggleTrack, {
	Name = "ToggleKnob",
	Position = UDim2.fromOffset(3, 3),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = Color3.fromRGB(190, 190, 198),
	BorderSizePixel = 0,
	ZIndex = 7,
})
F.addCorner(colorToggleKnob, 7)

local colorToggleEnabled = false

function F.setColorToggle(enabled)
	colorToggleEnabled = enabled

	F.tween("color_toggle_track", colorToggleTrack, 0.18, {
		BackgroundColor3 = enabled and COLORS.Accent or Color3.fromRGB(57, 57, 64),
	})

	F.tween("color_toggle_knob", colorToggleKnob, 0.18, {
		Position = enabled and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3),
		BackgroundColor3 = enabled and Color3.fromRGB(245, 249, 255) or Color3.fromRGB(190, 190, 198),
	})
end

colorToggleRow.MouseEnter:Connect(function()
	F.setToggleHover(true, colorToggleRow, colorToggleLabel)
end)

colorToggleRow.MouseLeave:Connect(function()
	F.setToggleHover(false, colorToggleRow, colorToggleLabel)
end)

colorToggleRow.Activated:Connect(function()
	F.setColorToggle(not colorToggleEnabled)
end)

-- "conditional group" toggle: reveals a nested "no longer hidden!" toggle
-- that slides and fades in beneath it when enabled.
secondGroupBox.ClipsDescendants = true

local conditionalRowY = secondToggleRowY + 30 + 2

local conditionalRow = F.create("TextButton", secondGroupBox, {
	Name = "ConditionalToggleRow",
	Position = UDim2.fromOffset(CONFIG.spacing, conditionalRowY),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 40),
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 5,
})
F.addCorner(conditionalRow, 5)

local conditionalLabel = F.makeText(
	conditionalRow,
	"conditional group",
	UDim2.new(1, -66, 1, 0),
	UDim2.fromOffset(0, 0),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
conditionalLabel.Name = "ToggleLabel"
conditionalLabel.ZIndex = 6
conditionalLabel.Active = false

local conditionalTrack = F.create("Frame", conditionalRow, {
	Name = "ToggleTrack",
	Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10),
	Size = UDim2.fromOffset(36, 20),
	BackgroundColor3 = Color3.fromRGB(57, 57, 64),
	BorderSizePixel = 0,
	ZIndex = 6,
})
F.addCorner(conditionalTrack, 10)

local conditionalKnob = F.create("Frame", conditionalTrack, {
	Name = "ToggleKnob",
	Position = UDim2.fromOffset(3, 3),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = Color3.fromRGB(190, 190, 198),
	BorderSizePixel = 0,
	ZIndex = 7,
})
F.addCorner(conditionalKnob, 7)

local hiddenRowY = conditionalRowY + 30 + 2

-- Generic conditional-row system: any content type (a toggle, a slider,
-- or a dropdown) can be wrapped in a CanvasGroup that slides/fades in
-- when its controlling row is enabled; the group box resizes to fit.
local conditionalRows = {}

function F.secondGroupTargetHeight()
	-- Collapsed height stops below the conditional row; each visible
	-- conditional row extends the box to its own bottom edge.
	local bottom = conditionalRowY + 30
	for _, entry in ipairs(conditionalRows) do
		if entry.visible then
			bottom = math.max(bottom, entry.y + entry.height)
		end
	end
	return bottom + CONFIG.spacing
end

function F.refreshSecondGroupSize()
	F.tween("second_group_size", secondGroupBox, 0.24, {
		Size = UDim2.fromOffset(secondGroupBox.AbsoluteSize.X, F.secondGroupTargetHeight()),
	}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

function F.setConditionalRowShown(entry, shown)
	if entry.visible == shown then
		return
	end

	entry.visible = shown
	entry.revision += 1
	local revision = entry.revision

	-- The group box grows/shrinks in sync with the nested row sliding in/out.
	F.refreshSecondGroupSize()

	if shown then
		entry.row.Visible = true
		entry.row.Position = UDim2.fromOffset(CONFIG.spacing, entry.y - entry.height - 2)
		F.tween("conditional_row_" .. entry.id, entry.row, 0.24, {
			Position = UDim2.fromOffset(CONFIG.spacing, entry.y),
			GroupTransparency = 0,
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	else
		-- Fade the row out in place while the group box shrinks around it,
		-- so nothing slides up over the row above; clipping hides it.
		local hideTween = F.tween("conditional_row_" .. entry.id, entry.row, 0.18, {
			GroupTransparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		hideTween.Completed:Connect(function()
			if entry.revision == revision and not entry.visible then
				entry.row.Visible = false
			end
		end)
	end
end

-- Builds a conditionally-revealed row. `buildContent` receives the row's
-- CanvasGroup and can parent any control into it -- a toggle, a slider
-- (title + track + input), or a dropdown (title + button) -- laid out to
-- fill the given `height`.
function F.createConditionalRow(id, y, height, buildContent)
	local row = F.create("CanvasGroup", secondGroupBox, {
		Name = id,
		Position = UDim2.fromOffset(CONFIG.spacing, y),
		Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, height),
		BackgroundColor3 = COLORS.SelectBg,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
	})
	F.addCorner(row, 5)

	buildContent(row)

	local entry = { id = id, row = row, y = y, height = height, visible = false, revision = 0 }
	table.insert(conditionalRows, entry)
	return entry, row
end

local hiddenHitArea
local hiddenLabel
local hiddenTrack
local hiddenKnob

local hiddenEntry, hiddenRow = F.createConditionalRow("HiddenToggleRow", hiddenRowY, 30, function(row)
	hiddenHitArea = F.create("TextButton", row, {
		Name = "HitArea",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 6,
	})

	hiddenLabel = F.makeText(
		row,
		"no longer hidden!",
		UDim2.new(1, -66, 1, 0),
		UDim2.fromOffset(0, 0),
		13,
		COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	hiddenLabel.Name = "ToggleLabel"
	hiddenLabel.ZIndex = 6
	hiddenLabel.Active = false

	hiddenTrack = F.create("Frame", row, {
		Name = "ToggleTrack",
		Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10),
		Size = UDim2.fromOffset(36, 20),
		BackgroundColor3 = Color3.fromRGB(57, 57, 64),
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	F.addCorner(hiddenTrack, 10)

	hiddenKnob = F.create("Frame", hiddenTrack, {
		Name = "ToggleKnob",
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.fromRGB(190, 190, 198),
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	F.addCorner(hiddenKnob, 7)
end)

local conditionalEnabled = false
local hiddenEnabled = false

function F.setConditionalToggle(enabled)
	conditionalEnabled = enabled

	F.tween("conditional_toggle_track", conditionalTrack, 0.18, {
		BackgroundColor3 = enabled and COLORS.Accent or Color3.fromRGB(57, 57, 64),
	})

	F.tween("conditional_toggle_knob", conditionalKnob, 0.18, {
		Position = enabled and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3),
		BackgroundColor3 = enabled and Color3.fromRGB(245, 249, 255) or Color3.fromRGB(190, 190, 198),
	})

	F.setConditionalRowShown(hiddenEntry, enabled)
end

conditionalRow.MouseEnter:Connect(function()
	F.setToggleHover(true, conditionalRow, conditionalLabel)
end)

conditionalRow.MouseLeave:Connect(function()
	F.setToggleHover(false, conditionalRow, conditionalLabel)
end)

conditionalRow.Activated:Connect(function()
	F.setConditionalToggle(not conditionalEnabled)
end)

hiddenHitArea.MouseEnter:Connect(function()
	F.setToggleHover(true, hiddenRow, hiddenLabel)
end)

hiddenHitArea.MouseLeave:Connect(function()
	F.setToggleHover(false, hiddenRow, hiddenLabel)
end)

hiddenHitArea.Activated:Connect(function()
	hiddenEnabled = not hiddenEnabled

	F.tween("hidden_toggle_track", hiddenTrack, 0.18, {
		BackgroundColor3 = hiddenEnabled and COLORS.Accent or Color3.fromRGB(57, 57, 64),
	})

	F.tween("hidden_toggle_knob", hiddenKnob, 0.18, {
		Position = hiddenEnabled and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3),
		BackgroundColor3 = hiddenEnabled and Color3.fromRGB(245, 249, 255) or Color3.fromRGB(190, 190, 198),
	})
end)

local colorPopup = F.create("CanvasGroup", Root, {
	Name = "ColorPickerPopup",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(180, 244),
	BackgroundColor3 = Color3.fromRGB(20, 20, 24),
	BackgroundTransparency = 0,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = false,
	Visible = false,
	ZIndex = 80,
})
F.addCorner(colorPopup, 7)
F.addStroke(colorPopup)

local saturationArea = F.create("Frame", colorPopup, {
	Name = "SaturationArea",
	Position = UDim2.fromOffset(9, 9),
	Size = UDim2.fromOffset(162, 162),
	BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	BorderSizePixel = 0,
	ZIndex = 81,
})
F.addCorner(saturationArea, 4)

local saturationWhite = F.create("Frame", saturationArea, {
	Name = "SaturationWhite",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 82,
})
F.addCorner(saturationWhite, 4)
F.create("UIGradient", saturationWhite, {
	Rotation = 0,
	Color = ColorSequence.new(Color3.new(1, 1, 1)),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
})

local saturationBlack = F.create("Frame", saturationArea, {
	Name = "SaturationBlack",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
	ZIndex = 83,
})
F.addCorner(saturationBlack, 4)
F.create("UIGradient", saturationBlack, {
	Rotation = 90,
	Color = ColorSequence.new(Color3.new(0, 0, 0)),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	}),
})

local saturationHitArea = F.create("TextButton", saturationArea, {
	Name = "SaturationHitArea",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 85,
})

local saturationMarker = F.create("Frame", saturationArea, {
	Name = "SaturationMarker",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(4, 4),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 86,
})
F.addCorner(saturationMarker, 100)
F.create("UIStroke", saturationMarker, {
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 5,
	Transparency = 0,
})

local hueTrack = F.create("Frame", colorPopup, {
	Name = "HueTrack",
	Position = UDim2.fromOffset(9, 179),
	Size = UDim2.fromOffset(162, 9),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 81,
})
F.addCorner(hueTrack, 4)
F.create("UIGradient", hueTrack, {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	}),
})

local hueHitArea = F.create("TextButton", hueTrack, {
	Name = "HueHitArea",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 83,
})

local hueMarker = F.create("Frame", hueTrack, {
	Name = "HueMarker",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.fromOffset(4, 4),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 84,
})
F.addCorner(hueMarker, 100)
F.create("UIStroke", hueMarker, {
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 5,
	Transparency = 0,
})

local transparencyTrack = F.create("Frame", colorPopup, {
	Name = "TransparencyTrack",
	Position = UDim2.fromOffset(9, 194),
	Size = UDim2.fromOffset(162, 9),
	BackgroundColor3 = Color3.fromRGB(39, 39, 45),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ClipsDescendants = false,
	ZIndex = 81,
})
F.addCorner(transparencyTrack, 4)

local transparencyOverlay = F.create("Frame", transparencyTrack, {
	Name = "TransparencyColorOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 82,
})
F.addCorner(transparencyOverlay, 4)

local transparencyGradient = F.create("UIGradient", transparencyOverlay, {
	Color = ColorSequence.new(Color3.fromRGB(255, 40, 40)),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
})

local transparencyHitArea = F.create("TextButton", transparencyTrack, {
	Name = "TransparencyHitArea",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 83,
})

local transparencyMarker = F.create("Frame", transparencyTrack, {
	Name = "TransparencyMarker",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.fromOffset(4, 4),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 84,
})
F.addCorner(transparencyMarker, 100)
F.create("UIStroke", transparencyMarker, {
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 5,
	Transparency = 0,
})

local formatButton = F.create("TextButton", colorPopup, {
	Name = "ColorFormatButton",
	Position = UDim2.fromOffset(9, 211),
	Size = UDim2.fromOffset(58, 24),
	BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 82,
})
F.addCorner(formatButton, 5)

local formatButtonText = F.makeText(
	formatButton,
	"HEX",
	UDim2.new(1, -25, 1, 0),
	UDim2.fromOffset(9, 0),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
formatButtonText.ZIndex = 83
formatButtonText.Active = false

local formatChevronLeft = F.create("Frame", formatButton, {
	Name = "ChevronLeft",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -16, 0.5, -1),
	Size = UDim2.fromOffset(6, 1.5),
	Rotation = 42,
	BackgroundColor3 = COLORS.Gray,
	BorderSizePixel = 0,
	ZIndex = 83,
})

local formatChevronRight = F.create("Frame", formatButton, {
	Name = "ChevronRight",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -12, 0.5, -1),
	Size = UDim2.fromOffset(6, 1.5),
	Rotation = -42,
	BackgroundColor3 = COLORS.Gray,
	BorderSizePixel = 0,
	ZIndex = 83,
})

local colorValueInput = F.create("TextBox", colorPopup, {
	Name = "ColorValueInput",
	Position = UDim2.fromOffset(72, 213),
	Size = UDim2.fromOffset(99, 20),
	BackgroundColor3 = Color3.fromRGB(39, 39, 45),
	BorderSizePixel = 0,
	Text = "#FF2828",
	PlaceholderText = "#RRGGBB",
	PlaceholderColor3 = COLORS.Muted,
	TextColor3 = COLORS.Title,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 82,
})
F.addCorner(colorValueInput, 4)

local formatMenu = F.create("CanvasGroup", Root, {
	Name = "ColorFormatMenu",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(64, 56),
	BackgroundColor3 = Color3.fromRGB(21, 21, 25),
	BorderSizePixel = 0,
	GroupTransparency = 1,
	Visible = false,
	ZIndex = 1000,
})
F.addCorner(formatMenu, 5)
F.addStroke(formatMenu)

local formatMenuRevision = 0
local formatMenuOpen = false

function F.setFormatMenuOpen(open)
	if formatMenuOpen == open then
		return
	end
	formatMenuOpen = open
	formatMenuRevision += 1
	local revision = formatMenuRevision
	if open then
		formatMenu.GroupTransparency = 1
		formatMenu.Visible = true
		F.tween("format_menu_fade", formatMenu, 0.12, {
			GroupTransparency = 0,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	else
		local fadeTween = F.tween("format_menu_fade", formatMenu, 0.12, {
			GroupTransparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		fadeTween.Completed:Connect(function()
			if formatMenuRevision == revision and not formatMenuOpen then
				formatMenu.Visible = false
			end
		end)
	end
end

local hexOption = F.create("TextButton", formatMenu, {
	Name = "HexOption",
	Position = UDim2.fromOffset(4, 4),
	Size = UDim2.new(1, -8, 0, 22),
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 1001,
})
local hexOptionText = F.makeText(
	hexOption,
	"HEX",
	UDim2.new(1, -10, 1, 0),
	UDim2.fromOffset(8, 0),
	13,
	COLORS.Accent,
	Enum.Font.GothamMedium
)
hexOptionText.ZIndex = 1002
hexOptionText.Active = false

local rgbOption = F.create("TextButton", formatMenu, {
	Name = "RgbOption",
	Position = UDim2.fromOffset(4, 28),
	Size = UDim2.new(1, -8, 0, 22),
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 1001,
})
local rgbOptionText = F.makeText(
	rgbOption,
	"RGB",
	UDim2.new(1, -10, 1, 0),
	UDim2.fromOffset(8, 0),
	13,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
rgbOptionText.ZIndex = 1002
rgbOptionText.Active = false

function F.setFormatOptionHover(button, label, key)
	button.MouseEnter:Connect(function()
		F.tween(key .. "_text", label, 0.13, {
			Position = UDim2.fromOffset(12, 0),
			TextColor3 = label.Text == colorFormat and COLORS.Accent or COLORS.White,
		})
		F.tween(key .. "_bg", button, 0.13, {
			BackgroundTransparency = 0.35,
		})
	end)

	button.MouseLeave:Connect(function()
		F.tween(key .. "_text", label, 0.13, {
			Position = UDim2.fromOffset(8, 0),
			TextColor3 = label.Text == colorFormat and COLORS.Accent or COLORS.TabIdle,
		})
		F.tween(key .. "_bg", button, 0.13, {
			BackgroundTransparency = 1,
		})
	end)
end

F.setFormatOptionHover(hexOption, hexOptionText, "format_hex_option")
F.setFormatOptionHover(rgbOption, rgbOptionText, "format_rgb_option")

formatButton.MouseEnter:Connect(function()
	F.tween("format_button_text", formatButtonText, 0.12, {
		TextColor3 = COLORS.White,
	})
	F.tween("format_button_bg", formatButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(51, 51, 58),
	})
	F.tween("format_chevron_left", formatChevronLeft, 0.12, {
		BackgroundColor3 = COLORS.White,
	})
	F.tween("format_chevron_right", formatChevronRight, 0.12, {
		BackgroundColor3 = COLORS.White,
	})
end)

formatButton.MouseLeave:Connect(function()
	F.tween("format_button_text", formatButtonText, 0.12, {
		TextColor3 = COLORS.TabIdle,
	})
	F.tween("format_button_bg", formatButton, 0.12, {
		BackgroundColor3 = Color3.fromRGB(43, 43, 49),
	})
	F.tween("format_chevron_left", formatChevronLeft, 0.12, {
		BackgroundColor3 = COLORS.Gray,
	})
	F.tween("format_chevron_right", formatChevronRight, 0.12, {
		BackgroundColor3 = COLORS.Gray,
	})
end)

function F.colorToText(color)
	if colorFormat == "HEX" then
		return string.format(
			"#%02X%02X%02X",
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5)
		)
	end

	return string.format(
		"%d, %d, %d",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

function F.parseColorText(text)
	if colorFormat == "HEX" then
		local hex = string.gsub(text, "#", "")
		if #hex ~= 6 then
			return nil
		end
		local r = tonumber(string.sub(hex, 1, 2), 16)
		local g = tonumber(string.sub(hex, 3, 4), 16)
		local b = tonumber(string.sub(hex, 5, 6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
		return nil
	end

	local r, g, b = string.match(text, "^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
	if r and g and b then
		return Color3.fromRGB(
			math.clamp(tonumber(r), 0, 255),
			math.clamp(tonumber(g), 0, 255),
			math.clamp(tonumber(b), 0, 255)
		)
	end
	return nil
end

function F.updateColorPickerVisuals()
	if not activeColorPicker then
		return
	end

	local picker = activeColorPicker
	local color = Color3.fromHSV(picker.hue, picker.saturation, picker.value)

	picker.button.BackgroundColor3 = color
	picker.button.BackgroundTransparency = 1 - picker.opacity

	saturationArea.BackgroundColor3 = Color3.fromHSV(picker.hue, 1, 1)
	saturationMarker.Position = UDim2.fromScale(picker.saturation, 1 - picker.value)
	hueMarker.Position = UDim2.new(picker.hue, 0, 0.5, 0)
	transparencyGradient.Color = ColorSequence.new(color)
	transparencyMarker.Position = UDim2.new(1 - picker.opacity, 0, 0.5, 0)
	colorValueInput.Text = F.colorToText(color)
end

function F.positionColorPopup(picker)
	local buttonPosition = picker.button.AbsolutePosition
	local buttonSize = picker.button.AbsoluteSize
	local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Root.AbsoluteSize
	local popupSize = colorPopup.AbsoluteSize

	-- Translate from screen space (AbsolutePosition) into the ScreenGui's own
	-- coordinate space, since IgnoreGuiInset makes the two origins differ.
	local guiOrigin = ScreenGui.AbsolutePosition

	local x = buttonPosition.X - guiOrigin.X
	local y = buttonPosition.Y + buttonSize.Y + CONFIG.spacing - guiOrigin.Y

	x = math.clamp(x, CONFIG.spacing, math.max(CONFIG.spacing, viewportSize.X - popupSize.X - CONFIG.spacing))

	colorPopup.Position = UDim2.fromOffset(x, y)
end

function F.openColorPicker(picker)
	activeColorPicker = picker
	colorPopupOpen = true
	F.setFormatMenuOpen(false)
	formatChevronLeft.Rotation = 42
	formatChevronRight.Rotation = -42
	F.positionColorPopup(picker)
	colorPopup.Visible = true
	colorPopup.GroupTransparency = 1
	F.updateColorPickerVisuals()
	F.tween("color_picker_popup", colorPopup, 0.15, {
		GroupTransparency = 0,
	})
end

function F.closeColorPicker()
	if not colorPopupOpen then
		return
	end

	colorPopupOpen = false
	colorDragControl = nil
	F.setFormatMenuOpen(false)
	local closeTween = F.tween("color_picker_popup", colorPopup, 0.12, {
		GroupTransparency = 1,
	})
	closeTween.Completed:Connect(function()
		if not colorPopupOpen then
			colorPopup.Visible = false
		end
	end)
end

function F.addColorPickerToToggle(toggleRow, initialColor)
	local attached = colorPickersByToggle[toggleRow]
	if not attached then
		attached = {}
		colorPickersByToggle[toggleRow] = attached
	end

	if #attached >= MAX_COLORPICKERS_PER_TOGGLE then
		return nil
	end

	local pickerColor = initialColor or Color3.fromRGB(255, 40, 40)
	local hue, saturation, value = pickerColor:ToHSV()
	local picker = {
		color = pickerColor,
		hue = hue,
		saturation = saturation,
		value = value,
		opacity = 1,
	}

	local index = #attached + 1
	local swatch = F.create("TextButton", toggleRow, {
		Name = "ColorPickerButton" .. index,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -(36 + CONFIG.spacing + index * 14 + index * CONFIG.spacing), 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = pickerColor,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 7,
	})
	F.addCorner(swatch, 3)
	local swatchStroke = F.addStroke(swatch)
	swatchStroke.Thickness = 1
	swatchStroke.Transparency = 0.35

	picker.button = swatch
	picker.stroke = swatchStroke
	table.insert(attached, picker)

	local occupiedWidth = 36 + CONFIG.spacing + (#attached * 14) + (#attached * CONFIG.spacing) + CONFIG.spacing
	local label = toggleRow:FindFirstChild("ToggleLabel")
	if label then
		label.Position = UDim2.fromOffset(0, 0)
		label.Size = UDim2.new(1, -occupiedWidth, 1, 0)
	end

	swatch.MouseEnter:Connect(function()
		F.tween("color_swatch_stroke_" .. tostring(swatch), swatchStroke, 0.12, {
			Transparency = 0,
			Thickness = 1.5,
		})
	end)

	swatch.MouseLeave:Connect(function()
		F.tween("color_swatch_stroke_" .. tostring(swatch), swatchStroke, 0.12, {
			Transparency = 0.35,
			Thickness = 1,
		})
	end)

	swatch.Activated:Connect(function()
		if colorPopupOpen and activeColorPicker == picker then
			F.closeColorPicker()
		else
			F.openColorPicker(picker)
		end
	end)

	return picker
end

local primaryColorPicker = F.addColorPickerToToggle(colorToggleRow, Color3.fromRGB(255, 40, 40))

function F.applyColorPickerPoint(control, point)
	if not activeColorPicker then
		return
	end

	local target = control == "saturation" and saturationArea
		or control == "hue" and hueTrack
		or transparencyTrack

	local position = target.AbsolutePosition
	local size = target.AbsoluteSize
	local x = math.clamp((point.X - position.X) / math.max(size.X, 1), 0, 1)
	local y = math.clamp((point.Y - position.Y) / math.max(size.Y, 1), 0, 1)

	if control == "saturation" then
		activeColorPicker.saturation = x
		activeColorPicker.value = 1 - y
	elseif control == "hue" then
		activeColorPicker.hue = x
	elseif control == "transparency" then
		activeColorPicker.opacity = 1 - x
	end

	F.updateColorPickerVisuals()
end

function F.colorPointerPosition(input)
	return getPointerPosition(input)
end

function F.beginColorDrag(control, input)
	if not colorPopupOpen then
		return
	end

	local inputType = input.UserInputType
	if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
		return
	end

	colorDragControl = control
	colorDragInputType = inputType
	colorDragTouchInput = inputType == Enum.UserInputType.Touch and input or nil
	F.applyColorPickerPoint(control, F.colorPointerPosition(input))
end

saturationHitArea.InputBegan:Connect(function(input)
	F.beginColorDrag("saturation", input)
end)
hueHitArea.InputBegan:Connect(function(input)
	F.beginColorDrag("hue", input)
end)
transparencyHitArea.InputBegan:Connect(function(input)
	F.beginColorDrag("transparency", input)
end)

SERVICES.UserInputService.InputChanged:Connect(function(input)
	if not colorDragControl then
		return
	end

	if colorDragInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement then
		F.applyColorPickerPoint(colorDragControl, F.colorPointerPosition())
	elseif colorDragInputType == Enum.UserInputType.Touch and input == colorDragTouchInput then
		F.applyColorPickerPoint(colorDragControl, F.colorPointerPosition(input))
	end
end)

SERVICES.UserInputService.InputEnded:Connect(function(input)
	if not colorDragControl then
		return
	end

	if colorDragInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1 then
		colorDragControl = nil
		colorDragInputType = nil
		colorDragTouchInput = nil
	elseif colorDragInputType == Enum.UserInputType.Touch and input == colorDragTouchInput then
		colorDragControl = nil
		colorDragInputType = nil
		colorDragTouchInput = nil
	end
end)

formatButton.Activated:Connect(function()
	local isOpen = not formatMenuOpen
	F.setFormatMenuOpen(isOpen)

	if isOpen then
		-- Anchor the menu below the format button in Root space. The
		-- color popup is a CanvasGroup that clips children to its own
		-- bounds, so the menu lives in Root and is positioned from the
		-- button's absolute position (translated for IgnoreGuiInset).
		local guiOrigin = ScreenGui.AbsolutePosition
		local buttonPosition = formatButton.AbsolutePosition
		local buttonSize = formatButton.AbsoluteSize
		local menuSize = formatMenu.AbsoluteSize
		local viewportSize = ScreenGui.AbsoluteSize
		local menuX = buttonPosition.X - guiOrigin.X
		local menuY = buttonPosition.Y + buttonSize.Y + 4 - guiOrigin.Y
		-- The hex/rgb format menu always opens downward from the button.
		formatMenu.Position = UDim2.fromOffset(menuX, buttonPosition.Y + buttonSize.Y + 4 - guiOrigin.Y)
	end
	F.tween("format_chevron_left", formatChevronLeft, 0.14, {
		Rotation = isOpen and -42 or 42,
		BackgroundColor3 = isOpen and COLORS.White or COLORS.Gray,
	})
	F.tween("format_chevron_right", formatChevronRight, 0.14, {
		Rotation = isOpen and 42 or -42,
		BackgroundColor3 = isOpen and COLORS.White or COLORS.Gray,
	})
end)

function F.setColorFormat(format)
	colorFormat = format
	formatButtonText.Text = format
	hexOptionText.TextColor3 = format == "HEX" and COLORS.Accent or COLORS.TabIdle
	rgbOptionText.TextColor3 = format == "RGB" and COLORS.Accent or COLORS.TabIdle
	F.updateColorPickerVisuals()
	F.setFormatMenuOpen(false)
	F.tween("format_chevron_left", formatChevronLeft, 0.14, {
		Rotation = 42,
		BackgroundColor3 = COLORS.Gray,
	})
	F.tween("format_chevron_right", formatChevronRight, 0.14, {
		Rotation = -42,
		BackgroundColor3 = COLORS.Gray,
	})
end

hexOption.Activated:Connect(function()
	F.setColorFormat("HEX")
end)
rgbOption.Activated:Connect(function()
	F.setColorFormat("RGB")
end)

colorValueInput.FocusLost:Connect(function()
	if not activeColorPicker then
		return
	end

	local parsed = F.parseColorText(colorValueInput.Text)
	if parsed then
		local hue, saturation, value = parsed:ToHSV()
		activeColorPicker.hue = hue
		activeColorPicker.saturation = saturation
		activeColorPicker.value = value
		F.updateColorPickerVisuals()
	else
		F.updateColorPickerVisuals()
	end
end)

function F.colorPointInside(guiObject, point)
	local position = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return point.X >= position.X and point.X <= position.X + size.X
		and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

SERVICES.UserInputService.InputBegan:Connect(function(input)
	if not colorPopupOpen then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local point = F.colorPointerPosition(input)
	local clickedPopup = F.colorPointInside(colorPopup, point)
		or (formatMenu.Visible and F.colorPointInside(formatMenu, point))
	local clickedSwatch = false
	for _, pickerList in pairs(colorPickersByToggle) do
		for _, picker in ipairs(pickerList) do
			if F.colorPointInside(picker.button, point) then
				clickedSwatch = true
				break
			end
		end
	end

	if not clickedPopup and not clickedSwatch then
		F.closeColorPicker()
	end
end)

SERVICES.RunService.RenderStepped:Connect(function()
	if dropdownOpen then
		F.updateDropdownPopupGeometry()
	end

	if colorPopupOpen and activeColorPicker then
		F.positionColorPopup(activeColorPicker)
	end
end)

function F.updateGroupBoxLayout()
	local availableWidth = math.max(0, content.AbsoluteSize.X - CONFIG.spacing * 3)
	local groupWidth = availableWidth / 2
	local dividerY = CONFIG.spacing + 18 + CONFIG.spacing
	local componentY = dividerY + 1 + CONFIG.spacing
	local nextComponentY = componentY + 30 + CONFIG.spacing
	local titleGap = componentTitleGap
	local titleHeight = componentTitleHeight
	local leftButtonY = nextComponentY + titleHeight + titleGap
	local leftHeight = leftButtonY + 28 + CONFIG.spacing
	local sliderControlY = nextComponentY + titleHeight + titleGap
	local hitAreaTop = sliderControlY - 2
	local hitAreaHeight = 30
	local rightHeight = hitAreaTop + hitAreaHeight + CONFIG.spacing
	local sliderLeft = CONFIG.spacing
	local sliderRightGap = CONFIG.spacing
	local sliderInputWidth = 46
	local sliderControlWidthOffset = sliderLeft + sliderRightGap * 2 + sliderInputWidth

	helloGroupBox.Position = UDim2.fromOffset(CONFIG.spacing, 16)
	helloGroupBox.Size = UDim2.fromOffset(groupWidth, leftHeight)

	secondGroupBox.Position = UDim2.fromOffset(CONFIG.spacing, 16 + leftHeight + CONFIG.spacing)
	secondGroupBox.Size = UDim2.fromOffset(
		groupWidth,
		F.secondGroupTargetHeight()
	)

	conditionalRow.Position = UDim2.fromOffset(CONFIG.spacing, conditionalRowY)
	conditionalRow.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 30)
	hiddenRow.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 30)

	secondGroupTitle.Position = UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing)
	secondGroupTitle.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 18)
	secondGroupDivider.Position = UDim2.fromOffset(CONFIG.spacing, secondGroupDividerY)
	secondGroupDivider.Size = headerDivider.Size
	secondGroupDivider.BackgroundColor3 = headerDivider.BackgroundColor3
	secondGroupDivider.BackgroundTransparency = headerDivider.BackgroundTransparency
	secondGroupDivider.BorderSizePixel = headerDivider.BorderSizePixel
	secondGroupDivider.ZIndex = headerDivider.ZIndex
	colorToggleRow.Position = UDim2.fromOffset(CONFIG.spacing, secondToggleRowY)
	colorToggleRow.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 30)
	colorToggleTrack.Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10)

	local colorPickerCount = #(colorPickersByToggle[colorToggleRow] or {})
	local occupiedWidth = 36 + CONFIG.spacing + colorPickerCount * 14 + colorPickerCount * CONFIG.spacing + CONFIG.spacing
	colorToggleLabel.Size = UDim2.new(1, -occupiedWidth, 1, 0)

	rightGroupBox.Position = UDim2.fromOffset(CONFIG.spacing * 2 + groupWidth, 16)
	rightGroupBox.Size = UDim2.fromOffset(groupWidth, rightHeight)

	helloTitle.Position = UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing)
	helloTitle.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 18)
	headerDivider.Position = UDim2.fromOffset(CONFIG.spacing, dividerY)
	headerDivider.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 1)

	local function layoutToggleWithSettings(groupBox, row, track, label, button)
		local innerWidth = math.max(0, groupBox.AbsoluteSize.X - CONFIG.spacing * 2)
		local settingsWidth = button and (button.AbsoluteSize.X + CONFIG.spacing) or 0
		local rowWidth = math.max(0, innerWidth - settingsWidth)
		row.Position = UDim2.fromOffset(CONFIG.spacing, componentY)
		row.Size = UDim2.fromOffset(rowWidth, 30)
		label.Position = UDim2.fromOffset(0, 0)
		label.Size = UDim2.new(1, -66, 1, 0)
		track.Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10)
		if button then
			button.AnchorPoint = Vector2.new(0, 0.5)
			button.Position = UDim2.fromOffset(CONFIG.spacing + rowWidth + CONFIG.spacing, componentY + 15)
		end
	end

	layoutToggleWithSettings(helloGroupBox, toggleRow, toggleTrack, toggleLabel, settingsButton)
	layoutToggleWithSettings(rightGroupBox, rightToggleRow, rightToggleTrack, rightToggleLabel, rightSettingsButton)

	dropdownTitle.Position = UDim2.fromOffset(CONFIG.spacing, nextComponentY)
	dropdownTitle.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, titleHeight)
	dropdownButton.Position = UDim2.fromOffset(CONFIG.spacing, leftButtonY)
	dropdownButton.Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 28)

	sliderTitle.Position = UDim2.fromOffset(CONFIG.spacing, nextComponentY)
	sliderTitle.Size = UDim2.new(1, -(sliderLeft + CONFIG.spacing * 2 + 46), 0, titleHeight)
	sliderValueLabel.AnchorPoint = Vector2.new(1, 0)
	sliderValueLabel.Position = UDim2.new(1, -CONFIG.spacing, 0, nextComponentY)
	sliderValueLabel.Size = UDim2.fromOffset(46, titleHeight)

	sliderInput.Position = UDim2.new(1, -(CONFIG.spacing + sliderInputWidth), 0, sliderControlY)
	sliderInput.Size = UDim2.fromOffset(sliderInputWidth, 26)
	sliderHitArea.Position = UDim2.fromOffset(sliderLeft, hitAreaTop)
	sliderHitArea.Size = UDim2.new(1, -sliderControlWidthOffset, 0, hitAreaHeight)
	sliderTrack.Position = UDim2.fromOffset(sliderLeft, sliderControlY + 11)
	sliderTrack.Size = UDim2.new(1, -sliderControlWidthOffset, 0, 4)

	if dropdownOpen then
		F.updateDropdownPopupGeometry()
	end
end

content:GetPropertyChangedSignal("AbsoluteSize"):Connect(F.updateGroupBoxLayout)
F.updateGroupBoxLayout()

local combatLabel = F.makeText(
	sidebar,
	"COMBAT",
	UDim2.new(1, -20, 0, 14),
	UDim2.fromOffset(14, 14),
	11,
	COLORS.Muted,
	Enum.Font.GothamBold
)

local selectionBg = F.create("Frame", sidebar, {
	Name = "SelectionBackground",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromOffset(CONFIG.SIDEBAR_W * 0.5, 34),
	Size = UDim2.fromOffset(0, CONFIG.TAB_H),
	BackgroundColor3 = COLORS.SelectBg,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 1,
})
F.addCorner(selectionBg, 4)

local tabs = {}
local selectedTab = nil
local selectionRevision = 0

function F.setTabSelected(tab)
	if selectedTab == tab then
		return
	end

	selectionRevision += 1
	local revision = selectionRevision
	local previousTab = selectedTab
	selectedTab = tab

	if previousTab then
		F.tween("tab_text_" .. previousTab.name, previousTab.label, 0.16, {
			TextColor3 = COLORS.TabIdle,
			Position = UDim2.fromOffset(18, 0),
		})

		local collapse = F.tween("selection_background", selectionBg, 0.14, {
			Size = UDim2.fromOffset(0, CONFIG.TAB_H),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		collapse.Completed:Wait()
	end

	if revision ~= selectionRevision then
		return
	end

	local y = tab.button.Position.Y.Offset
	local fullWidth = CONFIG.SIDEBAR_W - 16

	selectionBg.AnchorPoint = Vector2.new(0.5, 0)
	selectionBg.Position = UDim2.fromOffset(CONFIG.SIDEBAR_W * 0.5, y)
	selectionBg.Size = UDim2.fromOffset(0, CONFIG.TAB_H)
	selectionBg.Visible = true

	F.tween("selection_background", selectionBg, CONFIG.SELECT_EXPAND_T, {
		Size = UDim2.fromOffset(fullWidth, CONFIG.TAB_H),
	}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	F.tween("tab_text_" .. tab.name, tab.label, 0.16, {
		TextColor3 = COLORS.Accent,
		Position = UDim2.fromOffset(18, 0),
	})

	if F.setActivePage then
		F.setActivePage(tab.name)
	end
end

function F.createTab(name, order, explicitY)
	local y = explicitY or (34 + (order - 1) * (CONFIG.TAB_H + 4))

	local button = F.create("TextButton", sidebar, {
		Name = name .. "TabButton",
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, CONFIG.TAB_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
	})

	local label = F.makeText(
		button,
		name,
		UDim2.new(1, -24, 1, 0),
		UDim2.fromOffset(18, 0),
		13,
		COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	label.ZIndex = 3

	local tab = {
		name = name,
		button = button,
		label = label,
	}

	button.MouseEnter:Connect(function()
		local targetColor = selectedTab == tab and COLORS.Accent or COLORS.TabHover
		F.tween("tab_hover_" .. name, label, 0.14, {
			Position = UDim2.fromOffset(22, 0),
			TextColor3 = targetColor,
		})
	end)

	button.MouseLeave:Connect(function()
		local targetColor = selectedTab == tab and COLORS.Accent or COLORS.TabIdle
		F.tween("tab_hover_" .. name, label, 0.14, {
			Position = UDim2.fromOffset(18, 0),
			TextColor3 = targetColor,
		})
	end)

	button.MouseButton1Click:Connect(function()
		F.setTabSelected(tab)
	end)

	tabs[name] = tab
	return tab
end

local legitTab = F.createTab("Legit", 1)
task.defer(function()
	F.setTabSelected(legitTab)
end)

local otherCategoryY = 34 + CONFIG.TAB_H + 10
local otherFeaturesCategoryLabel = F.makeText(
	sidebar,
	"Other features!",
	UDim2.new(1, -20, 0, 14),
	UDim2.fromOffset(14, otherCategoryY),
	11,
	COLORS.Muted,
	Enum.Font.GothamBold
)

local newFeaturesTab = F.createTab("new features", 2, otherCategoryY + 18)

local profileBar = F.create("Frame", window, {
	Name = "ProfileBar",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, CONFIG.PROFILE_H),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 4,
})

F.create("Frame", profileBar, {
	Name = "ProfileDivider",
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
})

local avatar = F.create("ImageLabel", profileBar, {
	Name = "Avatar",
	BackgroundColor3 = COLORS.SelectBg,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.fromOffset(22, 22),
	Image = "",
	ZIndex = 5,
})
F.addCorner(avatar, 6)

local profileInfo = F.create("Frame", profileBar, {
	Name = "ProfileInfo",
	Position = UDim2.fromOffset(42, 0),
	Size = UDim2.new(1, -54, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 5,
})

F.create("UIListLayout", profileInfo, {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 10),
})

local usernameLabel = F.makeText(
	profileInfo,
	PLAYER.LocalPlayer.Name,
	UDim2.new(0, 0, 1, 0),
	UDim2.fromOffset(0, 0),
	12,
	COLORS.Username,
	Enum.Font.GothamBold
)
usernameLabel.Name = "Username"
usernameLabel.AutomaticSize = Enum.AutomaticSize.X
usernameLabel.LayoutOrder = 1
usernameLabel.ZIndex = 5

F.create("Frame", profileInfo, {
	Name = "ClockDivider",
	Size = UDim2.fromOffset(1, 14),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	LayoutOrder = 2,
	ZIndex = 5,
})

local clockLabel = F.makeText(
	profileInfo,
	os.date("%H:%M:%S"),
	UDim2.new(0, 0, 1, 0),
	UDim2.fromOffset(0, 0),
	12,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
clockLabel.Name = "LocalTime"
clockLabel.AutomaticSize = Enum.AutomaticSize.X
clockLabel.LayoutOrder = 3
clockLabel.ZIndex = 5

-- Live local time (hour:minute:second), refreshed as the wall clock ticks.
task.spawn(function()
	local last = ""
	while true do
		local now = os.date("%H:%M:%S")
		if now ~= last then
			last = now
			clockLabel.Text = now
		end
		task.wait(0.1)
	end
end)

local resizeGrip = F.create("TextButton", window, {
	Name = "ResizeGrip",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -6, 1, -6),
	Size = UDim2.fromOffset(18, 18),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 12,
})

function F.makeDot(parent, x, y, name)
	local dot = F.create("Frame", parent, {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(3, 3),
		BackgroundColor3 = COLORS.Icon,
		BorderSizePixel = 0,
		ZIndex = 13,
	})
	F.addCorner(dot, 2)
	return dot
end

local resizeDots = {
	F.makeDot(resizeGrip, 14, 4, "ResizeDot1"),
	F.makeDot(resizeGrip, 10, 9, "ResizeDot2"),
	F.makeDot(resizeGrip, 14, 9, "ResizeDot3"),
	F.makeDot(resizeGrip, 6, 14, "ResizeDot4"),
	F.makeDot(resizeGrip, 10, 14, "ResizeDot5"),
	F.makeDot(resizeGrip, 14, 14, "ResizeDot6"),
}

function F.setResizeDotsColor(color)
	for index, dot in ipairs(resizeDots) do
		F.tween("resize_dot_" .. index, dot, 0.13, {
			BackgroundColor3 = color,
		})
	end
end

local miniBar = F.create("CanvasGroup", Root, {
	Name = "MiniBar",
	Position = UDim2.fromOffset(initialPosition.X, initialPosition.Y),
	Size = UDim2.fromOffset(CONFIG.MINI_SIZE.X, CONFIG.MINI_SIZE.Y),
	BackgroundColor3 = COLORS.Background,
	BackgroundTransparency = 0,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Visible = false,
	ZIndex = 20,
})
F.addCorner(miniBar, 6)
F.addStroke(miniBar)

local miniAvatar = F.create("ImageLabel", miniBar, {
	Name = "MiniAvatar",
	BackgroundColor3 = COLORS.SelectBg,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.fromOffset(22, 22),
	Image = "",
	ZIndex = 21,
})
F.addCorner(miniAvatar, 6)

local miniName = F.makeText(
	miniBar,
	PLAYER.LocalPlayer.Name,
	UDim2.fromOffset(105, CONFIG.MINI_SIZE.Y),
	UDim2.fromOffset(41, 0),
	12,
	COLORS.Username,
	Enum.Font.GothamBold
)
miniName.TextTruncate = Enum.TextTruncate.AtEnd
miniName.ZIndex = 21

F.create("Frame", miniBar, {
	Name = "ProfileDivider",
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(151, 10),
	Size = UDim2.fromOffset(1, CONFIG.MINI_SIZE.Y - 20),
	ZIndex = 21,
})

local dragHandle = F.create("TextButton", miniBar, {
	Name = "DragHandle",
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(157, 4),
	Size = UDim2.fromOffset(28, CONFIG.MINI_SIZE.Y - 8),
	Text = "",
	AutoButtonColor = false,
	ZIndex = 22,
})
F.addCorner(dragHandle, 4)

local arrowHolder = F.create("Frame", dragHandle, {
	Name = "FourWayArrow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(20, 20),
	BackgroundTransparency = 1,
	ZIndex = 23,
})

local arrowParts = {}

function F.addArrowLine(x1, y1, x2, y2, name)
	local dx = x2 - x1
	local dy = y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	local line = F.create("Frame", arrowHolder, {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((x1 + x2) * 0.5, (y1 + y2) * 0.5),
		Size = UDim2.fromOffset(length, 1.5),
		Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = COLORS.Icon,
		BorderSizePixel = 0,
		ZIndex = 24,
	})
	table.insert(arrowParts, line)
	return line
end

F.addArrowLine(10, 10, 10, 4, "ArrowUpShaft")
F.addArrowLine(10, 2, 7, 5, "ArrowUpHeadLeft")
F.addArrowLine(10, 2, 13, 5, "ArrowUpHeadRight")
F.addArrowLine(10, 10, 10, 16, "ArrowDownShaft")
F.addArrowLine(10, 18, 7, 15, "ArrowDownHeadLeft")
F.addArrowLine(10, 18, 13, 15, "ArrowDownHeadRight")
F.addArrowLine(10, 10, 4, 10, "ArrowLeftShaft")
F.addArrowLine(2, 10, 5, 7, "ArrowLeftHeadTop")
F.addArrowLine(2, 10, 5, 13, "ArrowLeftHeadBottom")
F.addArrowLine(10, 10, 16, 10, "ArrowRightShaft")
F.addArrowLine(18, 10, 15, 7, "ArrowRightHeadTop")
F.addArrowLine(18, 10, 15, 13, "ArrowRightHeadBottom")

function F.setArrowColor(color)
	for _, part in ipairs(arrowParts) do
		part.BackgroundColor3 = color
	end
end

F.create("Frame", miniBar, {
	Name = "ExpandDivider",
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(191, 10),
	Size = UDim2.fromOffset(1, CONFIG.MINI_SIZE.Y - 20),
	ZIndex = 21,
})

local expandBtn = F.create("TextButton", miniBar, {
	Name = "ExpandButton",
	Position = UDim2.fromOffset(199, 8),
	Size = UDim2.fromOffset(28, 26),
	BackgroundColor3 = COLORS.SelectBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 22,
})
F.addCorner(expandBtn, 4)

local expandIconH = F.create("Frame", expandBtn, {
	Name = "ExpandIconHorizontal",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(10, 2),
	BackgroundColor3 = COLORS.Icon,
	BorderSizePixel = 0,
	ZIndex = 23,
})

local expandIconV = F.create("Frame", expandBtn, {
	Name = "ExpandIconVertical",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(2, 10),
	BackgroundColor3 = COLORS.Icon,
	BorderSizePixel = 0,
	ZIndex = 23,
})

local dragHandleHovered = false
local isMiniDragging = false

function F.updateDragHandle(isHovered, isDragging)
	local color = COLORS.Icon
	if isDragging then
		color = COLORS.IconActive
	elseif isHovered then
		color = COLORS.IconHover
	end

	for _, part in ipairs(arrowParts) do
		F.tween("arrow_" .. part.Name, part, 0.11, {
			BackgroundColor3 = color,
		})
	end

	F.tween("drag_handle_bg", dragHandle, 0.11, {
		BackgroundTransparency = (isHovered or isDragging) and 0.35 or 1,
	})
end

dragHandle.MouseEnter:Connect(function()
	dragHandleHovered = true
	F.updateDragHandle(true, isMiniDragging)
end)

dragHandle.MouseLeave:Connect(function()
	dragHandleHovered = false
	F.updateDragHandle(false, isMiniDragging)
end)

minimizeBtn.MouseEnter:Connect(function()
	F.tween("minimize_bg", minimizeBtn, 0.12, {
		BackgroundTransparency = 0.35,
	})
	F.tween("minimize_icon", minimizeIcon, 0.12, {
		BackgroundColor3 = COLORS.IconHover,
	})
end)

minimizeBtn.MouseLeave:Connect(function()
	F.tween("minimize_bg", minimizeBtn, 0.12, {
		BackgroundTransparency = 1,
	})
	F.tween("minimize_icon", minimizeIcon, 0.12, {
		BackgroundColor3 = COLORS.Icon,
	})
end)

expandBtn.MouseEnter:Connect(function()
	F.tween("expand_bg", expandBtn, 0.12, {
		BackgroundTransparency = 0.35,
	})
	F.tween("expand_h", expandIconH, 0.12, {
		BackgroundColor3 = COLORS.IconHover,
	})
	F.tween("expand_v", expandIconV, 0.12, {
		BackgroundColor3 = COLORS.IconHover,
	})
end)

expandBtn.MouseLeave:Connect(function()
	F.tween("expand_bg", expandBtn, 0.12, {
		BackgroundTransparency = 1,
	})
	F.tween("expand_h", expandIconH, 0.12, {
		BackgroundColor3 = COLORS.Icon,
	})
	F.tween("expand_v", expandIconV, 0.12, {
		BackgroundColor3 = COLORS.Icon,
	})
end)

resizeGrip.MouseEnter:Connect(function()
	F.setResizeDotsColor(COLORS.IconHover)
end)

resizeGrip.MouseLeave:Connect(function()
	F.setResizeDotsColor(COLORS.Icon)
end)

task.spawn(function()
	local success, image = pcall(function()
		return SERVICES.Players:GetUserThumbnailAsync(
			PLAYER.LocalPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size48x48
		)
	end)

	if success and image then
		avatar.Image = image
		miniAvatar.Image = image
	end
end)

local drag = {
	active = false,
	mode = nil,
	target = nil,
	inputType = nil,
	touchInput = nil,
	originPointer = nil,
	originGoal = nil,
	originGoalSize = nil,
	current = nil,
	goal = nil,
	currentSize = nil,
	goalSize = nil,
}

function F.getOffsetPosition(target)
	-- Derive a target's offset position within Root from its current
	-- absolute position, so scale-based positions (like the centered
	-- start position) convert cleanly into drag coordinates.
	local origin = Root.AbsolutePosition
	local position = target.AbsolutePosition
	return Vector2.new(position.X - origin.X, position.Y - origin.Y)
end

function F.beginDrag(mode, target, input)
	if drag.active or state.animating or not state.guiVisible then
		return
	end

	local inputType = input.UserInputType
	if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
		return
	end

	local position = F.getOffsetPosition(target)

	-- Pin the target to a plain top-left offset position. If the target was
	-- placed with scale/anchor (like the centered start position), writing
	-- offset positions later would otherwise re-anchor it from its center
	-- and throw it half its size up and to the left.
	target.AnchorPoint = Vector2.zero
	target.Position = UDim2.fromOffset(position.X, position.Y)

	drag.active = true
	drag.mode = mode
	drag.target = target
	drag.inputType = inputType
	drag.touchInput = inputType == Enum.UserInputType.Touch and input or nil
	drag.current = position
	drag.goal = position
	drag.originPointer = getPointerPosition(input)
	drag.originGoal = position

	if mode == "resize" then
		local size = Vector2.new(target.AbsoluteSize.X, target.AbsoluteSize.Y)
		drag.currentSize = size
		drag.goalSize = size
		drag.originGoalSize = size
		F.setResizeDotsColor(COLORS.IconActive)
	elseif mode == "mini" then
		isMiniDragging = true
		F.updateDragHandle(dragHandleHovered, true)
	end
end

function F.endDrag()
	if not drag.active then
		return
	end

	if drag.mode == "move" or drag.mode == "mini" then
		local finalPosition = F.clampToScreen(drag.goal, drag.target.AbsoluteSize)
		drag.target.Position = UDim2.fromOffset(finalPosition.X, finalPosition.Y)

		if drag.target == window then
			state.fullPos = finalPosition
		elseif drag.target == miniBar then
			state.miniPos = finalPosition
		end
	elseif drag.mode == "resize" then
		local finalSize = drag.goalSize
		window.Size = UDim2.fromOffset(finalSize.X, finalSize.Y)
		state.fullSize = finalSize
		state.fullPos = F.getOffsetPosition(window)
	end

	local previousMode = drag.mode
	drag.active = false
	drag.mode = nil
	drag.target = nil
	drag.inputType = nil
	drag.touchInput = nil
	drag.originPointer = nil
	drag.originGoal = nil
	drag.originGoalSize = nil
	drag.current = nil
	drag.goal = nil
	drag.currentSize = nil
	drag.goalSize = nil

	if previousMode == "mini" then
		isMiniDragging = false
		F.updateDragHandle(dragHandleHovered, false)
	elseif previousMode == "resize" then
		F.setResizeDotsColor(COLORS.Icon)
	end
end

-- Pointer positions are compared in a single consistent space, so the
-- delta between the drag-start pointer and the current pointer is always
-- correct regardless of how the engine reports absolute coordinates.
function F.updateDragFromPointer(pointer)
	if not drag.active then
		return
	end

	local delta = pointer - drag.originPointer
	if delta.Magnitude == 0 then
		return
	end

	if drag.mode == "move" or drag.mode == "mini" then
		drag.goal = F.clampToScreen(
			drag.originGoal + delta,
			drag.target.AbsoluteSize
		)
	elseif drag.mode == "resize" then
		local currentCamera = workspace.CurrentCamera
		local windowPosition = F.getOffsetPosition(window)
		local availableWidth = currentCamera and currentCamera.ViewportSize.X - windowPosition.X or CONFIG.MAX_SIZE.X
		local availableHeight = currentCamera and currentCamera.ViewportSize.Y - windowPosition.Y or CONFIG.MAX_SIZE.Y

		local maxWidth = math.max(CONFIG.MIN_SIZE.X, math.min(CONFIG.MAX_SIZE.X, availableWidth))
		local maxHeight = math.max(CONFIG.MIN_SIZE.Y, math.min(CONFIG.MAX_SIZE.Y, availableHeight))

		drag.goalSize = Vector2.new(
			math.clamp(drag.originGoalSize.X + delta.X, CONFIG.MIN_SIZE.X, maxWidth),
			math.clamp(drag.originGoalSize.Y + delta.Y, CONFIG.MIN_SIZE.Y, maxHeight)
		)
	end
end

function F.pointInside(guiObject, point)
	local position = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize

	return point.X >= position.X
		and point.Y >= position.Y
		and point.X <= position.X + size.X
		and point.Y <= position.Y + size.Y
end

getPointerPosition = function(input)
	-- Keep pointer coordinates in the same space as GuiObject.AbsolutePosition.
	local origin = ScreenGui.AbsolutePosition
	if input and input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X + origin.X, input.Position.Y + origin.Y)
	end

	local mousePosition = SERVICES.UserInputService:GetMouseLocation()
	return Vector2.new(mousePosition.X + origin.X, mousePosition.Y + origin.Y)
end

SERVICES.UserInputService.InputBegan:Connect(function(input)
	local inputType = input.UserInputType
	if dropdownOpen and (inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch) then
		local point = getPointerPosition(input)
		if not F.pointInside(dropdownButton, point) and not F.pointInside(dropdownPopup, point) then
			F.setDropdownOpen(false)
		end
	end
end)

SERVICES.UserInputService.InputBegan:Connect(function(input)
	local inputType = input.UserInputType
	if inputType ~= Enum.UserInputType.MouseButton1
		and inputType ~= Enum.UserInputType.Touch then
		return
	end

	if not state.guiVisible or state.animating or state.visibilityAnimating then
		return
	end

	local point = getPointerPosition(input)

	if state.minimized then
		if miniBar.Visible and F.pointInside(dragHandle, point) then
			F.beginDrag("mini", miniBar, input)
		end
		return
	end

	if not window.Visible then
		return
	end

	if rightGroupBox.Visible and F.pointInside(sliderHitArea, point) then
		F.beginSliderDrag(input)
		return
	end

	if F.pointInside(resizeGrip, point) then
		F.beginDrag("resize", window, input)
	elseif F.pointInside(dragRegion, point) and not F.pointInside(minimizeBtn, point) then
		F.beginDrag("move", window, input)
	end
end)

SERVICES.UserInputService.InputChanged:Connect(function(input)
	if not drag.active then
		return
	end

	if drag.inputType == Enum.UserInputType.MouseButton1 then
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			F.updateDragFromPointer(getPointerPosition(input))
		end
	elseif drag.inputType == Enum.UserInputType.Touch and input == drag.touchInput then
		F.updateDragFromPointer(getPointerPosition(input))
	end
end)

SERVICES.UserInputService.InputEnded:Connect(function(input)
	if not drag.active then
		return
	end

	if drag.inputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1 then
		F.endDrag()
	elseif drag.inputType == Enum.UserInputType.Touch and input == drag.touchInput then
		F.endDrag()
	end
end)

SERVICES.UserInputService.WindowFocusReleased:Connect(F.endDrag)

SERVICES.RunService.RenderStepped:Connect(function(deltaTime)
	if not drag.active then
		return
	end

	local alpha = 1 - math.exp(-deltaTime / CONFIG.DRAG_SMOOTH)

	if drag.mode == "move" or drag.mode == "mini" then
		drag.current = drag.current:Lerp(drag.goal, alpha)
		drag.current = F.clampToScreen(drag.current, drag.target.AbsoluteSize)
		drag.target.Position = UDim2.fromOffset(
			math.floor(drag.current.X + 0.5),
			math.floor(drag.current.Y + 0.5)
		)

		if drag.target == window then
			state.fullPos = drag.current
		elseif drag.target == miniBar then
			state.miniPos = drag.current
		end
	elseif drag.mode == "resize" then
		drag.currentSize = drag.currentSize:Lerp(drag.goalSize, alpha)
		window.Size = UDim2.fromOffset(
			math.floor(drag.currentSize.X + 0.5),
			math.floor(drag.currentSize.Y + 0.5)
		)
	end
end)

function F.minimizeWindow()
	if state.minimized or state.animating then
		return
	end

	state.animating = true
	F.endDrag()
	F.setDropdownOpen(false)
	F.closeColorPicker()
	F.setToggleSettingsOpen(false)

	state.fullPos = F.getOffsetPosition(window)
	state.fullSize = Vector2.new(window.Size.X.Offset, window.Size.Y.Offset)

	if not state.miniPos then
		state.miniPos = Vector2.new(
			state.fullPos.X + (state.fullSize.X - CONFIG.MINI_SIZE.X) * 0.5,
			state.fullPos.Y
		)
	end

	state.miniPos = F.clampToScreen(state.miniPos, CONFIG.MINI_SIZE)
	miniBar.Position = UDim2.fromOffset(state.miniPos.X, state.miniPos.Y)
	miniBar.Visible = true
	miniBar.GroupTransparency = 1

	local windowFade = F.tween(
		"window_group_fade",
		window,
		CONFIG.MINI_TRANSITION_T,
		{ GroupTransparency = 1 },
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	F.tween(
		"mini_group_fade",
		miniBar,
		CONFIG.MINI_TRANSITION_T,
		{ GroupTransparency = 0 },
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	windowFade.Completed:Wait()

	window.Visible = false
	window.GroupTransparency = 0
	state.minimized = true
	state.animating = false
end

function F.expandWindow()
	if not state.minimized or state.animating then
		return
	end

	state.animating = true
	F.endDrag()

	state.fullPos = F.clampToScreen(state.fullPos, state.fullSize)
	-- fullPos is a top-left offset; drop the centered start anchor so the
	-- offset is interpreted from the top-left corner instead of the center.
	window.AnchorPoint = Vector2.zero
	window.Position = UDim2.fromOffset(state.fullPos.X, state.fullPos.Y)
	window.Size = UDim2.fromOffset(state.fullSize.X, state.fullSize.Y)
	window.Visible = true
	window.GroupTransparency = 1

	local miniFade = F.tween(
		"mini_group_fade",
		miniBar,
		CONFIG.MINI_TRANSITION_T,
		{ GroupTransparency = 1 },
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	F.tween(
		"window_group_fade",
		window,
		CONFIG.MINI_TRANSITION_T,
		{ GroupTransparency = 0 },
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	miniFade.Completed:Wait()

	miniBar.Visible = false
	miniBar.GroupTransparency = 1
	state.minimized = false
	state.animating = false
end

minimizeBtn.MouseButton1Click:Connect(F.minimizeWindow)
expandBtn.MouseButton1Click:Connect(F.expandWindow)

function F.setGuiVisible(visible)
	if state.visibilityAnimating or state.animating or state.guiVisible == visible then
		return
	end

	state.visibilityAnimating = true
	state.guiVisible = visible

	if not visible then
		F.endDrag()
		F.closeColorPicker()
		if typeof(F.setToggleSettingsOpen) == "function" then
			F.setToggleSettingsOpen(false)
		end
		local fade = F.tween(
			"root_visibility",
			Root,
			0.14,
			{ GroupTransparency = 1 },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)
		fade.Completed:Wait()
		Root.Visible = false
		Root.GroupTransparency = 0
	else
		Root.GroupTransparency = 1
		Root.Visible = true
		local fade = F.tween(
			"root_visibility",
			Root,
			0.14,
			{ GroupTransparency = 0 },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		fade.Completed:Wait()
	end

	state.visibilityAnimating = false
end

SERVICES.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or SERVICES.UserInputService:GetFocusedTextBox() then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		F.setGuiVisible(not state.guiVisible)
	end
end)

-- ============================================================================
-- Other features! page: "new features" tab with its own tabbed groupbox.
-- ============================================================================

local otherFeaturesPage = F.create("Frame", content, {
	Name = "OtherFeaturesPage",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 2,
})

local featuresGroup = F.create("Frame", otherFeaturesPage, {
	Name = "FeaturesGroupBox",
	Position = UDim2.fromOffset(CONFIG.spacing, 16),
	Size = UDim2.new(0.5, -(CONFIG.spacing * 1.5), 0, 69),
	BackgroundColor3 = Color3.fromRGB(16, 16, 19),
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 3,
})
F.addCorner(featuresGroup, 7)
F.addStroke(featuresGroup)

local featuresGroupShadow = Instance.new("UIShadow")
featuresGroupShadow.Name = "GroupBoxShadow"
featuresGroupShadow.Color = Color3.fromRGB(0, 0, 0)
featuresGroupShadow.Transparency = 0.56
featuresGroupShadow.BlurRadius = UDim.new(0, 14)
featuresGroupShadow.Offset = UDim2.fromOffset(0, 4)
featuresGroupShadow.Spread = UDim2.fromOffset(0, 1)
featuresGroupShadow.ShowBehindParent = true
featuresGroupShadow.Parent = featuresGroup

local featuresHeaderRow = F.create("Frame", featuresGroup, {
	Name = "HeaderRow",
	Position = UDim2.fromOffset(CONFIG.spacing, 0),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 28),
	BackgroundTransparency = 1,
	ZIndex = 4,
})
F.create("UIListLayout", featuresHeaderRow, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, CONFIG.spacing),
})

local function makeHeaderTab(name, text, order)
	return F.create("TextButton", featuresHeaderRow, {
		Name = name,
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = COLORS.TabIdle,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		LayoutOrder = order,
		ZIndex = 4,
	})
end

local featuresHeaderTab = makeHeaderTab("FeaturesHeaderTab", "features", 1)
local containerHeaderTab = makeHeaderTab("ContainertabHeaderTab", "containertab!", 3)

local headerTabDivider = F.create("Frame", featuresHeaderRow, {
	Name = "HeaderTabDivider",
	Size = UDim2.fromOffset(1, 12),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	LayoutOrder = 2,
	ZIndex = 4,
})

F.create("Frame", featuresGroup, {
	Name = "HeaderDivider",
	Position = UDim2.fromOffset(CONFIG.spacing, 28),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 1),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	ZIndex = 4,
})

local featuresContent = F.create("Frame", featuresGroup, {
	Name = "FeaturesContent",
	Position = UDim2.fromOffset(CONFIG.spacing, 34),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 220),
	BackgroundTransparency = 1,
	ZIndex = 4,
})

local containerContent = F.create("Frame", featuresGroup, {
	Name = "ContainertabContent",
	Position = UDim2.fromOffset(CONFIG.spacing, 34),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 220),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 4,
})

local currentGroupTab = "features"
local conditionalDropdownShown = false
local sliderShown = false
local helloShown = false

local function containerContentBottom()
	local sliderOffset = sliderShown and 54 or 0
	local dropdownY = 36 + sliderOffset
	if helloShown then
		return dropdownY + 28 + 6 + 30
	end
	return dropdownY + 28
end

function F.refreshGroupHeight()
	local contentBottom
	if currentGroupTab == "features" then
		contentBottom = conditionalDropdownShown and 64 or 30
	else
		contentBottom = containerContentBottom()
	end
	F.tween("features_group_size", featuresGroup, 0.22, {
		Size = UDim2.new(0.5, -(CONFIG.spacing * 1.5), 0, 34 + contentBottom + CONFIG.spacing),
	}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

local revealStates = {}

local function setRevealed(key, row, shown)
	local revealState = revealStates[key]
	if not revealState then
		revealState = { shown = false, revision = 0 }
		revealStates[key] = revealState
	end
	if revealState.shown == shown then
		return
	end
	revealState.shown = shown
	revealState.revision += 1
	local revision = revealState.revision
	if shown then
		row.Visible = true
		row.GroupTransparency = 1
		F.tween("reveal_" .. key, row, 0.18, {
			GroupTransparency = 0,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	else
		local hideTween = F.tween("reveal_" .. key, row, 0.14, {
			GroupTransparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		hideTween.Completed:Connect(function()
			if revealState.revision == revision and not revealState.shown then
				row.Visible = false
			end
		end)
	end
end

local function createFeatureToggle(parent, name, y, text, onChanged)
	local row = F.create("TextButton", parent, {
		Name = name,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = COLORS.SelectBg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 5,
	})
	F.addCorner(row, 5)

	local label = F.makeText(
		row,
		text,
		UDim2.new(1, -66, 1, 0),
		UDim2.fromOffset(0, 0),
		13,
		COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	label.Name = "ToggleLabel"
	label.ZIndex = 6
	label.Active = false

	local track = F.create("Frame", row, {
		Name = "ToggleTrack",
		Position = UDim2.new(1, -(36 + CONFIG.spacing), 0.5, -10),
		Size = UDim2.fromOffset(36, 20),
		BackgroundColor3 = Color3.fromRGB(57, 57, 64),
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	F.addCorner(track, 10)

	local knob = F.create("Frame", track, {
		Name = "ToggleKnob",
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.fromRGB(190, 190, 198),
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	F.addCorner(knob, 7)

	local toggleState = { enabled = false }

	local function setEnabled(enabled)
		toggleState.enabled = enabled
		F.tween("feature_toggle_track_" .. name, track, 0.18, {
			BackgroundColor3 = enabled and COLORS.Accent or Color3.fromRGB(57, 57, 64),
		})
		F.tween("feature_toggle_knob_" .. name, knob, 0.18, {
			Position = enabled and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = enabled and Color3.fromRGB(245, 249, 255) or Color3.fromRGB(190, 190, 198),
		})
		if onChanged then
			onChanged(enabled)
		end
	end

	row.MouseEnter:Connect(function()
		F.setToggleHover(true, row, label)
	end)
	row.MouseLeave:Connect(function()
		F.setToggleHover(false, row, label)
	end)
	row.Activated:Connect(function()
		setEnabled(not toggleState.enabled)
	end)

	toggleState.setEnabled = setEnabled
	toggleState.row = row
	toggleState.label = label
	return toggleState
end

local function createFeatureSlider(parent, name, title, minValue, maxValue, defaultValue)
	local minV = math.min(minValue, maxValue)
	local maxV = math.max(minValue, maxValue)
	local value = math.clamp(defaultValue, minV, maxV)
	local dragging = false
	local inputWidth = 46
	local trackWidthOffset = inputWidth + CONFIG.spacing * 3

	local titleLabel = F.makeText(
		parent,
		title,
		UDim2.new(1, -(CONFIG.spacing + 46 + CONFIG.spacing), 0, 18),
		UDim2.fromOffset(0, 0),
		13,
		COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	titleLabel.Name = name .. "Title"
	titleLabel.ZIndex = 6

	local valueLabel = F.makeText(
		parent,
		"",
		UDim2.fromOffset(46, 18),
		UDim2.new(1, -CONFIG.spacing, 0, 0),
		12,
		COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	valueLabel.Name = name .. "Value"
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.ZIndex = 6

	local hitArea = F.create("TextButton", parent, {
		Name = name .. "HitArea",
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, -trackWidthOffset, 0, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 9,
	})

	local track = F.create("Frame", parent, {
		Name = name .. "Track",
		Position = UDim2.fromOffset(0, 31),
		Size = UDim2.new(1, -trackWidthOffset, 0, 4),
		BackgroundColor3 = Color3.fromRGB(55, 55, 62),
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	F.addCorner(track, 3)

	local trackStroke = F.create("UIStroke", track, {
		Color = COLORS.Accent,
		Thickness = 1,
		Transparency = 1,
	})

	local fill = F.create("Frame", track, {
		Name = "SliderFill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = COLORS.Accent,
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	F.addCorner(fill, 3)

	local knob = F.create("Frame", track, {
		Name = "SliderKnob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 8,
	})
	F.addCorner(knob, 6)

	local input = F.create("TextBox", parent, {
		Name = name .. "Input",
		Position = UDim2.new(1, -(CONFIG.spacing + inputWidth), 0, 20),
		Size = UDim2.fromOffset(inputWidth, 24),
		BackgroundColor3 = Color3.fromRGB(39, 39, 45),
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "0",
		PlaceholderColor3 = COLORS.Muted,
		TextColor3 = COLORS.Title,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
	})
	F.addCorner(input, 5)
	F.addStroke(input)

	input.MouseEnter:Connect(function()
		F.tween(name .. "_input_hover", input, 0.13, {
			BackgroundColor3 = Color3.fromRGB(48, 48, 56),
		})
	end)

	input.MouseLeave:Connect(function()
		F.tween(name .. "_input_hover", input, 0.13, {
			BackgroundColor3 = Color3.fromRGB(39, 39, 45),
		})
	end)

	local function formatValue(number)
		return string.format("%d", math.floor(number + 0.5))
	end

	local function setValue(newValue, updateInput)
		newValue = math.clamp(math.floor(newValue + 0.5), minV, maxV)
		value = newValue
		local alpha = (maxV == minV) and 0 or (newValue - minV) / (maxV - minV)
		F.tween(name .. "_fill", fill, 0.13, {
			Size = UDim2.new(alpha, 0, 1, 0),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		F.tween(name .. "_knob", knob, 0.13, {
			Position = UDim2.new(alpha, 0, 0.5, 0),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		valueLabel.Text = formatValue(newValue)
		if updateInput then
			input.Text = formatValue(newValue)
		end
	end

	local function setFromPointer(screenX)
		local trackPosition = track.AbsolutePosition.X
		local trackWidth = math.max(track.AbsoluteSize.X, 1)
		local alpha = math.clamp((screenX - trackPosition) / trackWidth, 0, 1)
		setValue(minV + (maxV - minV) * alpha, true)
	end

	local function setHover(hovered)
		F.tween(name .. "_track_hover", track, 0.14, {
			BackgroundColor3 = hovered and Color3.fromRGB(72, 72, 82) or Color3.fromRGB(55, 55, 62),
		})
		F.tween(name .. "_stroke_hover", trackStroke, 0.14, {
			Transparency = hovered and 0.45 or 1,
		})
		F.tween(name .. "_knob_hover", knob, 0.14, {
			Size = hovered and UDim2.fromOffset(14, 14) or UDim2.fromOffset(12, 12),
		})
		F.tween(name .. "_fill_hover", fill, 0.14, {
			BackgroundColor3 = hovered and Color3.fromRGB(105, 195, 255) or COLORS.Accent,
		})
	end

	local function pointerInsideHitArea(inputObject)
		local point = getPointerPosition(inputObject)
		local position = hitArea.AbsolutePosition
		local size = hitArea.AbsoluteSize
		return point.X >= position.X and point.X <= position.X + size.X
			and point.Y >= position.Y and point.Y <= position.Y + size.Y
	end

	hitArea.InputBegan:Connect(function(inputObject)
		local inputType = inputObject.UserInputType
		if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		setHover(true)
		setFromPointer(getPointerPosition(inputObject).X)
	end)

	hitArea.MouseEnter:Connect(function()
		setHover(true)
	end)

	hitArea.MouseLeave:Connect(function()
		if not dragging then
			setHover(false)
		end
	end)

	SERVICES.UserInputService.InputChanged:Connect(function(inputObject)
		if not dragging then
			return
		end
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement
			or inputObject.UserInputType == Enum.UserInputType.Touch then
			setFromPointer(getPointerPosition(inputObject).X)
		end
	end)

	SERVICES.UserInputService.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1
			or inputObject.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			setHover(pointerInsideHitArea(inputObject))
		end
	end)

	input.FocusLost:Connect(function()
		local typedValue = tonumber(input.Text)
		if typedValue then
			setValue(typedValue, true)
		else
			input.Text = formatValue(value)
		end
	end)

	setValue(value, true)

	return {
		setValue = setValue,
		getValue = function()
			return value
		end,
	}
end

local featureDropdownOpen = nil

function F.closeFeatureDropdowns()
	local current = featureDropdownOpen
	if current then
		current.close()
	end
end

local function createFeatureDropdown(parent, name, y, options, defaultOption, onSelect)
	local selected = defaultOption
	local isOpen = false

	local button = F.create("TextButton", parent, {
		Name = name .. "Button",
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(43, 43, 49),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 7,
	})
	F.addCorner(button, 5)

	local buttonText = F.makeText(
		button,
		selected,
		UDim2.new(1, -34, 1, 0),
		UDim2.fromOffset(9, 0),
		13,
		COLORS.TabIdle,
		Enum.Font.GothamMedium
	)
	buttonText.Name = "DropdownText"
	buttonText.TextTruncate = Enum.TextTruncate.None
	buttonText.ZIndex = 8
	buttonText.Active = false

	local function makeChevron(chevronName, positionOffset, rotation)
		return F.create("Frame", button, {
			Name = chevronName,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, positionOffset, 0.5, -1),
			Size = UDim2.fromOffset(6, 1.5),
			Rotation = rotation,
			BackgroundColor3 = COLORS.Icon,
			BorderSizePixel = 0,
			ZIndex = 8,
		})
	end

	local chevronLeft = makeChevron("ChevronLeft", -17, 42)
	local chevronRight = makeChevron("ChevronRight", -13, -42)

	local popup = F.create("CanvasGroup", Root, {
		Name = name .. "Options",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(160, 8),
		BackgroundColor3 = Color3.fromRGB(21, 21, 25),
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 5000,
	})
	F.addCorner(popup, 5)
	F.addStroke(popup)

	local popupTargetWidth = 160
	local popupTargetHeight = 8 + #options * 24
	local popupAnimHeight = F.create("NumberValue", popup, {
		Name = "AnimHeight",
		Value = 0,
	})
	local popupRevision = 0

	local function applyPopupLayout()
		popup.Size = UDim2.fromOffset(popupTargetWidth, math.max(popupAnimHeight.Value, 0))
	end

	popupAnimHeight.Changed:Connect(applyPopupLayout)

	local optionButtons = {}

	local function refreshOptionColors()
		for optionName, optionButton in pairs(optionButtons) do
			local optionLabel = optionButton:FindFirstChild("OptionLabel")
			if optionLabel then
				optionLabel.TextColor3 = optionName == selected and COLORS.Accent or COLORS.TabIdle
			end
		end
	end

	local function positionPopup()
		local buttonPosition = button.AbsolutePosition
		local buttonSize = button.AbsoluteSize
		local rootOrigin = Root.AbsolutePosition
		local rootSize = Root.AbsoluteSize
		if rootSize.X <= 0 or rootSize.Y <= 0 then
			local currentCamera = workspace.CurrentCamera
			rootSize = currentCamera and currentCamera.ViewportSize or Vector2.new(1280, 720)
		end
		local popupWidth = math.min(math.max(buttonSize.X, 260), math.max(48, rootSize.X - 16))
		local x = buttonPosition.X - rootOrigin.X
		local y = buttonPosition.Y - rootOrigin.Y + buttonSize.Y + 4
		x = math.clamp(x, 8, math.max(8, rootSize.X - popupWidth - 8))
		if y + popupTargetHeight > rootSize.Y - 8 then
			y = math.max(8, buttonPosition.Y - rootOrigin.Y - popupTargetHeight - 4)
		end
		popupTargetWidth = popupWidth
		popup.Position = UDim2.fromOffset(x, y)
		applyPopupLayout()
	end

	local api

	local function close()
		if not isOpen then
			return
		end
		isOpen = false
		popupRevision += 1
		local revision = popupRevision
		if featureDropdownOpen == api then
			featureDropdownOpen = nil
		end
		local fadeTween = F.tween(name .. "_popup_fade", popup, 0.12, {
			GroupTransparency = 1,
		})
		F.tween(name .. "_popup_collapse", popupAnimHeight, 0.14, {
			Value = 0,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		fadeTween.Completed:Connect(function()
			if popupRevision == revision and not isOpen then
				popup.Visible = false
			end
		end)
		F.tween(name .. "_chevron_left", chevronLeft, 0.14, {
			Rotation = 42,
			BackgroundColor3 = COLORS.Icon,
		})
		F.tween(name .. "_chevron_right", chevronRight, 0.14, {
			Rotation = -42,
			BackgroundColor3 = COLORS.Icon,
		})
		F.tween(name .. "_text", buttonText, 0.12, {
			TextColor3 = COLORS.TabIdle,
		})
		F.tween(name .. "_bg", button, 0.12, {
			BackgroundColor3 = Color3.fromRGB(43, 43, 49),
		})
	end

	local function open()
		if isOpen then
			return
		end
		F.closeFeatureDropdowns()
		featureDropdownOpen = api
		isOpen = true
		popupRevision += 1
		refreshOptionColors()
		popupAnimHeight.Value = 0
		positionPopup()
		popup.Visible = true
		popup.GroupTransparency = 1
		popup.Size = UDim2.fromOffset(popupTargetWidth, 0)
		F.tween(name .. "_popup_fade", popup, 0.12, {
			GroupTransparency = 0,
		})
		F.tween(name .. "_popup_expand", popupAnimHeight, 0.18, {
			Value = popupTargetHeight,
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		F.tween(name .. "_chevron_left", chevronLeft, 0.14, {
			Rotation = -42,
			BackgroundColor3 = COLORS.White,
		})
		F.tween(name .. "_chevron_right", chevronRight, 0.14, {
			Rotation = 42,
			BackgroundColor3 = COLORS.White,
		})
		F.tween(name .. "_text", buttonText, 0.12, {
			TextColor3 = COLORS.White,
		})
		F.tween(name .. "_bg", button, 0.12, {
			BackgroundColor3 = Color3.fromRGB(51, 51, 58),
		})
	end

	api = {
		close = close,
		refresh = function()
			if isOpen then
				positionPopup()
			end
		end,
		button = button,
		popup = popup,
		isOpen = function()
			return isOpen
		end,
		getSelected = function()
			return selected
		end,
	}

	for index, optionName in ipairs(options) do
		local optionButton = F.create("TextButton", popup, {
			Name = "Option_" .. string.gsub(optionName, "[%s%.!%-]", "_"),
			Position = UDim2.fromOffset(4, 4 + (index - 1) * 24),
			Size = UDim2.new(1, -8, 0, 22),
			BackgroundColor3 = COLORS.SelectBg,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 5001,
		})
		F.addCorner(optionButton, 4)

		local optionLabel = F.makeText(
			optionButton,
			optionName,
			UDim2.new(1, -12, 1, 0),
			UDim2.fromOffset(8, 0),
			13,
			optionName == selected and COLORS.Accent or COLORS.TabIdle,
			Enum.Font.GothamMedium
		)
		optionLabel.Name = "OptionLabel"
		optionLabel.TextTruncate = Enum.TextTruncate.None
		optionLabel.ZIndex = 5002
		optionLabel.Active = false

		optionButton.MouseEnter:Connect(function()
			F.tween(name .. "_opt_text_" .. index, optionLabel, 0.12, {
				Position = UDim2.fromOffset(12, 0),
				TextColor3 = optionName == selected and COLORS.Accent or COLORS.White,
			})
			F.tween(name .. "_opt_bg_" .. index, optionButton, 0.12, {
				BackgroundTransparency = 0.35,
			})
		end)

		optionButton.MouseLeave:Connect(function()
			F.tween(name .. "_opt_text_" .. index, optionLabel, 0.12, {
				Position = UDim2.fromOffset(8, 0),
				TextColor3 = optionName == selected and COLORS.Accent or COLORS.TabIdle,
			})
			F.tween(name .. "_opt_bg_" .. index, optionButton, 0.12, {
				BackgroundTransparency = 1,
			})
		end)

		optionButton.Activated:Connect(function()
			selected = optionName
			buttonText.Text = optionName
			refreshOptionColors()
			close()
			if onSelect then
				onSelect(optionName)
			end
		end)

		optionButtons[optionName] = optionButton
	end

	button.MouseEnter:Connect(function()
		if not isOpen then
			F.tween(name .. "_text", buttonText, 0.12, {
				TextColor3 = COLORS.White,
			})
			F.tween(name .. "_bg", button, 0.12, {
				BackgroundColor3 = Color3.fromRGB(51, 51, 58),
			})
		end
	end)

	button.MouseLeave:Connect(function()
		if not isOpen then
			F.tween(name .. "_text", buttonText, 0.12, {
				TextColor3 = COLORS.TabIdle,
			})
			F.tween(name .. "_bg", button, 0.12, {
				BackgroundColor3 = Color3.fromRGB(43, 43, 49),
			})
		end
	end)

	button.Activated:Connect(function()
		if isOpen then
			close()
		else
			open()
		end
	end)

	return api
end

SERVICES.UserInputService.InputBegan:Connect(function(inputObject)
	if not featureDropdownOpen then
		return
	end
	local inputType = inputObject.UserInputType
	if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
		return
	end
	local point = getPointerPosition(inputObject)
	local function inside(guiObject)
		local position = guiObject.AbsolutePosition
		local size = guiObject.AbsoluteSize
		return point.X >= position.X and point.X <= position.X + size.X
			and point.Y >= position.Y and point.Y <= position.Y + size.Y
	end
	local current = featureDropdownOpen
	if not inside(current.popup) and not inside(current.button) then
		current.close()
	end
end)

SERVICES.RunService.RenderStepped:Connect(function()
	if featureDropdownOpen then
		featureDropdownOpen.refresh()
	end
end)

local conditionalDropdownBlock = F.create("CanvasGroup", featuresContent, {
	Name = "ConditionalDropdownBlock",
	Position = UDim2.fromOffset(0, 36),
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 5,
})

createFeatureToggle(featuresContent, "ConditionalGroupsToggle", 0, "conditional groups!", function(enabled)
	conditionalDropdownShown = enabled
	setRevealed("conditional_groups_dropdown", conditionalDropdownBlock, enabled)
	if not enabled then
		F.closeFeatureDropdowns()
	end
	F.refreshGroupHeight()
end)

local conditionalDropdown = createFeatureDropdown(
	conditionalDropdownBlock,
	"ConditionalDropdown",
	0,
	{"i appeared now!", "this is a conditional group dropdown."},
	"i appeared now!"
)

local sliderBlock = F.create("CanvasGroup", containerContent, {
	Name = "ImNowShownBlock",
	Position = UDim2.fromOffset(0, 36),
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundTransparency = 1,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 5,
})

local containerDropdown
local helloBlock

createFeatureToggle(containerContent, "AnotherToggle", 0, "this is another toggle", function(enabled)
	sliderShown = enabled
	setRevealed("im_now_shown_slider", sliderBlock, enabled)
	local sliderOffset = enabled and 54 or 0
	if containerDropdown then
		F.tween("feature_container_dropdown_pos", containerDropdown.button, 0.22, {
			Position = UDim2.fromOffset(0, 36 + sliderOffset),
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end
	if helloBlock then
		F.tween("feature_container_hello_pos", helloBlock, 0.22, {
			Position = UDim2.fromOffset(0, 70 + sliderOffset),
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end
	F.refreshGroupHeight()
end)

createFeatureSlider(sliderBlock, "ImNowShownSlider", "im now shown!", 0, 100, 40)

containerDropdown = createFeatureDropdown(
	containerContent,
	"ContainerDropdown",
	36,
	{"alfa", "charlie", "delta", "zulu", "x-ray", "select me!"},
	"delta",
	function(optionName)
		helloShown = optionName == "select me!"
		setRevealed("container_hello_toggle", helloBlock, helloShown)
		F.refreshGroupHeight()
	end
)

helloBlock = F.create("CanvasGroup", containerContent, {
	Name = "HelloToggleBlock",
	Position = UDim2.fromOffset(0, 70),
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 5,
})

createFeatureToggle(helloBlock, "HelloFeatureToggle", 0, "hello!")

local function setGroupTab(which)
	currentGroupTab = which
	local isFeatures = which == "features"
	featuresHeaderTab.TextColor3 = isFeatures and COLORS.Accent or COLORS.TabIdle
	containerHeaderTab.TextColor3 = isFeatures and COLORS.TabIdle or COLORS.Accent
	featuresContent.Visible = isFeatures
	containerContent.Visible = not isFeatures
	F.closeFeatureDropdowns()
	F.refreshGroupHeight()
end

featuresHeaderTab.Activated:Connect(function()
	setGroupTab("features")
end)

containerHeaderTab.Activated:Connect(function()
	setGroupTab("containertab!")
end)

local function addHeaderTabHover(button, tabName)
	button.MouseEnter:Connect(function()
		if currentGroupTab ~= tabName then
			button.TextColor3 = COLORS.TabHover
		end
	end)
	button.MouseLeave:Connect(function()
		if currentGroupTab ~= tabName then
			button.TextColor3 = COLORS.TabIdle
		end
	end)
end

addHeaderTabHover(featuresHeaderTab, "features")
addHeaderTabHover(containerHeaderTab, "containertab!")

setGroupTab("features")

-- ============================================================================
-- "extra feature" groupbox (right column) with a delayed hover tooltip.
-- ============================================================================

local extraFeatureGroup = F.create("Frame", otherFeaturesPage, {
	Name = "ExtraFeatureGroupBox",
	Position = UDim2.new(0.5, CONFIG.spacing * 0.5, 0, 16),
	Size = UDim2.new(0.5, -(CONFIG.spacing * 1.5), 0, 69),
	BackgroundColor3 = Color3.fromRGB(16, 16, 19),
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 3,
})
F.addCorner(extraFeatureGroup, 7)
F.addStroke(extraFeatureGroup)

local extraFeatureShadow = Instance.new("UIShadow")
extraFeatureShadow.Name = "GroupBoxShadow"
extraFeatureShadow.Color = Color3.fromRGB(0, 0, 0)
extraFeatureShadow.Transparency = 0.56
extraFeatureShadow.BlurRadius = UDim.new(0, 14)
extraFeatureShadow.Offset = UDim2.fromOffset(0, 4)
extraFeatureShadow.Spread = UDim2.fromOffset(0, 1)
extraFeatureShadow.ShowBehindParent = true
extraFeatureShadow.Parent = extraFeatureGroup

local extraFeatureTitle = F.makeText(
	extraFeatureGroup,
	"extra feature",
	UDim2.new(1, -(CONFIG.spacing * 2), 0, 18),
	UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing),
	12,
	COLORS.Muted,
	Enum.Font.GothamBold
)
extraFeatureTitle.ZIndex = 4

F.create("Frame", extraFeatureGroup, {
	Name = "HeaderDivider",
	Position = UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing + 18 + CONFIG.spacing),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 1),
	BackgroundColor3 = COLORS.Divider,
	BorderSizePixel = 0,
	ZIndex = 4,
})

local extraFeatureContent = F.create("Frame", extraFeatureGroup, {
	Name = "ExtraFeatureContent",
	Position = UDim2.fromOffset(CONFIG.spacing, CONFIG.spacing + 18 + CONFIG.spacing + 1 + CONFIG.spacing),
	Size = UDim2.new(1, -(CONFIG.spacing * 2), 0, 30),
	BackgroundTransparency = 1,
	ZIndex = 4,
})

local tooltipToggle = createFeatureToggle(extraFeatureContent, "TooltipToggle", 0, "i have a tooltip!")

local tooltipPanel = F.create("CanvasGroup", ScreenGui, {
	Name = "FeatureTooltip",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(220, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Color3.fromRGB(21, 21, 25),
	BackgroundTransparency = 0,
	GroupTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ClipsDescendants = false,
	ZIndex = 7000,
})
F.addCorner(tooltipPanel, 6)
F.addStroke(tooltipPanel)

F.create("UIPadding", tooltipPanel, {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 9),
	PaddingRight = UDim.new(0, 9),
})

F.create("UIListLayout", tooltipPanel, {
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	Padding = UDim.new(0, 5),
})

local tooltipTitle = F.makeText(
	tooltipPanel,
	"i have a tooltip!",
	UDim2.new(1, 0, 0, 0),
	UDim2.fromOffset(0, 0),
	13,
	Color3.fromRGB(255, 255, 255),
	Enum.Font.GothamBold
)
tooltipTitle.Name = "TooltipTitle"
tooltipTitle.TextWrapped = true
tooltipTitle.TextTruncate = Enum.TextTruncate.None
tooltipTitle.TextYAlignment = Enum.TextYAlignment.Top
tooltipTitle.AutomaticSize = Enum.AutomaticSize.Y
tooltipTitle.LayoutOrder = 1
tooltipTitle.ZIndex = 7001

local tooltipDescription = F.makeText(
	tooltipPanel,
	"this is a tooltip! you can write what ever text you want here!",
	UDim2.new(1, 0, 0, 0),
	UDim2.fromOffset(0, 0),
	12,
	COLORS.TabIdle,
	Enum.Font.GothamMedium
)
tooltipDescription.Name = "TooltipDescription"
tooltipDescription.TextWrapped = true
tooltipDescription.TextTruncate = Enum.TextTruncate.None
tooltipDescription.TextYAlignment = Enum.TextYAlignment.Top
tooltipDescription.AutomaticSize = Enum.AutomaticSize.Y
tooltipDescription.LayoutOrder = 2
tooltipDescription.ZIndex = 7001

local tooltipSettings = CONFIG.TOOLTIP_SETTINGS
local tooltipDelay = tooltipSettings.DELAY_BY_TOGGLE[tooltipToggle.row.Name]
	or tooltipSettings.DEFAULT_DELAY
local TOOLTIP_GAP = tooltipSettings.GAP
local TOOLTIP_WIDTH = tooltipSettings.WIDTH

local tooltipRevision = 0
local tooltipVisible = false
local tooltipHovering = false
local tooltipHoverToken = 0

local function getTooltipPointerPosition()
	local point = getPointerPosition()
	local origin = ScreenGui.AbsolutePosition
	-- TooltipPanel.Position is relative to ScreenGui, unlike AbsolutePosition.
	return Vector2.new(point.X - origin.X, point.Y - origin.Y)
end

local function positionFeatureTooltip()
	local point = getTooltipPointerPosition()
	local panelSize = tooltipPanel.AbsoluteSize
	local screenSize = ScreenGui.AbsoluteSize
	if screenSize.X <= 0 or screenSize.Y <= 0 then
		return
	end
	-- Prefer the bottom-right of the cursor. Keep that vertical direction;
	-- clamp to the viewport at the bottom edge instead of flipping above it.
	local x = point.X + TOOLTIP_GAP
	if x + panelSize.X > screenSize.X - 8 then
		x = math.max(8, point.X - panelSize.X - TOOLTIP_GAP)
	end
	local y = point.Y + TOOLTIP_GAP
	-- Keep the tooltip below the cursor even at the bottom screen edge.
	-- The viewport may clip the overflow rather than moving it above the cursor.
	tooltipPanel.Position = UDim2.fromOffset(x, y)
end

function F.hideFeatureTooltip()
	tooltipHovering = false
	tooltipHoverToken += 1
	if not tooltipVisible then
		return
	end
	tooltipVisible = false
	tooltipRevision += 1
	local revision = tooltipRevision
	local fadeTween = F.tween("feature_tooltip_fade", tooltipPanel, 0.14, {
		GroupTransparency = 1,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	fadeTween.Completed:Connect(function()
		if tooltipRevision == revision and not tooltipVisible then
			tooltipPanel.Visible = false
		end
	end)
end

local function showFeatureTooltip()
	if tooltipVisible or not tooltipHovering then
		return
	end
	tooltipVisible = true
	tooltipRevision += 1
	local screenSize = Root.AbsoluteSize
	local width = math.clamp(TOOLTIP_WIDTH, 140, math.max(140, screenSize.X - 24))
	tooltipPanel.Size = UDim2.fromOffset(width, 0)
	tooltipPanel.Visible = true
	tooltipPanel.GroupTransparency = 1
	positionFeatureTooltip()
	F.tween("feature_tooltip_fade", tooltipPanel, 0.16, {
		GroupTransparency = 0,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

tooltipToggle.row.MouseEnter:Connect(function()
	tooltipHovering = true
	tooltipHoverToken += 1
	local token = tooltipHoverToken
	task.delay(tooltipDelay, function()
		if tooltipHovering and tooltipHoverToken == token and not tooltipVisible then
			showFeatureTooltip()
		end
	end)
end)

tooltipToggle.row.MouseLeave:Connect(function()
	tooltipHovering = false
	tooltipHoverToken += 1
	F.hideFeatureTooltip()
end)

SERVICES.RunService.RenderStepped:Connect(function()
	if tooltipVisible then
		positionFeatureTooltip()
	end
end)

function F.setActivePage(name)
	local showNewFeatures = name == "new features"
	otherFeaturesPage.Visible = showNewFeatures
	helloGroupBox.Visible = not showNewFeatures
	rightGroupBox.Visible = not showNewFeatures
	secondGroupBox.Visible = not showNewFeatures
	F.closeFeatureDropdowns()
	F.setDropdownOpen(false)
	F.setToggleSettingsOpen(false)
	F.closeColorPicker()
	F.hideFeatureTooltip()
end

window:GetPropertyChangedSignal("Visible"):Connect(function()
	if not window.Visible then
		F.closeFeatureDropdowns()
		F.hideFeatureTooltip()
	end
end)

Root:GetPropertyChangedSignal("Visible"):Connect(function()
	if not Root.Visible then
		F.closeFeatureDropdowns()
		F.hideFeatureTooltip()
	end
end)

print(string.format("Midnight UI | %.2fs", os.clock() - scriptLoadStartTime))