-- UI.lua — оболочка окна, темы и набор компонентов (кнопки, чипы, слайдеры, карточки, модальные окна)
local Ctx = ...
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Settings, Catalog, Inv = Ctx.Settings, Ctx.Catalog, Ctx.Inventory

local UI = {}
local MIN_W, MIN_H, TITLE_H = 320, 250, 40
local NONE, AUTO_Y, AUTO_X = Enum.AutomaticSize.None, Enum.AutomaticSize.Y, Enum.AutomaticSize.X
UI.CARD_H, UI.CARD_HA = 158, 192
UI.curScale = 1
UI.state = { minimized = false, hidden = false, tab = "inv" }

local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local function mk(t)
	t.good, t.bad, t.warn = C(64, 196, 120), C(235, 87, 87), C(240, 180, 70)
	return t
end
UI.themes = {
	dark     = mk({ name = "Тёмная",      bg = C(18, 19, 24),  side = C(13, 14, 18),  panel = C(27, 29, 37),  panel2 = C(38, 41, 52),  accent = C(110, 95, 255), text = C(240, 242, 248), sub = C(148, 154, 172), stroke = C(50, 54, 68) }),
	midnight = mk({ name = "Полночь",     bg = C(12, 17, 28),  side = C(9, 13, 22),   panel = C(20, 28, 44),  panel2 = C(30, 42, 64),  accent = C(56, 152, 255), text = C(236, 242, 250), sub = C(140, 158, 186), stroke = C(38, 54, 80) }),
	graphite = mk({ name = "Графит",      bg = C(24, 24, 24),  side = C(17, 17, 17),  panel = C(34, 34, 34),  panel2 = C(48, 48, 48),  accent = C(60, 200, 140), text = C(238, 238, 238), sub = C(160, 160, 160), stroke = C(62, 62, 62) }),
	light    = mk({ name = "Светлая",     bg = C(242, 243, 247), side = C(228, 230, 237), panel = C(255, 255, 255), panel2 = C(231, 233, 241), accent = C(96, 80, 240), text = C(28, 30, 40), sub = C(100, 106, 124), stroke = C(205, 208, 220) }),
}
UI.themeOrder = { "dark", "midnight", "graphite", "light" }
UI.T = UI.themes.dark

local conns, cleanups, permConns = {}, {}, {}
local function track(c) conns[#conns + 1] = c return c end
function UI.cleanup(fn) cleanups[#cleanups + 1] = fn end

local function new(class, props, parent)
	local o = Instance.new(class)
	if props then for k, v in pairs(props) do o[k] = v end end
	if parent then o.Parent = parent end
	return o
end
UI.new = new

local function esc(s)
	s = tostring(s):gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end
UI.esc = esc
local function rgbStr(c)
	return string.format("rgb(%d,%d,%d)", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
UI.rgbStr = rgbStr

---------------------------------------------------------------- базовые элементы
function UI.corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end
function UI.stroke(o, color, th)
	return new("UIStroke", { Color = color or UI.T.stroke, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
function UI.pad(o, l, t, r, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or l or 0),
		PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or l or 0),
	}, o)
end
function UI.list(o, gap)
	return new("UIListLayout", { Padding = UDim.new(0, gap or 6), SortOrder = Enum.SortOrder.LayoutOrder }, o)
end
function UI.frame(parent, props)
	local p = { BorderSizePixel = 0, BackgroundColor3 = UI.T.panel }
	for k, v in pairs(props or {}) do p[k] = v end
	return new("Frame", p, parent)
end
function UI.clear(parent)
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end
function UI.label(parent, text, props)
	local p = {
		BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamMedium, TextSize = 14,
		TextColor3 = UI.T.text, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
	}
	for k, v in pairs(props or {}) do p[k] = v end
	return new("TextLabel", p, parent)
end

function UI.tween(o, props, t, style)
	if not Settings.get("animations") then
		for k, v in pairs(props) do o[k] = v end
		return nil
	end
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

function UI.heading(parent, text, subtitle)
	local h = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y }, parent)
	UI.list(h, 2)
	UI.label(h, text, { Font = Enum.Font.GothamBold, TextSize = 20 })
	if subtitle then UI.label(h, subtitle, { TextSize = 12, TextColor3 = UI.T.sub }) end
	return h
end

function UI.panel(parent, title, order)
	local p = new("Frame", {
		BackgroundColor3 = UI.T.panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y, LayoutOrder = order or 0,
	}, parent)
	UI.corner(p, 10); UI.stroke(p); UI.pad(p, 10); UI.list(p, 8)
	if title then UI.label(p, title, { Font = Enum.Font.GothamBold, TextSize = 15 }) end
	return p
end

function UI.scroll(parent)
	local s = new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4, ScrollBarImageColor3 = UI.T.sub,
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
	}, parent)
	UI.list(s, 10); UI.pad(s, 12, 12, 14, 24)
	return s
end

---------------------------------------------------------------- кнопки и ввод
function UI.setBase(b, color)
	b:SetAttribute("base", color)
	b.BackgroundColor3 = color
end

function UI.setEnabled(b, on)
	b.Active = on
	b.TextTransparency = on and 0 or 0.55
	b.BackgroundTransparency = on and 0 or 0.5
end

function UI.button(parent, text, cb, opts)
	opts = opts or {}
	local T = UI.T
	local h = opts.height or 36
	local b = new("TextButton", {
		Text = text, Font = Enum.Font.GothamSemibold, TextSize = opts.textSize or 14,
		TextColor3 = opts.textColor or T.text, BackgroundColor3 = opts.color or T.panel2,
		BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = opts.order or 0,
		Size = opts.size or (opts.autosize and UDim2.fromOffset(0, h) or UDim2.new(1, 0, 0, h)),
		AutomaticSize = opts.autosize and AUTO_X or NONE,
	}, parent)
	b:SetAttribute("base", b.BackgroundColor3)
	UI.corner(b, opts.radius or 8)
	if opts.autosize then UI.pad(b, opts.padX or 12, 0, opts.padX or 12, 0) end
	local function to(c) UI.tween(b, { BackgroundColor3 = c }, 0.12) end
	local function isPress(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end
	b.MouseEnter:Connect(function() to(b:GetAttribute("base"):Lerp(Color3.new(1, 1, 1), 0.12)) end)
	b.MouseLeave:Connect(function() to(b:GetAttribute("base")) end)
	b.InputBegan:Connect(function(i) if isPress(i) then to(b:GetAttribute("base"):Lerp(Color3.new(0, 0, 0), 0.2)) end end)
	b.InputEnded:Connect(function(i) if isPress(i) then to(b:GetAttribute("base")) end end)
	b.Activated:Connect(function()
		if cb then
			local ok, e = pcall(cb)
			if not ok then
				warn("[ADOPT ME ULTIMATE] " .. tostring(e))
				UI.toast("Ошибка: " .. tostring(e), "bad")
			end
		end
	end)
	return b
end

function UI.chips(parent, options, value, cb, opts)
	opts = opts or {}
	local T = UI.T
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local btns, colors, cur = {}, {}, value
	local function paint()
		for id, b in pairs(btns) do
			local on = (id == cur)
			UI.setBase(b, on and T.accent or T.panel2)
			b.TextColor3 = on and Color3.new(1, 1, 1) or (colors[id] or T.text)
		end
	end
	for i, o in ipairs(options) do
		local id = type(o) == "table" and o.id or o
		local label = type(o) == "table" and (o.label or o.id) or o
		local b = UI.button(holder, tostring(label), function()
			cur = id
			paint()
			if cb then cb(id) end
		end, { autosize = true, height = opts.height or 32, order = i, textSize = 13 })
		btns[id] = b
		if type(o) == "table" and o.color then colors[id] = o.color end
	end
	paint()
	return { frame = holder, get = function() return cur end, set = function(v) cur = v paint() end }
end

function UI.toggleChip(parent, text, value, cb)
	local T = UI.T
	local state = value and true or false
	local b
	local function paint()
		UI.setBase(b, state and T.accent or T.panel2)
		b.TextColor3 = state and Color3.new(1, 1, 1) or T.text
	end
	b = UI.button(parent, text, function() state = not state paint() if cb then cb(state) end end,
		{ autosize = true, height = 32, textSize = 13 })
	paint()
	return { frame = b, get = function() return state end, set = function(v) state = v and true or false paint() end }
end

function UI.input(parent, placeholder, opts)
	opts = opts or {}
	local T = UI.T
	local f = new("Frame", { BackgroundColor3 = T.panel2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, opts.height or 38), LayoutOrder = opts.order or 0 }, parent)
	UI.corner(f, 8)
	local st = UI.stroke(f, T.stroke)
	local box = new("TextBox", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
		Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = T.text, PlaceholderText = placeholder or "",
		PlaceholderColor3 = T.sub, Text = opts.text or "", TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, MaxVisibleGraphemes = -1,
	}, f)
	if opts.maxLength then box.MaxLength = opts.maxLength end
	box.Focused:Connect(function() st.Color = T.accent end)
	box.FocusLost:Connect(function(enter)
		st.Color = T.stroke
		if opts.onEnter then opts.onEnter(box.Text, enter) end
	end)
	if opts.numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local t = box.Text:gsub("[^%d]", "")
			if t ~= box.Text then box.Text = t end
		end)
	end
	if opts.onChanged then
		box:GetPropertyChangedSignal("Text"):Connect(function() opts.onChanged(box.Text) end)
	end
	return { frame = f, box = box, get = function() return box.Text end, set = function(t) box.Text = t end }
end

function UI.toggle(parent, text, value, cb)
	local T = UI.T
	local row = new("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 38) }, parent)
	UI.label(row, text, { Size = UDim2.new(1, -60, 1, 0), AutomaticSize = NONE })
	local pill = new("Frame", { BackgroundColor3 = T.panel2, BorderSizePixel = 0, Size = UDim2.fromOffset(44, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) }, row)
	UI.corner(pill, 12)
	local knob = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0) }, pill)
	UI.corner(knob, 9)
	local state = value and true or false
	local function apply(v)
		state = v and true or false
		UI.tween(pill, { BackgroundColor3 = state and T.accent or T.panel2 }, 0.15)
		UI.tween(knob, { Position = UDim2.new(0, state and 23 or 3, 0.5, 0) }, 0.15)
	end
	row.Activated:Connect(function()
		apply(not state)
		if cb then cb(state) end
	end)
	apply(state)
	return { set = apply, get = function() return state end }
end

---------------------------------------------------------------- перетаскивание
-- onStart(pos), onMove(delta, pos), onEnd()
local function makeDrag(handle, onStart, onMove, onEnd)
	local dragging, dragInput, origin = false, nil, Vector2.zero
	handle.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging, dragInput = true, input
			origin = Vector2.new(input.Position.X, input.Position.Y)
			if onStart then onStart(origin) end
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End and dragging then
					dragging = false
					if onEnd then onEnd() end
				end
			end)
		end
	end)
	track(UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			onMove(p - origin, p)
		end
	end))
end

function UI.slider(parent, text, min, max, value, step, cb, fmt)
	local T = UI.T
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54) }, parent)
	UI.label(row, text, { Size = UDim2.new(1, -70, 0, 20), AutomaticSize = NONE })
	local val = UI.label(row, "", { Size = UDim2.new(0, 70, 0, 20), Position = UDim2.new(1, -70, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, AutomaticSize = NONE, TextColor3 = T.sub })
	local hit = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 22), Active = true }, row)
	local bar = new("Frame", { BackgroundColor3 = T.panel2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0.5, -4) }, hit)
	UI.corner(bar, 4)
	local fill = new("Frame", { BackgroundColor3 = T.accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0) }, bar)
	UI.corner(fill, 4)
	local knob = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, bar)
	UI.corner(knob, 10)
	local current = value
	local function setV(v, fire)
		v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
		current = v
		local a = (v - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		val.Text = fmt and fmt(v) or tostring(v)
		if fire and cb then cb(v, false) end
	end
	local function fromX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		setV(min + a * (max - min), true)
	end
	makeDrag(hit, function(p) fromX(p.X) end, function(_, p) fromX(p.X) end, function() if cb then cb(current, true) end end)
	setV(value, false)
	return { set = function(v) setV(v, false) end }
end

---------------------------------------------------------------- сетка и карточки питомцев
function UI.grid(parent, minW, cellH)
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y }, parent)
	local g = new("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8), CellSize = UDim2.new(1, 0, 0, cellH),
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, holder)
	local function upd()
		local w = holder.AbsoluteSize.X / math.max(UI.curScale, 0.1)
		if w <= 0 then return end
		local cols = math.max(1, math.floor((w + 8) / (minW + 8)))
		g.CellSize = UDim2.new(1 / cols, -math.ceil(8 * (cols - 1) / cols), 0, cellH)
	end
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(upd)
	upd()
	return holder
end

function UI.row(parent, title, subtitle, order, rightW)
	local T = UI.T
	rightW = rightW or 0
	local row = new("Frame", { BackgroundColor3 = T.panel2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = order or 0 }, parent)
	UI.corner(row, 8)
	new("TextLabel", {
		BackgroundTransparency = 1, RichText = true, Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -(rightW + 20), 1, 0),
		Text = "<b>" .. esc(title) .. "</b>\n<font size=\"11\" color=\"" .. rgbStr(T.sub) .. "\">" .. esc(subtitle or "") .. "</font>",
	}, row)
	local right = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, rightW, 0, 30) }, row)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, right)
	return row, right
end

local function initials(name)
	local s = ""
	for w in tostring(name):gmatch("%S+") do
		s = s .. w:sub(1, 1):upper()
		if #s >= 2 then break end
	end
	return s ~= "" and s or "?"
end

local function dot(parent, letter, color, pos)
	local d = new("TextLabel", {
		BackgroundColor3 = color, Size = UDim2.fromOffset(18, 18), Position = pos, Text = letter,
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
	}, parent)
	UI.corner(d, 9)
	return d
end

-- opts: order, onClick, actions = { {text, cb, kind="bad"}, ... }, size
function UI.petCard(parent, item, opts)
	opts = opts or {}
	local T = UI.T
	local rc = Catalog.rarityColor(item.rarity)
	local h = opts.actions and UI.CARD_HA or UI.CARD_H
	local card = new("Frame", { BackgroundColor3 = T.panel, BorderSizePixel = 0, LayoutOrder = opts.order or 0, Size = opts.size or UDim2.new(1, 0, 0, h) }, parent)
	UI.corner(card, 10)
	local cs = UI.stroke(card, T.stroke, 1)
	if item.neon == "neon" then cs.Color, cs.Thickness = C(70, 255, 200), 2
	elseif item.neon == "mega" then cs.Color, cs.Thickness = C(255, 80, 240), 2 end

	if opts.onClick then
		local hit = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1) }, card)
		hit.Activated:Connect(opts.onClick)
	end

	local tile = new("Frame", { BackgroundColor3 = rc, BorderSizePixel = 0, Size = UDim2.fromOffset(56, 56), Position = UDim2.new(0.5, -28, 0, 8) }, card)
	UI.corner(tile, 12)
	new("UIGradient", { Color = ColorSequence.new(rc, rc:Lerp(Color3.new(0, 0, 0), 0.35)), Rotation = 90 }, tile)
	local url = Catalog.imageUrl(item.image) or Catalog.imageUrl(Catalog.imageOf(item.name))
	if url then
		local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = url, ScaleType = Enum.ScaleType.Fit }, tile)
		UI.corner(img, 12)
	else
		new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = initials(item.name), Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.new(1, 1, 1) }, tile)
	end
	if item.fly then dot(tile, "F", C(90, 190, 255), UDim2.new(0, -6, 1, -12)) end
	if item.ride then dot(tile, "R", C(255, 170, 70), UDim2.new(1, -12, 1, -12)) end
	if item.neon == "neon" then dot(tile, "N", C(70, 255, 200), UDim2.new(1, -12, 0, -6))
	elseif item.neon == "mega" then dot(tile, "M", C(255, 80, 240), UDim2.new(1, -12, 0, -6)) end

	local function line(text, y, hh, size, color, bold)
		return new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(6, y), Size = UDim2.new(1, -12, 0, hh), Text = text,
			Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium, TextSize = size, TextColor3 = color,
			TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false,
		}, card)
	end
	line(item.name, 70, 16, 13, T.text, true)
	line(Inv.typeLabel(item), 86, 14, 11, T.sub)
	line(item.age .. (item.qty and item.qty > 1 and ("  •  ×" .. item.qty) or (item.qty and "  •  ×1" or "")), 100, 14, 11, T.sub)
	line(Catalog.rarityLabel(item.rarity), 114, 14, 11, rc, true)
	if item.note and item.note ~= "" then
		local n = line("📝 " .. item.note, 128, 24, 10, T.sub)
		n.TextWrapped = true
		n.TextYAlignment = Enum.TextYAlignment.Top
	end

	if opts.actions then
		local row = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 156), Size = UDim2.new(1, -12, 0, 30) }, card)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, row)
		local n = #opts.actions
		for i, a in ipairs(opts.actions) do
			UI.button(row, a[1], a[2], {
				size = UDim2.new(1 / n, -math.ceil(4 * (n - 1) / n), 1, 0), order = i, textSize = 13,
				color = a.kind == "bad" and T.bad or nil,
			})
		end
	end
	return card
end

---------------------------------------------------------------- уведомления и модальные окна
function UI.toast(text, kind)
	if not UI.overlay then return end
	local T = UI.T
	if UI.toastObj then pcall(function() UI.toastObj:Destroy() end) end
	local col = (kind == "bad" and T.bad) or (kind == "good" and T.good) or T.accent
	local f = new("Frame", {
		BackgroundColor3 = T.panel2, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 60), Size = UDim2.new(0.9, 0, 0, 0), AutomaticSize = AUTO_Y, ZIndex = 300,
	}, UI.overlay)
	UI.corner(f, 10); UI.stroke(f, col, 1.5); UI.pad(f, 12, 8, 12, 8)
	new("UISizeConstraint", { MaxSize = Vector2.new(340, 9999) }, f)
	UI.label(f, tostring(text), { TextSize = 13 })
	UI.toastObj = f
	UI.tween(f, { Position = UDim2.new(0.5, 0, 1, -34) }, 0.25, Enum.EasingStyle.Back)
	task.delay(2.8, function()
		if UI.toastObj == f then
			UI.tween(f, { Position = UDim2.new(0.5, 0, 1, 60) }, 0.2)
			task.delay(0.25, function() f:Destroy() end)
			UI.toastObj = nil
		end
	end)
end

-- builder(content, close); opts: buttons = { {text, cb(close), kind}, ... }, dismiss, onClose
function UI.modal(title, builder, opts)
	opts = opts or {}
	local T = UI.T
	local closed = false
	local dim = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 100,
	}, UI.overlay)
	local maxH = math.max(160, UI.overlay.AbsoluteSize.Y / math.max(UI.curScale, 0.1) - 24)
	local box = new("ScrollingFrame", {
		BackgroundColor3 = T.panel, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.94, 0, 0, 0), AutomaticSize = AUTO_Y,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y, Active = true, ElasticBehavior = Enum.ElasticBehavior.Never,
	}, dim)
	UI.corner(box, 12); UI.stroke(box, T.stroke); UI.pad(box, 12); UI.list(box, 8)
	new("UISizeConstraint", { MaxSize = Vector2.new(480, maxH) }, box)
	local sc = new("UIScale", { Scale = Settings.get("animations") and 0.92 or 1 }, box)
	UI.label(box, title, { Font = Enum.Font.GothamBold, TextSize = 16 })
	local content = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y }, box)
	UI.list(content, 8)

	local function close()
		if closed then return end
		closed = true
		UI.tween(dim, { BackgroundTransparency = 1 }, 0.15)
		UI.tween(sc, { Scale = 0.92 }, 0.15)
		task.delay(0.16, function() dim:Destroy() end)
		if opts.onClose then pcall(opts.onClose) end
	end

	builder(content, close)

	if opts.buttons and #opts.buttons > 0 then
		local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38) }, box)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
		local n = #opts.buttons
		for i, b in ipairs(opts.buttons) do
			local color = (b.kind == "primary" and T.accent) or (b.kind == "danger" and T.bad) or (b.kind == "good" and T.good) or nil
			UI.button(row, b.text, function()
				local r = b.cb and b.cb(close)
				if r ~= false then close() end
			end, { size = UDim2.new(1 / n, -math.ceil(6 * (n - 1) / n), 1, 0), color = color, order = i, textColor = color and Color3.new(1, 1, 1) or nil })
		end
	end
	if opts.dismiss ~= false then dim.Activated:Connect(close) end
	dim.BackgroundTransparency = 1
	UI.tween(dim, { BackgroundTransparency = 0.45 }, 0.15)
	UI.tween(sc, { Scale = 1 }, 0.18, Enum.EasingStyle.Back)
	return close
end

function UI.confirm(title, text, onYes, yesText)
	UI.modal(title, function(content) UI.label(content, text, { TextSize = 13, TextColor3 = UI.T.sub }) end, {
		buttons = { { text = "Отмена" }, { text = yesText or "Да", kind = "danger", cb = function() onYes() end } },
	})
end

---------------------------------------------------------------- оболочка окна
local gui, main, scaleObj, fab, pages

function UI.shellDestroy()
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	for _, f in ipairs(cleanups) do pcall(f) end
	cleanups = {}
	if gui then pcall(function() gui:Destroy() end) end
	gui, main, fab, pages = nil, nil, nil, nil
	UI.overlay, UI.toastObj = nil, nil
end

function UI.destroy()
	UI.shellDestroy()
	for _, c in ipairs(permConns) do pcall(function() c:Disconnect() end) end
	permConns = {}
end

function UI.build()
	UI.shellDestroy()
	local st = UI.state
	local T = UI.themes[Settings.get("theme")] or UI.themes.dark
	UI.T = T
	local isTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled
	st.w = st.w or (isTouch and 520 or 680)
	st.h = st.h or (isTouch and 300 or 440)

	gui = new("ScreenGui", {
		Name = "AU_" .. HttpService:GenerateGUID(false):sub(1, 8), ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 1000,
	})
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	gui.Parent = Ctx.guiParent()

	main = new("CanvasGroup", {
		Name = "Main", BackgroundColor3 = T.bg, BorderSizePixel = 0, Active = true, ClipsDescendants = true,
		Size = UDim2.fromOffset(st.w, st.h), GroupTransparency = Settings.get("transparency"),
	}, gui)
	UI.corner(main, 14); UI.stroke(main, T.stroke, 1)
	scaleObj = new("UIScale", { Scale = 1 }, main)

	-- заголовок
	local title = new("Frame", { Name = "Title", BackgroundColor3 = T.side, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, TITLE_H) }, main)
	local tl = new("TextLabel", {
		BackgroundTransparency = 1, RichText = true, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -100, 1, 0),
		Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "ADOPT ME <font color=\"" .. rgbStr(T.accent) .. "\">ULTIMATE</font>",
	}, title)
	local btnMin = UI.button(title, "—", nil, { size = UDim2.fromOffset(34, 28), color = T.panel2 })
	btnMin.AnchorPoint, btnMin.Position = Vector2.new(1, 0.5), UDim2.new(1, -48, 0.5, 0)
	local btnClose = UI.button(title, "✕", nil, { size = UDim2.fromOffset(34, 28), color = T.panel2 })
	btnClose.AnchorPoint, btnClose.Position = Vector2.new(1, 0.5), UDim2.new(1, -8, 0.5, 0)

	-- тело
	local body = new("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TITLE_H), Size = UDim2.new(1, 0, 1, -TITLE_H) }, main)
	local sidebar = new("ScrollingFrame", {
		Name = "Sidebar", BackgroundColor3 = T.side, BorderSizePixel = 0, Size = UDim2.new(0, 54, 1, 0),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, body)
	UI.list(sidebar, 3); UI.pad(sidebar, 6, 6, 6, 6)
	local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromOffset(54, 0), Size = UDim2.new(1, -54, 1, 0) }, body)

	local overlay = new("Frame", { Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50 }, main)
	UI.overlay = overlay

	local grip = new("TextButton", {
		Text = "◢", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.sub, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), ZIndex = 60,
	}, main)

	-- вкладки
	pages = {}
	local tabBtns = {}
	for i, p in ipairs(Ctx.PageList) do
		local b = new("TextButton", { Name = p.id, BackgroundColor3 = T.accent, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = i }, sidebar)
		UI.corner(b, 8)
		local ic = UI.label(b, p.icon, { Size = UDim2.new(0, 40, 1, 0), AutomaticSize = NONE, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 18 })
		local tx = UI.label(b, p.short, { Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(42, 0), AutomaticSize = NONE, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
		tabBtns[p.id] = { b = b, ic = ic, tx = tx }
		b.Activated:Connect(function() UI.goto(p.id) end)
		local frame = new("CanvasGroup", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }, content)
		pages[p.id] = { frame = frame, mod = p.mod, built = false }
	end

	local sidebarExpanded
	local function layoutSidebar()
		local exp = st.w >= 560
		if exp == sidebarExpanded then return end
		sidebarExpanded = exp
		local sw = exp and 150 or 54
		sidebar.Size = UDim2.new(0, sw, 1, 0)
		content.Position = UDim2.fromOffset(sw, 0)
		content.Size = UDim2.new(1, -sw, 1, 0)
		for _, t in pairs(tabBtns) do t.tx.Visible = exp end
	end

	local function effScale()
		local vp = gui.AbsoluteSize
		local s = math.min(Settings.get("scale"), (vp.X - 12) / MIN_W, (vp.Y - 12) / MIN_H)
		return math.max(s, 0.5), vp
	end

	function UI.fit()
		if not gui then return end
		local s, vp = effScale()
		UI.curScale = s
		scaleObj.Scale = s
		st.w = math.clamp(st.w, MIN_W, math.max(MIN_W, math.floor((vp.X - 12) / s)))
		st.h = math.clamp(st.h, MIN_H, math.max(MIN_H, math.floor((vp.Y - 12) / s)))
		local h = st.minimized and TITLE_H or st.h
		main.Size = UDim2.fromOffset(st.w, h)
		local pw, ph = st.w * s, h * s
		if st.x == nil then
			st.x, st.y = (vp.X - pw) / 2, (vp.Y - ph) / 2
		end
		st.x = math.clamp(st.x, 6, math.max(6, vp.X - pw - 6))
		st.y = math.clamp(st.y, 4, math.max(4, vp.Y - ph - 6))
		main.Position = UDim2.fromOffset(st.x, st.y)
		layoutSidebar()
	end

	-- перемещение окна
	local sx, sy
	makeDrag(title, function() sx, sy = st.x, st.y end, function(d)
		st.x, st.y = sx + d.X, sy + d.Y
		UI.fit()
	end)
	-- изменение размера
	local sw0, sh0
	makeDrag(grip, function() sw0, sh0 = st.w, st.h end, function(d)
		st.w, st.h = sw0 + d.X / UI.curScale, sh0 + d.Y / UI.curScale
		UI.fit()
	end)

	btnMin.Activated:Connect(function()
		st.minimized = not st.minimized
		body.Visible = not st.minimized
		grip.Visible = not st.minimized
		btnMin.Text = st.minimized and "▢" or "—"
		UI.fit()
	end)

	-- плавающая кнопка
	fab = new("TextButton", {
		Name = "Fab", Text = "🐾", TextSize = 24, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = T.accent, BorderSizePixel = 0, AutoButtonColor = false, Size = UDim2.fromOffset(52, 52),
		Position = st.fabPos or UDim2.new(0, 14, 0.5, -26), Visible = false, ZIndex = 5,
	}, gui)
	UI.corner(fab, 26); UI.stroke(fab, Color3.new(1, 1, 1), 2)
	local fx, fy, moved = 0, 0, 0
	makeDrag(fab, function() fx, fy, moved = fab.AbsolutePosition.X, fab.AbsolutePosition.Y, 0 end, function(d)
		moved = math.max(moved, d.Magnitude)
		local vp = gui.AbsoluteSize
		fab.Position = UDim2.fromOffset(math.clamp(fx + d.X, 0, vp.X - 52), math.clamp(fy + d.Y, 0, vp.Y - 52))
	end, function()
		st.fabPos = fab.Position
		if moved < 8 then UI.setVisible(true) end
	end)

	function UI.setVisible(v)
		st.hidden = not v
		local target = Settings.get("transparency")
		if v then
			main.Visible, fab.Visible = true, false
			if Settings.get("animations") then main.GroupTransparency = 1 end
			UI.tween(main, { GroupTransparency = target }, 0.2)
		else
			UI.tween(main, { GroupTransparency = 1 }, 0.15)
			task.delay(0.16, function()
				if st.hidden and main then main.Visible = false end
			end)
			fab.Visible = true
		end
	end
	btnClose.Activated:Connect(function() UI.setVisible(false) end)

	function UI.goto(id, params)
		local p = pages and pages[id]
		if not p then return end
		st.tab = id
		for tid, q in pairs(pages) do
			q.frame.Visible = (tid == id)
			local t = tabBtns[tid]
			UI.tween(t.b, { BackgroundTransparency = tid == id and 0 or 1 }, 0.15)
			t.tx.TextColor3 = tid == id and Color3.new(1, 1, 1) or T.sub
			t.ic.TextColor3 = tid == id and Color3.new(1, 1, 1) or T.sub
		end
		if not p.built then
			p.built = true
			local sc = UI.scroll(p.frame)
			local ok, api = pcall(p.mod.build, sc)
			if ok then
				p.api = api or {}
			else
				warn("[ADOPT ME ULTIMATE] страница " .. id .. ": " .. tostring(api))
				UI.label(sc, "Ошибка загрузки страницы:\n" .. tostring(api), { TextColor3 = T.bad, TextSize = 12 })
				p.api = {}
			end
		end
		if Settings.get("animations") then
			p.frame.GroupTransparency = 1
			UI.tween(p.frame, { GroupTransparency = 0 }, 0.2)
		else
			p.frame.GroupTransparency = 0
		end
		if p.api.open then
			local ok, e = pcall(p.api.open, params)
			if not ok then warn("[ADOPT ME ULTIMATE] " .. tostring(e)) end
		elseif p.api.refresh then
			pcall(p.api.refresh)
		end
	end

	track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() UI.fit() end))
	track(UIS.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.RightShift then UI.setVisible(st.hidden) end
	end))

	UI.fit()
	if st.minimized then
		body.Visible, grip.Visible, btnMin.Text = false, false, "▢"
		UI.fit()
	end
	if st.hidden then
		main.Visible, fab.Visible = false, true
	end
	UI.goto(st.tab or "inv")
end

function UI.rebuild() UI.build() end

function UI.start()
	table.insert(permConns, (function()
		-- подписка на настройки: возвращает функцию отписки, оборачиваем в объект с :Disconnect()
		local off = Settings.onChanged(function(k)
			if k == "scale" then
				if UI.fit then UI.fit() end
			elseif k == "transparency" then
				if main then main.GroupTransparency = Settings.get("transparency") end
			elseif k == "theme" or k == "*" then
				task.defer(UI.rebuild)
			end
		end)
		return { Disconnect = off }
	end)())
	UI.build()
end

return UI
