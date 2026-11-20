-- PageCatalog.lua — «Каталог питомцев»
local Ctx = ...
local UI, Inv, Catalog = Ctx.UI, Ctx.Inventory, Ctx.Catalog
local M = {}

function M.build(container)
	local T = UI.T
	local filter = { q = "", rarity = "all" }
	local gridHolder, render

	UI.heading(container, "Каталог питомцев", "Список составлен вручную и может быть неполным — недостающих питомцев можно создать на вкладке «Добавить».")
	local count = UI.label(container, "", { TextSize = 13, TextColor3 = T.sub, Font = Enum.Font.GothamSemibold })
	local panel = UI.panel(container)
	UI.input(panel, "🔍 Поиск по названию", { maxLength = 32, onChanged = function(t) filter.q = t render() end })
	local rar = { { id = "all", label = "Все" } }
	for _, r in ipairs(Catalog.rarities) do rar[#rar + 1] = { id = r.id, label = r.label, color = r.color } end
	UI.chips(panel, rar, "all", function(id) filter.rarity = id render() end)

	render = function()
		if gridHolder then gridHolder:Destroy() end
		local list = Catalog.search(filter.q, filter.rarity, 150)
		count.Text = ("Показано: %d из %d"):format(#list, #Catalog.pets)
		if #list == 0 then
			gridHolder = UI.label(container, "Ничего не найдено.", { LayoutOrder = 100, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.sub })
			return
		end
		gridHolder = UI.grid(container, 150, UI.CARD_HA)
		gridHolder.LayoutOrder = 100
		for i, p in ipairs(list) do
			UI.petCard(gridHolder, { name = p.name, rarity = p.rarity, neon = "none", fly = false, ride = false, age = "Newborn", note = "" }, {
				order = i,
				actions = {
					{ "⚙ Настроить", function() UI.goto("add", { pet = p }) end },
					{ "+1", function()
						Inv.add({ name = p.name, rarity = p.rarity, age = "Newborn", qty = 1 })
						UI.toast("Добавлено: " .. p.name, "good")
					end },
				},
			})
		end
	end
	render()
	return { refresh = render }
end

return M
