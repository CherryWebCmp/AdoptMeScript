-- PageInventory.lua — «Мой виртуальный инвентарь»
local Ctx = ...
local UI, Inv, Catalog = Ctx.UI, Ctx.Inventory, Ctx.Catalog
local M = {}

function M.build(container)
	local T = UI.T
	local api = {}
	local filter = { search = "", rarity = "all", sort = "recent" }
	local gridHolder, render

	UI.heading(container, "Мой виртуальный инвентарь", "Отдельный список внутри GUI. Настоящий инвентарь Adopt Me не затрагивается.")
	local stats = UI.label(container, "", { TextSize = 13, TextColor3 = T.sub, Font = Enum.Font.GothamSemibold })
	local panel = UI.panel(container)
	UI.input(panel, "🔍 Поиск по инвентарю", { maxLength = 32, onChanged = function(t) filter.search = t render() end })
	UI.label(panel, "Редкость", { TextSize = 12, TextColor3 = T.sub })
	local rar = { { id = "all", label = "Все" } }
	for _, r in ipairs(Catalog.rarities) do rar[#rar + 1] = { id = r.id, label = r.label, color = r.color } end
	UI.chips(panel, rar, "all", function(id) filter.rarity = id render() end)
	UI.label(panel, "Сортировка", { TextSize = 12, TextColor3 = T.sub })
	UI.chips(panel, {
		{ id = "recent", label = "Недавние" }, { id = "age", label = "По возрасту" }, { id = "type", label = "По типу" },
		{ id = "name", label = "По имени" }, { id = "rarity", label = "По редкости" },
	}, "recent", function(id) filter.sort = id render() end)
	UI.button(panel, "🗑 Очистить весь инвентарь", function()
		UI.confirm("Очистить инвентарь?", "Будут удалены все питомцы из ВИРТУАЛЬНОГО инвентаря. Настоящий инвентарь игры не меняется.", function()
			Inv.clear()
			UI.toast("Виртуальный инвентарь очищен")
		end, "Очистить")
	end, { color = T.bad, textColor = Color3.new(1, 1, 1) })

	render = function()
		local total, uniq = Inv.totals()
		stats.Text = ("Всего питомцев: %d  •  уникальных карточек: %d"):format(total, uniq)
		if gridHolder then gridHolder:Destroy() end
		local list = Inv.query(filter)
		if #list == 0 then
			gridHolder = UI.label(container, uniq == 0 and "Инвентарь пуст. Добавьте питомцев на вкладках «Добавить» или «Каталог»." or "Ничего не найдено по фильтрам.", {
				LayoutOrder = 100, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.sub, TextSize = 13,
			})
			return
		end
		gridHolder = UI.grid(container, 150, UI.CARD_HA)
		gridHolder.LayoutOrder = 100
		for i, it in ipairs(list) do
			local id = it.id
			UI.petCard(gridHolder, it, {
				order = i,
				actions = {
					{ "−", function() local c = Inv.get(id) if c then Inv.setQty(id, c.qty - 1) end end },
					{ "+", function() local c = Inv.get(id) if c then Inv.setQty(id, c.qty + 1) end end },
					{ "✏", function() UI.goto("add", { editId = id }) end },
					{ "🗑", function() Inv.remove(id) UI.toast("Удалено: " .. it.name) end, kind = "bad" },
				},
			})
		end
	end

	local off = Inv.onChanged(function()
		if container.Parent and container.Parent.Visible then render() end
	end)
	UI.cleanup(off)
	api.refresh = render
	render()
	return api
end

return M
