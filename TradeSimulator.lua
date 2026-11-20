-- TradeSimulator.lua — ЛОКАЛЬНАЯ симуляция обмена. Никаких обращений к серверу/Remote-событиям игры.
local Ctx = ...
local Inv, Settings = Ctx.Inventory, Ctx.Settings

local T = {}
local state = { partner = "", mine = {}, theirs = {}, phase = "edit", step = 0, status = "", result = nil }
T.state = state
T.history = {}

local listeners = {}
local token, uid = 0, 0

local function fire()
	for _, f in ipairs(listeners) do pcall(f) end
end

function T.onChanged(f)
	table.insert(listeners, f)
	return function()
		local i = table.find(listeners, f)
		if i then table.remove(listeners, i) end
	end
end

local function side(name) return name == "mine" and state.mine or state.theirs end

-- Любое изменение состава сбрасывает подтверждение (как в настоящем обмене)
local function resetAccept()
	token = token + 1
	if state.phase == "accepting" then
		state.phase = "edit"
		state.step = 0
		state.status = "Подтверждение сброшено: состав обмена изменился"
	end
end

local function nextUid() uid = uid + 1 return uid end

function T.offered(invId)
	local n = 0
	for _, e in ipairs(state.mine) do
		if e.invId == invId then n = n + e.qty end
	end
	return n
end

function T.availableFor(invId)
	local it = Inv.get(invId)
	if not it then return 0 end
	return it.qty - T.offered(invId)
end

function T.setPartner(name)
	state.partner = tostring(name or ""):sub(1, 20)
	fire()
end

function T.addFromInventory(invId, qty)
	local it = Inv.get(invId)
	if not it then return false, "Питомец не найден в инвентаре" end
	local avail = T.availableFor(invId)
	if avail <= 0 then return false, "Все экземпляры уже в обмене" end
	qty = math.min(math.max(math.floor(tonumber(qty) or 1), 1), avail)
	for _, e in ipairs(state.mine) do
		if e.invId == invId then
			e.qty = e.qty + qty
			resetAccept(); fire()
			return true
		end
	end
	local e = Inv.sanitize(it)
	e.qty, e.uid, e.invId = qty, nextUid(), invId
	state.mine[#state.mine + 1] = e
	resetAccept(); fire()
	return true
end

function T.addManual(sideName, data)
	local e = Inv.sanitize(data)
	e.uid, e.manual = nextUid(), true
	local list = side(sideName)
	list[#list + 1] = e
	resetAccept(); fire()
	return true
end

function T.remove(sideName, id)
	local list = side(sideName)
	for i, e in ipairs(list) do
		if e.uid == id then
			table.remove(list, i)
			resetAccept(); fire()
			return true
		end
	end
	return false
end

function T.setQty(sideName, id, qty)
	local list = side(sideName)
	for _, e in ipairs(list) do
		if e.uid == id then
			qty = math.floor(tonumber(qty) or 0)
			if qty <= 0 then return T.remove(sideName, id) end
			if e.invId then
				local it = Inv.get(e.invId)
				local cap = it and (it.qty - (T.offered(e.invId) - e.qty)) or e.qty
				if qty > cap then return false, "В инвентаре больше нет таких питомцев" end
			end
			e.qty = math.min(qty, Inv.MAX_QTY)
			resetAccept(); fire()
			return true
		end
	end
	return false
end

function T.clear()
	state.mine, state.theirs = {}, {}
	state.status, state.step, state.phase = "", 0, "edit"
	token = token + 1
	fire()
end

function T.canAccept()
	return state.phase == "edit" and (#state.mine > 0 or #state.theirs > 0)
end

local function copyList(list)
	local out = {}
	for i, e in ipairs(list) do
		local c = {}
		for k, v in pairs(e) do c[k] = v end
		out[i] = c
	end
	return out
end

local function finish()
	local r = {
		partner = state.partner ~= "" and state.partner or "Игрок",
		mine = copyList(state.mine),
		theirs = copyList(state.theirs),
		time = os.date("%H:%M:%S"),
		applied = false,
	}
	state.result, state.phase, state.step = r, "result", 4
	state.status = "Обмен завершён (симуляция)"
	table.insert(T.history, 1, r)
	while #T.history > 10 do table.remove(T.history) end
	fire()
end

-- Запуск анимации подтверждения
function T.accept()
	if not T.canAccept() then return false, "Добавьте предметы хотя бы с одной стороны" end
	token = token + 1
	local my = token
	local k = Settings.get("animations") and 1 or 0.25
	state.phase, state.step = "accepting", 1
	state.status = "Вы приняли обмен…"
	fire()
	local steps = {
		{ 1.2 * k, 2, "Ждём подтверждения партнёра (симуляция)…" },
		{ 2.8 * k, 3, "Партнёр принял обмен" },
		{ 3.8 * k, 4, "Завершаем обмен…" },
	}
	for _, s in ipairs(steps) do
		task.delay(s[1], function()
			if token ~= my or state.phase ~= "accepting" then return end
			state.step, state.status = s[2], s[3]
			fire()
		end)
	end
	task.delay(4.8 * k, function()
		if token ~= my or state.phase ~= "accepting" then return end
		finish()
	end)
	return true
end

function T.cancel()
	token = token + 1
	state.phase, state.step = "edit", 0
	state.status = "Обмен отменён"
	fire()
end

-- Применить результат к ВИРТУАЛЬНОМУ инвентарю (однократно)
function T.apply()
	local r = state.result
	if not r or r.applied then return false end
	for _, e in ipairs(r.mine) do
		if e.invId then
			local it = Inv.get(e.invId)
			if it then Inv.setQty(e.invId, it.qty - e.qty) end
		end
	end
	for _, e in ipairs(r.theirs) do Inv.add(e) end
	r.applied = true
	fire()
	return true
end

-- Закрыть итоговое окно: обмен очищается
function T.closeResult()
	state.mine, state.theirs = {}, {}
	state.phase, state.step, state.result = "edit", 0, nil
	state.status = ""
	fire()
end

return T
