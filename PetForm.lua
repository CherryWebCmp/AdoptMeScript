-- PetForm.lua — переиспользуемая форма характеристик питомца (страница «Добавить» и ручные карточки трейда)
local Ctx = ...
local UI, Catalog, Inv = Ctx.UI, Ctx.Catalog, Ctx.Inventory

local F = {}

-- init: начальные данные; onChange(data); opts.noQty
function F.create(parent, init, onChange, opts)
	opts = opts or {}
	local T = UI.T
	local d = { name = "", rarity = "Common", neon = "none", fly = false, ride = false, age = "Newborn", qty = 1, note = "", image = "" }
	for k, v in pairs(init or {}) do d[k] = v end
	d.image = d.image or ""
	local setting = false
	local api = {}

	local function changed() if onChange then onChange(d) end end
	local root = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent)
	UI.list(root, 8)
	local function cap(text) UI.label(root, text, { TextSize = 12, TextColor3 = T.sub, Font = Enum.Font.GothamSemibold }) end

	-- имя + подсказки из каталога
	cap("Питомец (поиск по каталогу или своё название)")
	local refreshSuggest
	local nameIn = UI.input(root, "Например: Shadow Dragon", {
		text = d.name, maxLength = 32,
		onChanged = function(t)
			if setting then return end
			d.name = t
			refreshSuggest()
			changed()
		end,
	})
	local status = UI.label(root, "", { TextSize = 12, TextColor3 = T.sub })
	local sugg = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, root)
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sugg)

	local rarityChips, neonChips, flyT, rideT, ageChips, qtyBox

	refreshSuggest = function()
		UI.clear(sugg)
		local q = d.name:gsub("^%s+", ""):gsub("%s+$", "")
		local exact = Catalog.find(q)
		if q == "" then
			status.Text = "Начните вводить название — появятся подсказки."
			return
		end
		if exact then
			status.Text = "✔ Найден в каталоге: " .. exact.name .. " (" .. Catalog.rarityLabel(exact.rarity) .. ")"
		else
			status.Text = "ℹ «" .. q .. "» — свой питомец (не из каталога); редкость выберите ниже."
		end
		for i, p in ipairs(Catalog.search(q, nil, 10)) do
			if not exact or exact.name ~= p.name then
				UI.button(sugg, p.name, function()
					setting = true
					nameIn.set(p.name)
					setting = false
					d.name, d.rarity = p.name, p.rarity
					rarityChips.set(p.rarity)
					refreshSuggest()
					changed()
				end, { autosize = true, height = 30, order = i, textSize = 12, textColor = Catalog.rarityColor(p.rarity) })
			end
		end
	end

	cap("Редкость")
	local ropts = {}
	for _, r in ipairs(Catalog.rarities) do ropts[#ropts + 1] = { id = r.id, label = r.label, color = r.color } end
	rarityChips = UI.chips(root, ropts, d.rarity, function(id) d.rarity = id changed() end)

	cap("Тип")
	neonChips = UI.chips(root, { { id = "none", label = "Обычный" }, { id = "neon", label = "Neon" }, { id = "mega", label = "Mega Neon" } }, d.neon, function(id) d.neon = id changed() end)
	local fr = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32) }, root)
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, fr)
	flyT = UI.toggleChip(fr, "🪽 Fly", d.fly, function(v) d.fly = v changed() end)
	rideT = UI.toggleChip(fr, "🛴 Ride", d.ride, function(v) d.ride = v changed() end)

	cap("Возраст")
	ageChips = UI.chips(root, Inv.AGES, d.age, function(id) d.age = id changed() end)

	if not opts.noQty then
		cap("Количество")
		local qr = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38) }, root)
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, qr)
		local function setQty(n)
			d.qty = math.clamp(math.floor(n), 1, Inv.MAX_QTY)
			setting = true
			qtyBox.set(tostring(d.qty))
			setting = false
			changed()
		end
		UI.button(qr, "−", function() setQty(d.qty - 1) end, { size = UDim2.fromOffset(40, 38), order = 1 })
		local qi = UI.input(qr, "1", {
			text = tostring(d.qty), numeric = true, maxLength = 3,
			onChanged = function(t)
				if setting then return end
				local n = tonumber(t)
				if n then d.qty = math.clamp(math.floor(n), 1, Inv.MAX_QTY) changed() end
			end,
		})
		qi.frame.Size, qi.frame.LayoutOrder = UDim2.fromOffset(80, 38), 2
		qtyBox = qi
		UI.button(qr, "+", function() setQty(d.qty + 1) end, { size = UDim2.fromOffset(40, 38), order = 3 })
	end

	cap("Описание (необязательно)")
	local noteIn = UI.input(root, "Например: мечта из яйца", { text = d.note, maxLength = 80, onChanged = function(t) if setting then return end d.note = t changed() end })
	cap("ID изображения (необязательно, только цифры)")
	local imgIn = UI.input(root, "rbxassetid, например 1234567", { text = d.image, numeric = true, maxLength = 16, onChanged = function(t) if setting then return end d.image = t changed() end })

	function api.get()
		local out = {}
		for k, v in pairs(d) do out[k] = v end
		out.name = (d.name:gsub("^%s+", ""):gsub("%s+$", ""))
		return out
	end

	function api.set(data)
		for k, v in pairs(data or {}) do d[k] = v end
		d.image = d.image or ""
		setting = true
		nameIn.set(d.name)
		noteIn.set(d.note or "")
		imgIn.set(tostring(d.image))
		if qtyBox then qtyBox.set(tostring(d.qty)) end
		setting = false
		rarityChips.set(d.rarity); neonChips.set(d.neon); ageChips.set(d.age)
		flyT.set(d.fly); rideT.set(d.ride)
		refreshSuggest()
		changed()
	end

	function api.reset()
		api.set({ name = "", rarity = "Common", neon = "none", fly = false, ride = false, age = "Newborn", qty = 1, note = "", image = "" })
	end

	api.root = root
	refreshSuggest()
	return api
end

return F
