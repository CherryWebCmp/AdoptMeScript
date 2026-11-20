-- PageTrade.lua — «Симулятор трейда» (полностью локальный)
local Ctx = ...
local UI, Inv, Catalog, Trade, PetForm = Ctx.UI, Ctx.Inventory, Ctx.Catalog, Ctx.Trade, Ctx.PetForm
local M = {}

local function describe(e)
	return Inv.typeLabel(e) .. " • " .. e.age .. " • " .. Catalog.rarityLabel(e.rarity)
end

local function lines(parent, list, T)
	if #list == 0 then
		UI.label(parent, "— ничего —", { TextSize = 12, TextColor3 = T.sub })
		return
	end
	for _, e in ipairs(list) do
		UI.label(parent, "• " .. e.name .. " ×" .. e.qty .. "  (" .. describe(e) .. ")", { TextSize = 12 })
	end
end

function M.build(container)
	local T = UI.T
	local resultShown = false
	local renderAll

	UI.heading(container, "Симулятор трейда", "Локальная симуляция. Ничего не отправляется на сервер и не влияет на настоящие обмены.")
	local banner = UI.frame(container, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.warn, BackgroundTransparency = 0.82 })
	UI.corner(banner, 8); UI.stroke(banner, T.warn); UI.pad(banner, 10, 6, 10, 6)
	UI.label(banner, "⚠ СИМУЛЯЦИЯ — этот обмен существует только внутри вашего GUI", { TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = T.warn })

	-- второй участник (просто текст)
	local pp = UI.panel(container, "Второй участник")
	UI.label(pp, "Никнейм используется только как подпись в симуляции.", { TextSize = 12, TextColor3 = T.sub })
	UI.input(pp, "Никнейм (текст)", { text = Trade.state.partner, maxLength = 20, onChanged = function(t) Trade.setPartner(t) end })

	-- стороны обмена
	local function side(sideName, title)
		local p = UI.panel(container, nil)
		local titleLbl = UI.label(p, title, { Font = Enum.Font.GothamBold, TextSize = 15 })
		local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, p)
		UI.list(holder, 6)
		local br = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, p)
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, br)
		return holder, br, titleLbl
	end
	local myHolder, myBtns = side("mine", "Вы предлагаете")
	local thHolder, thBtns, thTitle = side("theirs", "Предлагает: второй участник")

	local function renderSide(sideName, holder)
		UI.clear(holder)
		local list = sideName == "mine" and Trade.state.mine or Trade.state.theirs
		if #list == 0 then
			UI.label(holder, "Пока пусто", { TextSize = 12, TextColor3 = T.sub })
			return
		end
		for i, e in ipairs(list) do
			local row, right = UI.row(holder, e.name .. (e.manual and "  ✍" or ""), describe(e), i, 140)
			local id = e.uid
			local function chg(q)
				local ok, msg = Trade.setQty(sideName, id, q)
				if ok == false and msg then UI.toast(msg, "bad") end
			end
			UI.button(right, "−", function() chg(e.qty - 1) end, { size = UDim2.fromOffset(30, 30), order = 1 })
			UI.label(right, "×" .. e.qty, { Size = UDim2.fromOffset(34, 30), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 13, LayoutOrder = 2 })
			UI.button(right, "+", function() chg(e.qty + 1) end, { size = UDim2.fromOffset(30, 30), order = 3 })
			UI.button(right, "✕", function() Trade.remove(sideName, id) end, { size = UDim2.fromOffset(30, 30), order = 4, color = T.bad })
		end
	end

	local function manualModal(sideName)
		local form
		UI.modal("Своя карточка предмета", function(content)
			form = PetForm.create(content, nil, nil)
		end, {
			dismiss = false,
			buttons = {
				{ text = "Отмена" },
				{ text = "Добавить", kind = "primary", cb = function()
					local data = form.get()
					if data.name == "" then UI.toast("Укажите название", "bad") return false end
					Trade.addManual(sideName, data)
				end },
			},
		})
	end

	local function pickModal()
		UI.modal("Выбор из виртуального инвентаря", function(content)
			local q = ""
			local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 }, content)
			UI.list(holder, 6)
			local function render()
				UI.clear(holder)
				local list = Inv.query({ search = q, sort = "recent" })
				if #list == 0 then
					UI.label(holder, "Нет подходящих питомцев. Добавьте их на вкладке «Добавить».", { TextSize = 12, TextColor3 = T.sub })
					return
				end
				for i, it in ipairs(list) do
					local avail = Trade.availableFor(it.id)
					local row, right = UI.row(holder, it.name .. "  (доступно: " .. avail .. ")", describe(it), i, 40)
					local b = UI.button(right, "➕", function()
						local ok, msg = Trade.addFromInventory(it.id, 1)
						if ok then render() else UI.toast(msg or "Не удалось добавить", "bad") end
					end, { size = UDim2.fromOffset(34, 30) })
					UI.setEnabled(b, avail > 0)
				end
			end
			UI.input(content, "🔍 Поиск", { order = 1, maxLength = 32, onChanged = function(t) q = t render() end })
			render()
		end, { buttons = { { text = "Готово", kind = "primary" } } })
	end

	UI.button(myBtns, "➕ Из инвентаря", pickModal, { autosize = true, order = 1, textSize = 13 })
	UI.button(myBtns, "✍ Своя карточка", function() manualModal("mine") end, { autosize = true, order = 2, textSize = 13 })
	UI.button(thBtns, "✍ Создать карточку", function() manualModal("theirs") end, { autosize = true, order = 1, textSize = 13 })

	-- статус / подтверждение
	local sp = UI.panel(container, "Подтверждение")
	local statusLbl = UI.label(sp, "", { TextSize = 13, TextColor3 = T.sub })
	local pillRow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28) }, sp)
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, pillRow)
	local pills = {}
	for i, name in ipairs({ "Вы приняли", "Ожидание", "Партнёр принял", "Готово" }) do
		local pill = UI.new("Frame", { BackgroundColor3 = T.panel2, BorderSizePixel = 0, Size = UDim2.new(0.25, -3, 1, 0), LayoutOrder = i }, pillRow)
		UI.corner(pill, 6)
		UI.label(pill, name, { Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.None, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true })
		pills[i] = pill
	end
	local btnRow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, sp)
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, btnRow)

	local hp = UI.panel(container, "История (в этой сессии)")
	local histHolder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, hp)
	UI.list(histHolder, 4)

	local function showResult()
		local r = Trade.state.result
		if not r then return end
		UI.modal("Обмен завершён", function(content)
			local check = UI.label(content, "✔", { TextSize = 46, Font = Enum.Font.GothamBold, TextColor3 = T.good, TextXAlignment = Enum.TextXAlignment.Center })
			local sc = UI.new("UIScale", { Scale = Ctx.Settings.get("animations") and 0.2 or 1 }, check)
			UI.tween(sc, { Scale = 1 }, 0.5, Enum.EasingStyle.Back)
			UI.label(content, "СИМУЛЯЦИЯ • " .. r.partner .. " • " .. r.time, { TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Center })
			UI.label(content, "Вы отдали:", { Font = Enum.Font.GothamBold, TextSize = 13 })
			lines(content, r.mine, T)
			UI.label(content, "Вы получили:", { Font = Enum.Font.GothamBold, TextSize = 13 })
			lines(content, r.theirs, T)
		end, {
			dismiss = false,
			onClose = function() Trade.closeResult() end,
			buttons = {
				{ text = "Закрыть" },
				{ text = "Применить к инвентарю", kind = "primary", cb = function()
					if Trade.apply() then UI.toast("Применено к виртуальному инвентарю", "good") end
				end },
			},
		})
	end

	renderAll = function()
		local s = Trade.state
		thTitle.Text = "Предлагает: " .. (s.partner ~= "" and s.partner or "второй участник")
		renderSide("mine", myHolder)
		renderSide("theirs", thHolder)

		statusLbl.Text = s.status ~= "" and s.status or "Составьте обмен и нажмите «Принять»."
		for i, pill in ipairs(pills) do
			UI.tween(pill, { BackgroundColor3 = (s.step >= i) and T.good or T.panel2 }, 0.25)
		end
		UI.clear(btnRow)
		if s.phase == "accepting" then
			UI.button(btnRow, "✖ Отменить", function() Trade.cancel() end, { autosize = true, color = T.bad, textColor = Color3.new(1, 1, 1), order = 1 })
		else
			local ok = Trade.canAccept()
			local b = UI.button(btnRow, "✅ Принять обмен", function()
				local done, msg = Trade.accept()
				if not done and msg then UI.toast(msg, "bad") end
			end, { autosize = true, color = T.good, textColor = Color3.new(1, 1, 1), order = 1 })
			UI.setEnabled(b, ok)
			UI.button(btnRow, "🧹 Очистить обмен", function() Trade.clear() end, { autosize = true, order = 2 })
		end

		UI.clear(histHolder)
		if #Trade.history == 0 then
			UI.label(histHolder, "Пока нет завершённых симуляций.", { TextSize = 12, TextColor3 = T.sub })
		else
			for i, r in ipairs(Trade.history) do
				if i > 5 then break end
				UI.label(histHolder, string.format("%s • %s • отдано %d / получено %d • %s", r.time, r.partner, #r.mine, #r.theirs, r.applied and "применено" or "не применено"), { TextSize = 12, TextColor3 = T.sub, LayoutOrder = i })
			end
		end
	end

	local off = Trade.onChanged(function()
		renderAll()
		if Trade.state.phase == "result" then
			if not resultShown then resultShown = true showResult() end
		else
			resultShown = false
		end
	end)
	UI.cleanup(off)
	renderAll()
	return { refresh = renderAll }
end

return M
