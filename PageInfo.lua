-- PageInfo.lua — «Информация о проекте»
local Ctx = ...
local UI = Ctx.UI
local M = {}

function M.build(container)
	local T = UI.T
	UI.heading(container, "ADOPT ME ULTIMATE", "Версия " .. Ctx.Version .. " • локальный GUI-инструмент")

	local p = UI.panel(container, "О проекте")
	UI.label(p, "Виртуальный инвентарь питомцев, редактор карточек, симулятор трейда и каталог — всё внутри этого окна.", { TextSize = 13 })
	UI.label(p, "⚠ Важно: проект не изменяет серверный инвентарь Adopt Me, не отправляет события на сервер и не действует от имени других игроков. Все данные — локальная визуальная симуляция.", { TextSize = 13, TextColor3 = T.warn })

	local u = UI.panel(container, "Управление")
	UI.label(u, "• Перетаскивание — за заголовок окна.\n• Размер — угол ◢ справа внизу.\n• «—» сворачивает окно, «✕» скрывает его (вернуть — кнопка 🐾 или RightShift).\n• Тема, прозрачность и размер — во вкладке «Настройки».", { TextSize = 13 })

	local m = UI.panel(container, "Загруженные модули")
	UI.label(m, table.concat(Ctx.Loaded, ", "), { TextSize = 12, TextColor3 = T.sub })
	UI.label(m, "Источник: " .. (Ctx.Local and "локальная папка workspace" or Ctx.Base), { TextSize = 12, TextColor3 = T.sub })
	UI.label(m, "Обновление: после изменения файлов в GitHub просто перезапустите загрузчик — он каждый раз берёт актуальную версию.", { TextSize = 12, TextColor3 = T.sub })
	return {}
end

return M
