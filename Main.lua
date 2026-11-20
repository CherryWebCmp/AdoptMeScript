--[[
  ADOPT ME ULTIMATE — Main.lua (точка входа)
  Загружает остальные модули по HTTP из GitHub Raw (или из папки workspace, если AU_LOCAL = true).
  Всё, что делает проект, — локальная визуальная симуляция внутри GUI.
]]

-- ▼ ЕДИНСТВЕННОЕ место, которое нужно отредактировать после публикации на GitHub ▼
local DEFAULT_BASE = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/"
-- ▲ (можно вместо этого задать getgenv().AU_BASE перед запуском) ▲

local VERSION = "1.0.0"

local genv = (typeof(getgenv) == "function" and getgenv()) or _G
if type(genv.AU_CLEANUP) == "function" then pcall(genv.AU_CLEANUP) end -- повторный запуск = перезагрузка

local BASE = genv.AU_BASE or DEFAULT_BASE
if BASE:sub(-1) ~= "/" then BASE = BASE .. "/" end
local LOCAL = genv.AU_LOCAL == true
local FOLDER = genv.AU_FOLDER or "AdoptMeUltimate"

local Players = game:GetService("Players")
local Ctx = { Version = VERSION, Base = BASE, Local = LOCAL, Loaded = {} }

local function notify(text)
	warn("[ADOPT ME ULTIMATE] " .. tostring(text))
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "ADOPT ME ULTIMATE", Text = tostring(text):sub(1, 180), Duration = 8,
		})
	end)
end

local function fetch(name)
	if LOCAL then return readfile(FOLDER .. "/" .. name .. ".lua") end
	if BASE:find("YOUR_USER", 1, true) then
		error("Не указан адрес GitHub: замените YOUR_USER/YOUR_REPO в Main.lua", 0)
	end
	return game:HttpGet(BASE .. name .. ".lua?v=" .. os.time()) -- ?v= обходит кэш Raw при обновлениях
end

local function loadModule(name)
	local src = fetch(name)
	local fn, err = loadstring(src, "=" .. name)
	if not fn then error(name .. ": " .. tostring(err), 0) end
	local mod = fn(Ctx)
	Ctx.Loaded[#Ctx.Loaded + 1] = name
	return mod
end

-- Куда класть ScreenGui
function Ctx.guiParent()
	if typeof(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local ok = pcall(function() return game:GetService("CoreGui"):GetChildren() end)
	if ok then return game:GetService("CoreGui") end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Ctx.Destroy()
	pcall(function() if Ctx.UI then Ctx.UI.destroy() end end)
	genv.AU_CLEANUP = nil
end
genv.AU_CLEANUP = Ctx.Destroy

local ok, err = pcall(function()
	Ctx.Settings  = loadModule("Settings")
	Ctx.Catalog   = loadModule("PetCatalog")
	Ctx.Inventory = loadModule("Inventory")
	Ctx.Trade     = loadModule("TradeSimulator")
	Ctx.UI        = loadModule("UI")
	Ctx.PetForm   = loadModule("PetForm")
	Ctx.PageList = {
		{ id = "inv",      short = "Инвентарь", icon = "🎒", mod = loadModule("PageInventory") },
		{ id = "add",      short = "Добавить",  icon = "➕", mod = loadModule("PageAdd") },
		{ id = "trade",    short = "Трейд",     icon = "🔄", mod = loadModule("PageTrade") },
		{ id = "catalog",  short = "Каталог",   icon = "📖", mod = loadModule("PageCatalog") },
		{ id = "settings", short = "Настройки", icon = "⚙", mod = loadModule("PageSettings") },
		{ id = "info",     short = "О проекте", icon = "ℹ", mod = loadModule("PageInfo") },
	}
	Ctx.UI.start()
end)

if not ok then
	notify("Ошибка запуска: " .. tostring(err))
	Ctx.Destroy()
end
return Ctx
