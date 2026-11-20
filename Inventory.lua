-- Inventory.lua — ВИРТУАЛЬНЫЙ инвентарь (хранится только локально; серверный инвентарь игры не затрагивается)
local Ctx = ...
local Settings, Catalog = Ctx.Settings, Ctx.Catalog

local Inv = {}
Inv.AGES = { "Newborn", "Junior", "Pre-Teen", "Teen", "Post-Teen", "Full Grown" }
Inv.MAX_QTY = 999

local items, listeners, nextId = {}, {}, 1

local function fire()
	for _, f in ipairs(listeners) do pcall(f) end
end

local function ageRank(a) return table.find(Inv.AGES, a) or 1 end

local function sanitize(d)
	d = d or {}
	local q = math.floor(tonumber(d.qty) or 1)
	local image = (d.image ~= nil and tostring(d.image) ~= "") and tostring(d.image) or nil
	return {
		name = tostring(d.name or "?"):sub(1, 32),
		rarity = Catalog.rarityIndex[d.rarity] and d.rarity or "Common",
		neon = (d.neon == "neon" or d.neon == "mega") and d.neon or "none",
		fly = d.fly == true,
		ride = d.ride == true,
		age = table.find(Inv.AGES, d.age) and d.age or "Newborn",
		qty = math.clamp(q, 1, Inv.MAX_QTY),
		note = tostring(d.note or ""):sub(1, 80),
		image = image,
	}
end
Inv.sanitize = sanitize

function Inv.typeLabel(it)
	local p = {}
	if it.neon == "neon" then p[#p + 1] = "Neon" elseif it.neon == "mega" then p[#p + 1] = "Mega Neon" end
	if it.fly then p[#p + 1] = "Fly" end
	if it.ride then p[#p + 1] = "Ride" end
	if #p == 0 then return "Обычный" end
	return table.concat(p, " ")
end

function Inv.typeRank(it)
	local n = (it.neon == "mega" and 2) or (it.neon == "neon" and 1) or 0
	return n * 4 + (it.fly and 1 or 0) + (it.ride and 2 or 0)
end

local function key(it)
	return table.concat({ it.name, it.rarity, it.neon, tostring(it.fly), tostring(it.ride), it.age, it.note, tostring(it.image) }, "|")
end

function Inv.save()
	Settings.writeJson("inventory.json", { nextId = nextId, items = items })
end

function Inv.load()
	local data = Settings.readJson("inventory.json")
	if type(data) ~= "table" or type(data.items) ~= "table" then return end
	items = {}
	for _, raw in ipairs(data.items) do
		local it = sanitize(raw)
		it.id = tonumber(raw.id) or nextId
		items[#items + 1] = it
		if it.id >= nextId then nextId = it.id + 1 end
	end
end

function Inv.onChanged(f)
	table.insert(listeners, f)
	return function()
		local i = table.find(listeners, f)
		if i then table.remove(listeners, i) end
	end
end

function Inv.get(id)
	for _, it in ipairs(items) do
		if it.id == id then return it end
	end
	return nil
end

-- Добавление; одинаковые карточки складываются в стопку
function Inv.add(data)
	local s = sanitize(data)
	local k = key(s)
	for _, it in ipairs(items) do
		if key(it) == k then
			it.qty = math.min(it.qty + s.qty, Inv.MAX_QTY)
			Inv.save(); fire()
			return it
		end
	end
	s.id = nextId
	nextId = nextId + 1
	items[#items + 1] = s
	Inv.save(); fire()
	return s
end

-- Редактирование характеристик (id и порядок сохраняются)
function Inv.update(id, data)
	local it = Inv.get(id)
	if not it then return false end
	local s = sanitize(data)
	for k, v in pairs(s) do it[k] = v end
	it.image = s.image
	Inv.save(); fire()
	return true
end

function Inv.remove(id)
	for i, it in ipairs(items) do
		if it.id == id then
			table.remove(items, i)
			Inv.save(); fire()
			return true
		end
	end
	return false
end

function Inv.setQty(id, qty)
	local it = Inv.get(id)
	if not it then return false end
	qty = math.floor(tonumber(qty) or 0)
	if qty <= 0 then return Inv.remove(id) end
	it.qty = math.min(qty, Inv.MAX_QTY)
	Inv.save(); fire()
	return true
end

function Inv.clear()
	items = {}
	Inv.save(); fire()
end

-- Возвращает (всего штук, уникальных карточек)
function Inv.totals()
	local total = 0
	for _, it in ipairs(items) do total = total + it.qty end
	return total, #items
end

-- opts: search, rarity ("all"/id), sort: recent | age | type | name | rarity
function Inv.query(opts)
	opts = opts or {}
	local q = tostring(opts.search or ""):lower()
	local out = {}
	for _, it in ipairs(items) do
		local okR = (opts.rarity == nil or opts.rarity == "all" or it.rarity == opts.rarity)
		local okS = q == "" or it.name:lower():find(q, 1, true) ~= nil or it.note:lower():find(q, 1, true) ~= nil
		if okR and okS then out[#out + 1] = it end
	end
	local sort = opts.sort or "recent"
	table.sort(out, function(a, b)
		if sort == "age" then
			local x, y = ageRank(a.age), ageRank(b.age)
			if x ~= y then return x > y end
		elseif sort == "type" then
			local x, y = Inv.typeRank(a), Inv.typeRank(b)
			if x ~= y then return x > y end
		elseif sort == "rarity" then
			local x, y = Catalog.rarityIndex[a.rarity], Catalog.rarityIndex[b.rarity]
			if x ~= y then return x > y end
		elseif sort == "name" then
			if a.name ~= b.name then return a.name < b.name end
		end
		return a.id > b.id -- запасной порядок: новые выше
	end)
	return out
end

Inv.load()
return Inv
