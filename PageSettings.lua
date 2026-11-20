-- PageSettings.lua — «Настройки»
local Ctx = ...
local UI, Settings, Inv = Ctx.UI, Ctx.Settings, Ctx.Inventory
local M = {}

function M.build(container)
	local T = UI.T
	UI.heading(container, "Настройки", "Параметры сохраняются между запусками, если ваш инжектор поддерживает файловые функции.")

	local p1 = UI.panel(container, "Интерфейс")
	UI.toggle(p1, "Плавные анимации", Settings.get("animations"), function(v) Settings.set("animations", v) end)
	UI.slider(p1, "Прозрачность окна", 0, 0.6, Settings.get("transparency"), 0.05, function(v, final)
		Settings.set("transparency", v, true) -- во время перетаскивания файл не пишем
		if final then Settings.save() end
	end, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
	UI.label(p1, "Размер интерфейса", { TextSize = 12, TextColor3 = T.sub })
	UI.chips(p1, { { id = 0.8, label = "Маленький" }, { id = 1, label = "Обычный" }, { id = 1.2, label = "Большой" } },
		Settings.get("scale"), function(id) Settings.set("scale", id) end)
	UI.label(p1, "Тема", { TextSize = 12, TextColor3 = T.sub })
	local topts = {}
	for _, id in ipairs(UI.themeOrder) do topts[#topts + 1] = { id = id, label = UI.themes[id].name } end
	UI.chips(p1, topts, Settings.get("theme"), function(id) Settings.set("theme", id) end)

	local p2 = UI.panel(container, "Данные")
	UI.label(p2, Settings.canSave and "Сохранение включено: настройки и виртуальный инвентарь пишутся в папку workspace/AdoptMeUltimate."
		or "Ваш инжектор не поддерживает файлы — настройки и инвентарь живут только до закрытия игры.", { TextSize = 12, TextColor3 = T.sub })
	UI.button(p2, "↺ Сбросить настройки", function() Settings.reset() UI.toast("Настройки сброшены", "good") end)
	UI.button(p2, "🗑 Очистить виртуальный инвентарь", function()
		UI.confirm("Очистить инвентарь?", "Все питомцы будут удалены из виртуального инвентаря.", function() Inv.clear() UI.toast("Инвентарь очищен") end, "Очистить")
	end, { color = T.bad, textColor = Color3.new(1, 1, 1) })

	local p3 = UI.panel(container, "Скрипт")
	UI.button(p3, "⏻ Выгрузить скрипт полностью", function()
		UI.confirm("Выгрузить скрипт?", "GUI будет удалён. Чтобы вернуть его, запустите загрузчик снова.", function() Ctx.Destroy() end, "Выгрузить")
	end)
	return {}
end

return M
