-- Settings.lua — настройки и безопасное файловое хранилище (writefile/readfile, если поддерживаются)
local Ctx = ...
local HttpService = game:GetService("HttpService")

local FOLDER = "AdoptMeUltimate"
local DEFAULTS = { animations = true, transparency = 0, scale = 1, theme = "dark" }

local S = {}
local values = {}
local listeners = {}

S.canSave = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"

function S.readJson(name)
	if not S.canSave then return nil end
	local path = FOLDER .. "/" .. name
	local ok, res = pcall(function()
		if not isfile(path) then return nil end
		return HttpService:JSONDecode(readfile(path))
	end)
	if ok then return res end
	return nil
end

function S.writeJson(name, data)
	if not S.canSave then return false end
	pcall(function()
		if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(FOLDER) then
			makefolder(FOLDER)
		end
	end)
	local ok = pcall(function() writefile(FOLDER .. "/" .. name, HttpService:JSONEncode(data)) end)
	return ok
end

local function notify(k, v)
	for _, f in ipairs(listeners) do pcall(f, k, v) end
end

function S.load()
	for k, v in pairs(DEFAULTS) do values[k] = v end
	local data = S.readJson("settings.json")
	if type(data) == "table" then
		for k, v in pairs(data) do
			if DEFAULTS[k] ~= nil and type(v) == type(DEFAULTS[k]) then values[k] = v end
		end
	end
	values.transparency = math.clamp(values.transparency, 0, 0.6)
	values.scale = math.clamp(values.scale, 0.7, 1.4)
end

function S.get(k) return values[k] end

function S.save() S.writeJson("settings.json", values) end

function S.set(k, v, noSave)
	if DEFAULTS[k] == nil or values[k] == v then return end
	values[k] = v
	if not noSave then S.save() end
	notify(k, v)
end

function S.reset()
	for k, v in pairs(DEFAULTS) do values[k] = v end
	S.save()
	notify("*", nil)
end

function S.onChanged(f)
	table.insert(listeners, f)
	return function()
		local i = table.find(listeners, f)
		if i then table.remove(listeners, i) end
	end
end

S.load()
return S
