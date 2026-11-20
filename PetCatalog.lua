-- PetCatalog.lua — каталог питомцев Adopt Me.
-- Список составлен вручную и может быть неполным / содержать неточные редкости:
-- любую редкость можно поменять в редакторе, а новых питомцев — дописать в RAW ниже (или создать «своего» в форме).
local Ctx = ...
local C = {}

C.rarities = {
	{ id = "Common",     label = "Обычный",       color = Color3.fromRGB(160, 168, 178) },
	{ id = "Uncommon",   label = "Необычный",     color = Color3.fromRGB(96, 200, 120) },
	{ id = "Rare",       label = "Редкий",        color = Color3.fromRGB(70, 150, 255) },
	{ id = "Ultra-Rare", label = "Ультра-редкий", color = Color3.fromRGB(176, 96, 255) },
	{ id = "Legendary",  label = "Легендарный",   color = Color3.fromRGB(255, 176, 48) },
}
C.rarityIndex = {}
for i, r in ipairs(C.rarities) do C.rarityIndex[r.id] = i end

function C.rarityColor(id)
	local r = C.rarities[C.rarityIndex[id] or 1]
	return r.color
end
function C.rarityLabel(id)
	local r = C.rarities[C.rarityIndex[id] or 1]
	return r.label
end

-- ИМЯ: через запятую, по редкостям
local RAW = {
	Common = "Dog,Cat,Pig,Chicken,Cow,Hedgehog,Bunny,Duck,Sheep,Mouse,Hamster,Goat",
	Uncommon = "Fox,Wolf,Koala,Penguin,Raccoon,Zebra,Ox,Frog,Hippo,Lamb",
	Rare = "Panda,Polar Bear,Brown Bear,Monkey,Tiger,Rhino,Crocodile,Dodo,Platypus,Sloth,Bat,Toucan,Lynx,Dolphin",
	["Ultra-Rare"] = "Elephant,Blue Dog,Pink Cat,Dalmatian,Kiwi,Axolotl,Seahorse,Cobra,Pegasus,Griffin,Reindeer,Snow Owl,Peacock,Candyfloss Chick,Emperor Penguin",
	Legendary = "Shadow Dragon,Bat Dragon,Frost Dragon,Giraffe,Owl,Parrot,Evil Unicorn,Unicorn,Crow,Turtle,Albino Monkey,Kangaroo,Flamingo,Arctic Reindeer,Lion",
}

C.pets = {}
local byName = {}
for _, r in ipairs(C.rarities) do
	for name in string.gmatch(RAW[r.id] or "", "[^,]+") do
		local entry = { name = name, rarity = r.id, image = nil } -- image: сюда можно вписать "rbxassetid://ID"
		C.pets[#C.pets + 1] = entry
		byName[name:lower()] = entry
	end
end
table.sort(C.pets, function(a, b)
	local ra, rb = C.rarityIndex[a.rarity], C.rarityIndex[b.rarity]
	if ra ~= rb then return ra > rb end
	return a.name < b.name
end)

function C.find(name)
	return byName[tostring(name or ""):lower()]
end

function C.imageOf(name)
	local e = C.find(name)
	return e and e.image or nil
end

-- "123456" -> "rbxassetid://123456"; принимаются только числовые ID и rbxassetid://
function C.imageUrl(img)
	if not img or img == "" then return nil end
	img = tostring(img)
	if img:match("^%d+$") then return "rbxassetid://" .. img end
	if img:match("^rbxassetid://%d+$") then return img end
	return nil
end

-- поиск по подстроке; rarity = nil/"all" — без фильтра
function C.search(query, rarity, limit)
	local q = tostring(query or ""):lower()
	local out = {}
	for _, p in ipairs(C.pets) do
		if (rarity == nil or rarity == "all" or p.rarity == rarity) and (q == "" or p.name:lower():find(q, 1, true)) then
			out[#out + 1] = p
			if limit and #out >= limit then break end
		end
	end
	return out
end

return C
