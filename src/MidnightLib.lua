-- ============================================================================
-- MidnightLib
-- A reusable UI library for executor scripts. One loadstring entry, no
-- dependency on the demo menu it grew out of.
--
-- Public API:
--   Library:CreateWindow({ Title, Size, ToggleKey, Accent }) -> Window
--   Window:AddTab(name) -> Tab
--   Tab:AddGroupbox(name, side?) -> Groupbox       -- side: "Left"/"Right"
--   Groupbox:AddToggle(flag, opts)   -> control
--   Groupbox:AddSlider(flag, opts)   -> control
--   Groupbox:AddDropdown(flag, opts) -> control
--   Groupbox:AddKeybind(flag, opts)  -> control
--   Groupbox:AddButton(text, callback)
--   Groupbox:AddLabel(text)
--   Library:Notify(text) / Library:SetNotifySide(side)
--   Library:Unload()
--
-- Every control is stored by flag in Library.Toggles / Library.Options and
-- exposes .Value, :Get(), :Set(value) and :SetVisible(visible), so scripts
-- never dig through frames.
--
-- Re-running the loader unloads the previous instance automatically
-- (getgenv().MidnightLib). No prints unless Library.Debug = true.
-- ============================================================================

-- Re-execute guard: tear down a previously attached copy before rebuilding.
do
	local ok, existing = pcall(function()
		return getgenv().MidnightLib
	end)
	if ok and existing and typeof(existing.Unload) == "function" then
		existing:Unload()
	end
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {
	Debug = false,
	Toggles = {},
	Options = {},
	Windows = {},
	NotifySide = "Top center",
}

-- Cleanup registries ---------------------------------------------------------

local connections = {}
local tweens = {}
local instances = {}

local function track(instance)
	table.insert(instances, instance)
	return instance
end

local function connect(signal, handler)
	local connection = signal:Connect(handler)
	table.insert(connections, connection)
	return connection
end

local function tween(key, object, duration, properties, style, direction)
	local previous = tweens[key]
	if previous then
		previous:Cancel()
	end
	local created = TweenService:Create(
		object,
		TweenInfo.new(
			duration,
			style or Enum.EasingStyle.Quad,
			direction or Enum.EasingDirection.Out
		),
		properties
	)
	tweens[key] = created
	created:Play()
	return created
end

local function makeColors(accent)
	return {
		Background = Color3.fromRGB(13, 13, 15),
		Sidebar = Color3.fromRGB(11, 11, 13),
		Border = Color3.fromRGB(32, 32, 36),
		Divider = Color3.fromRGB(38, 38, 43),
		Title = Color3.fromRGB(230, 230, 235),
		Text = Color3.fromRGB(195, 195, 200),
		TextDim = Color3.fromRGB(140, 140, 148),
		Icon = Color3.fromRGB(160, 160, 168),
		RowHover = Color3.fromRGB(28, 28, 33),
		SelectBg = Color3.fromRGB(24, 24, 28),
		Accent = accent,
		AccentSoft = Color3.new(
			accent.R + (1 - accent.R) * 0.35,
			accent.G + (1 - accent.G) * 0.35,
			accent.B + (1 - accent.B) * 0.35
		),
	}
end

local COLORS = makeColors(Color3.fromRGB(70, 180, 255))

local function create(className, parent, props)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	instance.Parent = parent
	return track(instance)
end

local function addCorner(parent, radius)
	return create("UICorner", parent, {
		CornerRadius = UDim.new(0, radius or 6),
	})
end

local function addStroke(parent, color)
	return create("UIStroke", parent, {
		Color = color or COLORS.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function addList(parent, padding, direction)
	local layout = create("UIListLayout", parent, {
		Padding = UDim.new(0, padding or 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = direction or Enum.FillDirection.Vertical,
	})
	return layout
end

-- Shared row-order counter for groupbox rows. Monotonic across all
-- groupboxes: LayoutOrder only matters inside each body list, and a global
-- counter keeps rows in creation order even across decorators.
local rowOrderCounter = 0

local function nextRowOrder()
	rowOrderCounter = rowOrderCounter + 1
	return rowOrderCounter
end

-- ============================================================================
-- Notifications (optional module; Library:Notify is the only entry point)
-- ============================================================================

local NOTIFY_FADE = 0.22
local NOTIFY_HOLD = 2.5
local NOTIFY_EXIT = 0.26
local NOTIFY_WIDTH = 260

local notifyGui
local notifyOrder = 0
local notifyContainers = {}

local function notifyContainer(side)
	if notifyContainers[side] then
		return notifyContainers[side]
	end
	if not notifyGui then
		notifyGui = create("ScreenGui", PlayerGui, {
			Name = "MidnightLibNotifications",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 1000000,
		})
	end
	local anchor, position
	if side == "Top left" then
		anchor, position = Vector2.new(0, 0), UDim2.fromOffset(16, 16)
	elseif side == "Top center" then
		anchor, position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 16)
	elseif side == "Top right" then
		anchor, position = Vector2.new(1, 0), UDim2.new(1, -16, 0, 16)
	elseif side == "Bottom left" then
		anchor, position = Vector2.new(0, 1), UDim2.new(0, 16, 1, -16)
	elseif side == "Bottom center" then
		anchor, position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -16)
	else -- "Bottom right"
		anchor, position = Vector2.new(1, 1), UDim2.new(1, -16, 1, -16)
	end
	local container = create("Frame", notifyGui, {
		Name = "Notify_" .. side,
		AnchorPoint = anchor,
		Position = position,
		Size = UDim2.fromOffset(NOTIFY_WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	addList(container, 8)
	notifyContainers[side] = container
	return container
end

function Library:SetNotifySide(side)
	if notifyContainers[side] then
		Library.NotifySide = side
	end
end

function Library:Notify(text)
	local container = notifyContainer(Library.NotifySide)
	notifyOrder = notifyOrder + 1

	local group = create("CanvasGroup", container, {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(10, 10, 12),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		LayoutOrder = notifyOrder,
	})
	addCorner(group, 6)
	addStroke(group, COLORS.Border)

	create("TextLabel", group, {
		Name = "Text",
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = tostring(text),
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(235, 235, 240),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local barAnchor = create("Frame", group, {
		Name = "BarTrack",
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundTransparency = 1,
	})
	local bar = create("Frame", barAnchor, {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -16, 0, 2),
		BackgroundColor3 = COLORS.Accent,
		BorderSizePixel = 0,
	})
	addCorner(bar, 1)

	local scale = create("UIScale", group, { Scale = 0.86 })
	tween("notify_in", group, NOTIFY_FADE, { GroupTransparency = 0 })
	tween("notify_scale", scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

	tween("notify_bar", bar, NOTIFY_HOLD + NOTIFY_FADE, {
		Size = UDim2.new(0, 0, 0, 2),
	}, Enum.EasingStyle.Linear)

	task.delay(NOTIFY_HOLD + NOTIFY_FADE, function()
		if not group.Parent then
			return
		end
		tween("notify_out", group, NOTIFY_EXIT, {
			GroupTransparency = 1,
			Size = UDim2.new(1, -12, 0, 0),
		})
		local out = tween("notify_scale_out", scale, NOTIFY_EXIT, { Scale = 0.9 })
		out.Completed:Once(function()
			group:Destroy()
		end)
	end)
end


-- ============================================================================
-- Window
-- ============================================================================

-- CanvasGroups rasterize into a quality-capped texture; past roughly this
-- size the whole window goes blurry. Larger windows fall back to a plain
-- Frame (crisp at any size) with an instant visibility toggle instead of a
-- group fade.
local WINDOW_TEXTURE_LIMIT = 1024

local function dragFrame(handle, target, clampToParent)
	local dragging = false
	local dragStart, startPos

	connect(handle.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = target.Position
	end)

	connect(handle.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local delta = input.Position - dragStart
		local newX = startPos.X.Offset + delta.X
		local newY = startPos.Y.Offset + delta.Y
		if clampToParent then
			local parentSize = target.Parent.AbsoluteSize
			newX = math.clamp(newX, -target.AbsoluteSize.X + 60, parentSize.X - 60)
			newY = math.clamp(newY, 0, parentSize.Y - 40)
		end
		target.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
	end)
end

function Library:CreateWindow(opts)
	opts = opts or {}
	local accent = typeof(opts.Accent) == "Color3" and opts.Accent
		or Color3.fromRGB(70, 180, 255)
	local colors = makeColors(accent)
	local windowSize = opts.Size or Vector2.new(600, 400)
	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	local title = opts.Title or "Midnight Lib"
	local groupFade = windowSize.X <= WINDOW_TEXTURE_LIMIT
		and windowSize.Y <= WINDOW_TEXTURE_LIMIT

	local ScreenGui = create("ScreenGui", PlayerGui, {
		Name = "MidnightLib",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 99,
	})

	local window = create(groupFade and "CanvasGroup" or "Frame", ScreenGui, {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		BackgroundColor3 = colors.Background,
		BorderSizePixel = 0,
	})
	if groupFade then
		window.GroupTransparency = 0
	end
	addCorner(window, 8)
	addStroke(window, colors.Border)

	-- Title bar ------------------------------------------------------------
	local titleBar = create("TextButton", window, {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = colors.Background,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	local titleHolder = create("Frame", titleBar, {
		Name = "TitleHolder",
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -70, 1, 0),
		BackgroundTransparency = 1,
	})
	local titleText = create("TextLabel", titleHolder, {
		Name = "Title",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextSize = 14,
		TextColor3 = colors.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	dragFrame(titleBar, window, true)

	-- Layout: sidebar + content -------------------------------------------
	local sidebar = create("Frame", window, {
		Name = "Sidebar",
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(0, 142, 1, -36),
		BackgroundColor3 = colors.Sidebar,
		BorderSizePixel = 0,
	})
	addList(sidebar, 2)
	create("UIPadding", sidebar, { PaddingTop = UDim.new(0, 6) })

	local content = create("Frame", window, {
		Name = "Content",
		Position = UDim2.fromOffset(142, 36),
		Size = UDim2.new(1, -142, 1, -36),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})

	local windowObject = {}
	windowObject.ScreenGui = ScreenGui
	windowObject.Tabs = {}

	function windowObject:SetVisible(visible)
		visible = visible and true or false
		ScreenGui.Enabled = visible
		if not groupFade then
			return
		end
		if visible then
			window.GroupTransparency = 1
			tween("win_fade", window, 0.14, { GroupTransparency = 0 })
		else
			local fade = tween("win_fade", window, 0.14, { GroupTransparency = 1 })
			fade.Completed:Once(function()
				ScreenGui.Enabled = false
				window.GroupTransparency = 0
			end)
		end
	end

	function windowObject:GetVisible()
		return ScreenGui.Enabled
	end

	connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == toggleKey then
			windowObject:SetVisible(not ScreenGui.Enabled)
		end
	end)

	function windowObject:AddTab(name)
		local page = create("Frame", content, {
			Name = "Tab_" .. name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
		})
		-- Two columns, laid out by the list layouts; groupboxes size
		-- themselves from their content (AutomaticSize), no magic numbers.
		local columns = {}
		for index, side in ipairs({ "Left", "Right" }) do
			local column = create("Frame", page, {
				Name = side .. "Column",
				Position = index == 1 and UDim2.fromOffset(10, 10)
					or UDim2.new(1, -10, 0, 10),
				Size = UDim2.new(0.5, index == 1 and -13 or -13, 1, -20),
				BackgroundTransparency = 1,
			})
			create("UIPadding", column, { PaddingRight = index == 1 and UDim.new(0, 3) or UDim.new(0, 0) })
			addList(column, 8)
			columns[side] = column
		end

		local tabButton = create("TextButton", sidebar, {
			Name = "TabButton_" .. name,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = colors.SelectBg,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = name,
			TextSize = 13,
			TextColor3 = colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		create("UIPadding", tabButton, {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 8),
		})
		addCorner(tabButton, 5)

		local tab = { Pages = { Left = columns.Left, Right = columns.Right } }
		windowObject.Pages = windowObject.Pages or {}
		windowObject.TabButtons = windowObject.TabButtons or {}
		local tabIndex = #windowObject.Pages + 1
		windowObject.Pages[tabIndex] = page
		windowObject.TabButtons[tabIndex] = tabButton

		local function selectTab()
			for index, otherPage in ipairs(windowObject.Pages) do
				otherPage.Visible = index == tabIndex
			end
			for index, otherButton in ipairs(windowObject.TabButtons) do
				local selected = index == tabIndex
				otherButton.BackgroundTransparency = selected and 0 or 1
				otherButton.TextColor3 = selected and colors.Title or colors.TextDim
			end
		end
		tab.Select = selectTab

		connect(tabButton.MouseButton1Click, function()
			selectTab()
		end)

		if tabIndex == 1 then
			selectTab()
		end

		function tab:AddGroupbox(name, side)
			local column = columns[side == "Right" and "Right" or "Left"]

			local group = create("Frame", column, {
				Name = "Groupbox_" .. name,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = colors.Sidebar,
				BorderSizePixel = 0,
			})
			addCorner(group, 6)
			addStroke(group, colors.Border)

			local header = create("TextButton", group, {
				Name = "Header",
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamSemibold,
				Text = name,
				TextSize = 12,
				TextColor3 = colors.Title,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
			})
			create("UIPadding", header, {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			})

			local body = create("Frame", group, {
				Name = "Body",
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			})
			addList(body, 5)
			create("UIPadding", body, {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			})

			local collapsed = false
			connect(header.MouseButton1Click, function()
				collapsed = not collapsed
				body.Visible = not collapsed
			end)

			local groupBox = {}
			groupBox.Header = header
			groupBox.Body = body

			function groupBox:SetVisible(visible)
				group.Visible = visible and true or false
			end

			function groupBox:SetCollapsed(collapsedState)
				collapsed = collapsedState and true or false
				body.Visible = not collapsed
			end

			-- Controls (toggle/slider/...) are attached by the library core
			-- once it is defined below; the hook keeps AddGroupbox free of
			-- per-control code.
			if Library._decorateGroupbox then
				Library._decorateGroupbox(groupBox, body, colors)
			end

			return groupBox, body
		end

		return tab
	end

	Library.Windows[#Library.Windows + 1] = windowObject
	return windowObject
end


-- ============================================================================
-- Controls
-- ============================================================================

-- Shared row scaffolding: a fixed-height button row inside a groupbox body.
local function addRow(body, height, order)
	local row = create("TextButton", body, {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, height or 24),
		BackgroundColor3 = COLORS.RowHover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order or 0,
	})
	addCorner(row, 4)
	return row
end

local function rowLabel(row, text, size, color)
	return create("TextLabel", row, {
		Name = "Label",
		Position = UDim2.fromOffset(8, 0),
		Size = size or UDim2.new(1, -16, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 13,
		TextColor3 = color or COLORS.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end

local function registerControl(control, flag, initialValue)
	control.flag = flag
	control.Value = initialValue
	Library.Toggles[flag] = control
	Library.Options[flag] = control

	function control:Get()
		return control.Value
	end

	function control:SetVisible(visible)
		control.Row.Visible = visible and true or false
	end

	return control
end

Library._decorateGroupbox = function(groupBox, body, colors)
	local function nextOrder()
		return nextRowOrder()
	end

	function groupBox:AddLabel(text)
		local row = addRow(body, 20, nextOrder())
		row.Active = false
		local label = rowLabel(row, tostring(text))
		label.TextColor3 = colors.Title
		local control = { Row = row, Label = label, Text = label }
		function control:SetText(newText)
			label.Text = tostring(newText)
		end
		return control
	end

	function groupBox:AddButton(text, callback)
		local row = addRow(body, 24, nextOrder())
		rowLabel(row, tostring(text))
		row.MouseEnter:Connect(function()
			row.BackgroundTransparency = 0.4
		end)
		row.MouseLeave:Connect(function()
			row.BackgroundTransparency = 1
		end)
		row.MouseButton1Click:Connect(function()
			if typeof(callback) == "function" then
				callback()
			end
		end)
		local control = { Row = row }
		function control:SetText(newText)
			row:FindFirstChildOfClass("TextLabel").Text = tostring(newText)
		end
		return control
	end

	function groupBox:AddToggle(flag, opts)
		opts = opts or {}
		local row = addRow(body, 24, nextOrder())
		rowLabel(row, opts.Text or flag)
		local accent = opts.Accent or colors.Accent

		local pill = create("Frame", row, {
			Name = "Pill",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(34, 18),
			BackgroundColor3 = COLORS.SelectBg,
			BorderSizePixel = 0,
		})
		addCorner(pill, 9)
		local knob = create("Frame", pill, {
			Name = "Knob",
			Position = UDim2.new(0, 2, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = COLORS.TextDim,
			BorderSizePixel = 0,
		})
		addCorner(knob, 7)

		local control = { Row = row }
		registerControl(control, flag, opts.Default and true or false)

		local function render(instant)
			local on = control.Value
			pill.BackgroundColor3 = on and accent or COLORS.SelectBg
			if instant then
				knob.Position = on
					and UDim2.new(1, -16, 0.5, 0)
					or UDim2.new(0, 2, 0.5, 0)
				knob.BackgroundColor3 = on and colors.Background or COLORS.TextDim
				return
			end
			tween("toggle_pill_" .. flag, pill, 0.14, { BackgroundColor3 = on and accent or COLORS.SelectBg })
			tween("toggle_knob_" .. flag, knob, 0.14, {
				Position = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				BackgroundColor3 = on and colors.Background or COLORS.TextDim,
			})
		end

		function control:Set(value, silent)
			control.Value = value and true or false
			render(silent == true)
			if not silent and typeof(opts.Callback) == "function" then
				opts.Callback(control.Value)
			end
		end

		row.MouseButton1Click:Connect(function()
			control:Set(not control.Value)
		end)
		render(true)
		if control.Value then
			control:Set(control.Value, true)
		end
		return control
	end

	function groupBox:AddSlider(flag, opts)
		opts = opts or {}
		local minimum = opts.Min or 0
		local maximum = opts.Max or 100
		local row = addRow(body, 40, nextOrder())
		local label = rowLabel(row, opts.Text or flag, UDim2.new(1, -60, 0, 18))
		local valueText = create("TextLabel", row, {
			Name = "Value",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 0),
			Size = UDim2.fromOffset(52, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "0",
			TextSize = 12,
			TextColor3 = colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		local track = create("Frame", row, {
			Name = "Track",
			Position = UDim2.fromOffset(8, 24),
			Size = UDim2.new(1, -16, 0, 4),
			BackgroundColor3 = COLORS.SelectBg,
			BorderSizePixel = 0,
		})
		addCorner(track, 2)
		local fill = create("Frame", track, {
			Name = "Fill",
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = opts.Accent or colors.Accent,
			BorderSizePixel = 0,
		})
		addCorner(fill, 2)

		local control = { Row = row, Label = label, ValueLabel = valueText }
		registerControl(control, flag, opts.Default or minimum)

		local function render()
			local alpha = (control.Value - minimum) / math.max(1e-6, maximum - minimum)
			alpha = math.clamp(alpha, 0, 1)
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			local shown = math.floor(control.Value + 0.5)
			valueText.Text = tostring(shown)
		end

		function control:Set(value, silent)
			control.Value = math.clamp(tonumber(value) or minimum, minimum, maximum)
			render()
			if not silent and typeof(opts.Callback) == "function" then
				opts.Callback(control.Value)
			end
		end

		local sliding = false
		local function applyFromPoint(point)
			local position = track.AbsolutePosition
			local size = track.AbsoluteSize
			local alpha = math.clamp((point.X - position.X) / math.max(1, size.X), 0, 1)
			control:Set(minimum + (maximum - minimum) * alpha)
		end

		connect(track.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				sliding = true
				applyFromPoint(input.Position)
			end
		end)
		connect(track.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				sliding = false
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if not sliding then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				applyFromPoint(input.Position)
			end
		end)

		control:Set(control.Value, true)
		return control
	end

	return groupBox
end


-- Dropdown + keybind controls. This decorator WRAPS the base one from the
-- controls chunk above (toggle/slider/button/label) so every groupbox gets
-- the full control set from a single Library._decorateGroupbox call.

local baseDecorateGroupbox = Library._decorateGroupbox

Library._decorateGroupbox = function(groupBox, body, colors)
	baseDecorateGroupbox(groupBox, body, colors)

	local function nextOrder()
		return nextRowOrder()
	end

	function groupBox:AddDropdown(flag, opts)
		opts = opts or {}
		local options = opts.Options or {}
		local row = addRow(body, 24, nextOrder())
		rowLabel(row, opts.Text or flag, UDim2.new(1, -70, 1, 0))
		local valueText = create("TextLabel", row, {
			Name = "Value",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -24, 0, 0),
			Size = UDim2.fromOffset(60, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "Select...",
			TextSize = 12,
			TextColor3 = colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		create("TextLabel", row, {
			Name = "Arrow",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "v",
			TextSize = 10,
			TextColor3 = colors.Icon,
		})

		local screenGui = body:FindFirstAncestorOfClass("ScreenGui")

		local popup = create("CanvasGroup", screenGui, {
			Name = "DropdownPopup_" .. flag,
			Visible = false,
			Size = UDim2.fromOffset(140, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = colors.Background,
			BorderSizePixel = 0,
			ZIndex = 50,
		})
		addCorner(popup, 6)
		addStroke(popup, COLORS.Border)
		local popupList = addList(popup, 2)
		create("UIPadding", popup, {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		})

		local control = { Row = row, ValueLabel = valueText, Options = options }
		registerControl(control, flag, opts.Default)

		local function render()
			valueText.Text = tostring(control.Value or "Select...")
			for _, child in ipairs(popup:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundTransparency = child.Text == control.Value and 0 or 1
				end
			end
		end

		local function rebuildPopup()
			for _, child in ipairs(popup:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("UIListLayout") then
					child:Destroy()
				end
			end
			addList(popup, 2)
			for _, option in ipairs(options) do
				local optionButton = create("TextButton", popup, {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = colors.SelectBg,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = Enum.Font.GothamMedium,
					Text = tostring(option),
					TextSize = 12,
					TextColor3 = colors.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
				})
				create("UIPadding", optionButton, { PaddingLeft = UDim.new(0, 8) })
				addCorner(optionButton, 4)
				optionButton.MouseEnter:Connect(function()
					optionButton.BackgroundTransparency = 0.35
				end)
				optionButton.MouseLeave:Connect(function()
					optionButton.BackgroundTransparency = optionButton.Text == control.Value and 0 or 1
				end)
				optionButton.MouseButton1Click:Connect(function()
					control:Set(option)
					popup.Visible = false
				end)
			end
		end
		rebuildPopup()

		function control:RefreshOptions(newOptions)
			options = newOptions or {}
			control.Options = options
			rebuildPopup()
			if control.Value ~= nil and not table.find(options, control.Value) then
				control:Set(nil, true)
			end
		end

		function control:Set(value, silent)
			control.Value = value
			render()
			if not silent and typeof(opts.Callback) == "function" then
				opts.Callback(control.Value)
			end
		end

		local function positionPopup()
			local absolute = row.AbsolutePosition
			popup.Position = UDim2.fromOffset(
				absolute.X + row.AbsoluteSize.X - 140,
				absolute.Y + row.AbsoluteSize.Y + 4
			)
		end

		row.MouseButton1Click:Connect(function()
			positionPopup()
			popup.Visible = not popup.Visible
		end)

		connect(UserInputService.InputBegan, function(input, gameProcessed)
			if not popup.Visible or gameProcessed then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local point = input.Position
			local inRow = row.AbsolutePosition
				and point.X >= row.AbsolutePosition.X
				and point.X <= row.AbsolutePosition.X + row.AbsoluteSize.X
				and point.Y >= row.AbsolutePosition.Y
				and point.Y <= row.AbsolutePosition.Y + row.AbsoluteSize.Y
			local inPopup = point.X >= popup.AbsolutePosition.X
				and point.X <= popup.AbsolutePosition.X + popup.AbsoluteSize.X
				and point.Y >= popup.AbsolutePosition.Y
				and point.Y <= popup.AbsolutePosition.Y + popup.AbsoluteSize.Y
			if not inRow and not inPopup then
				popup.Visible = false
			end
		end)

		control:Set(opts.Default, true)
		return control
	end

	function groupBox:AddKeybind(flag, opts)
		opts = opts or {}
		local row = addRow(body, 24, nextOrder())
		rowLabel(row, opts.Text or flag, UDim2.new(1, -70, 1, 0))
		local keyText = create("TextButton", row, {
			Name = "Key",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(60, 18),
			BackgroundColor3 = COLORS.SelectBg,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = "...",
			TextSize = 11,
			TextColor3 = colors.TextDim,
			AutoButtonColor = false,
		})
		addCorner(keyText, 4)

		local control = { Row = row }
		registerControl(control, flag, opts.Default)

		local capturing = false
		local captureConnection

		local function keyName(keyCode)
			if not keyCode then
				return "..."
			end
			return keyCode.Name == "Unknown" and "..." or keyCode.Name
		end

		local function stopCapture()
			capturing = false
			keyText.Text = keyName(control.Value)
			keyText.TextColor3 = colors.TextDim
			if captureConnection then
				captureConnection:Disconnect()
				captureConnection = nil
			end
		end

		function control:Set(value, silent)
			control.Value = value
			keyText.Text = keyName(value)
			if not silent and typeof(opts.Callback) == "function" then
				opts.Callback(value)
			end
		end

		connect(keyText.MouseButton1Click, function()
			if capturing then
				stopCapture()
				return
			end
			capturing = true
			keyText.Text = "Press..."
			keyText.TextColor3 = colors.Accent
			captureConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape then
						stopCapture()
					else
						stopCapture()
						control:Set(input.KeyCode)
					end
				end
			end)
		end)

		connect(UserInputService.InputBegan, function(input, gameProcessed)
			if capturing or gameProcessed or not control.Value then
				return
			end
			if input.KeyCode == control.Value
				and not UserInputService:GetFocusedTextBox()
				and typeof(opts.Callback) == "function" then
				opts.Callback(control.Value)
			end
		end)

		control:Set(opts.Default, true)
		return control
	end

	return groupBox
end

-- ============================================================================
-- Unload
-- ============================================================================

function Library:Unload()
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)

	for key, tweenObject in pairs(tweens) do
		pcall(function()
			tweenObject:Cancel()
		end)
		tweens[key] = nil
	end

	for _, instance in ipairs(instances) do
		pcall(function()
			instance:Destroy()
		end)
	end
	table.clear(instances)

	table.clear(Library.Toggles)
	table.clear(Library.Options)
	Library.Windows = {}

	if getgenv().MidnightLib == Library then
		getgenv().MidnightLib = nil
	end
end

getgenv().MidnightLib = Library

return Library
