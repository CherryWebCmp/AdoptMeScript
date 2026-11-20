-- PageAdd.lua — «Добавить питомца» + редактор карточек (создание/редактирование записей виртуального инвентаря)
local Ctx = ...
local UI, Inv, PetForm = Ctx.UI, Ctx.Inventory, Ctx.PetForm
local M = {}

function M.build(container)
	local T = UI.T
	local api = {}
	local editId, form, preview, modeLbl, addBtn, cancelBtn

	UI.heading(container, "Добавить питомца", "Редактор карточек: выберите питомца, редкость, тип, возраст и описание. Это локальная визуализация.")
	modeLbl = UI.label(container, "", { TextSize = 12, TextColor3 = T.warn, Font = Enum.Font.GothamSemibold })

	local function renderPreview()
		UI.clear(preview)
		local data = form.get()
		if data.name == "" then data.name = "—" end
		UI.petCard(preview, data, { size = UDim2.fromOffset(176, UI.CARD_H) }).Position = UDim2.new(0.5, -88, 0, 4)
	end

	local fp = UI.panel(container, "Параметры питомца")
	form = PetForm.create(fp, nil, function() if preview then renderPreview() end end)

	local pp = UI.panel(container, "Предпросмотр карточки")
	preview = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 166) }, pp)
	renderPreview()

	local function setMode(id)
		editId = id
		if id then
			modeLbl.Text = "✏ Режим редактирования записи инвентаря"
			addBtn.Text = "💾 Сохранить изменения"
			cancelBtn.Visible = true
		else
			modeLbl.Text = ""
			addBtn.Text = "➕ Добавить в инвентарь"
			cancelBtn.Visible = false
		end
	end

	local bp = UI.panel(container)
	addBtn = UI.button(bp, "➕ Добавить в инвентарь", function()
		local data = form.get()
		if data.name == "" then UI.toast("Укажите название питомца", "bad") return end
		if editId then
			if Inv.update(editId, data) then UI.toast("Изменения сохранены", "good") else UI.toast("Запись не найдена", "bad") end
			setMode(nil)
			form.reset()
			UI.goto("inv")
		else
			Inv.add(data)
			UI.toast("Добавлено в виртуальный инвентарь: " .. data.name .. " ×" .. data.qty, "good")
		end
	end, { color = T.accent, textColor = Color3.new(1, 1, 1), height = 42 })
	cancelBtn = UI.button(bp, "Отменить редактирование", function() setMode(nil) form.reset() UI.goto("inv") end)
	setMode(nil)

	-- params: { editId = n } или { pet = {name=, rarity=} }
	function api.open(params)
		if not params then return end
		if params.editId then
			local it = Inv.get(params.editId)
			if it then
				form.set(it)
				setMode(it.id)
			end
		elseif params.pet then
			setMode(nil)
			form.reset()
			form.set({ name = params.pet.name, rarity = params.pet.rarity })
		end
	end
	return api
end

return M
