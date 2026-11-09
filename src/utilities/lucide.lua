local Lucide = {}

-- The pack is downloaded once. Several mirrors are tried in order, because some executors /
-- networks block one host (raw.githubusercontent.com, for example) and not the others.
local PACK_URLS = {
	"https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
	"https://raw.githubusercontent.com/Footagesus/Icons/main/lucide/dist/Icons.lua",
	"https://cdn.jsdelivr.net/gh/Footagesus/Icons@main/lucide/dist/Icons.lua",
	"https://fastly.jsdelivr.net/gh/Footagesus/Icons@main/lucide/dist/Icons.lua",
}
local CACHE_FILE = "Ophyn-LucidePack.lua" -- last pack that downloaded fine (if the executor has files)
local RETRY_AFTER = 10 -- seconds before a failed download is tried again

-- Old Lucide names -> the current ones in the pack
local ALIASES = {
	home = "house",
	cog = "settings",
	["alert-triangle"] = "triangle-alert",
	["alert-circle"] = "circle-alert",
	["alert-octagon"] = "octagon-alert",
	["check-circle"] = "circle-check",
	["check-circle-2"] = "circle-check",
	["x-circle"] = "circle-x",
	["help-circle"] = "circle-help",
	["user-circle"] = "circle-user",
	["play-circle"] = "circle-play",
	["pause-circle"] = "circle-pause",
	["plus-circle"] = "circle-plus",
	["minus-circle"] = "circle-minus",
	["bar-chart"] = "chart-no-axes-column",
	["bar-chart-2"] = "chart-no-axes-column-increasing",
	["line-chart"] = "chart-line",
	["pie-chart"] = "chart-pie",
	["loader"] = "loader-circle",
	["edit"] = "square-pen",
	["trash"] = "trash-2",
}

local pack = nil
local loading = false
local failedAt = nil
local warnedLoad = false
local preloaded = {}
local warned = {}
local pending = setmetatable({}, { __mode = "k" }) -- ImageLabel -> value waiting for the pack

local loadFn = loadstring or load

local function fetch(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end
	ok, body = pcall(function()
		return game:HttpGetAsync(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end
	-- some executors only expose request()/http_request()
	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if type(req) == "function" then
		ok, body = pcall(req, { Url = url, Method = "GET" })
		if ok and type(body) == "table" and type(body.Body) == "string" and body.Body ~= "" then
			if body.StatusCode == nil or body.StatusCode == 200 then
				return body.Body
			end
		end
	end
	return nil
end

local function runSource(body)
	if type(loadFn) ~= "function" then
		return nil, "loadstring is not available in this executor"
	end
	local chunk, err = loadFn(body)
	if not chunk then
		return nil, tostring(err)
	end
	local ok, result = pcall(chunk)
	if not ok then
		return nil, tostring(result)
	end
	if type(result) == "function" then -- some packs return a getter
		ok, result = pcall(result)
		if not ok then
			return nil, tostring(result)
		end
	end
	if type(result) ~= "table" then
		return nil, "the icon pack did not return a table"
	end
	return result
end

local function readCache()
	if type(isfile) == "function" and type(readfile) == "function" then
		local ok, body = pcall(function()
			if isfile(CACHE_FILE) then
				return readfile(CACHE_FILE)
			end
		end)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end
	end
	return nil
end

local function writeCache(body)
	if type(writefile) == "function" then
		pcall(writefile, CACHE_FILE, body)
	end
end

-- Returns the pack (or nil). Yields while downloading, so run it in its own thread
-- when the caller can't wait.
local function loadPack()
	if pack then
		return pack
	end
	if failedAt and (os.clock() - failedAt) < RETRY_AFTER then
		return nil
	end
	if loading then
		while loading do
			task.wait()
		end
		return pack
	end

	loading = true
	local errors = {}

	for _, url in ipairs(PACK_URLS) do
		local body = fetch(url)
		if body then
			local result, err = runSource(body)
			if result then
				pack = result
				writeCache(body)
				break
			end
			errors[#errors + 1] = url .. " -> " .. tostring(err)
		else
			errors[#errors + 1] = url .. " -> download failed"
		end
	end

	if not pack then
		local body = readCache()
		if body then
			local result, err = runSource(body)
			if result then
				pack = result
			else
				errors[#errors + 1] = "cache -> " .. tostring(err)
			end
		end
	end

	loading = false

	if not pack then
		failedAt = os.clock()
		if not warnedLoad then
			warnedLoad = true
			warn("[Ophyn] Lucide icons unavailable:\n" .. table.concat(errors, "\n"))
		end
	end
	return pack
end

local function toAsset(value)
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(math.floor(value))
	end
	if type(value) == "string" and value:match("^%d+$") then
		return "rbxassetid://" .. value
	end
	return value
end

function Lucide.isName(value)
	if type(value) ~= "string" or value == "" then
		return false
	end
	if value:match("^%d+$") then
		return false
	end
	if value:match("^rbx%a*://") or value:match("^https?://") then
		return false
	end
	return true
end

-- "lucide:House", "arrowUp", "arrow_up", "Arrow Up" -> "house", "arrow-up", ...
local function normalize(name)
	name = name:match("^%s*(.-)%s*$")
	local lowered = name:lower()
	if lowered:sub(1, 7) == "lucide:" then
		name = name:sub(8)
	elseif lowered:sub(1, 7) == "lucide." then
		name = name:sub(8)
	end
	name = name:gsub("(%l)(%u)", "%1-%2") -- camelCase -> kebab-case
	name = name:gsub("[_%s]+", "-")
	return name:lower()
end

local function preload(sheet)
	if preloaded[sheet] then
		return
	end
	preloaded[sheet] = true
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync({ sheet })
		end)
	end)
end

local function findEntry(loaded, name)
	local icons = loaded.Icons or loaded
	if type(icons) ~= "table" then
		return nil
	end
	local entry = icons[name] or icons["lucide-" .. name]
	if type(entry) ~= "table" and ALIASES[name] then
		entry = icons[ALIASES[name]]
	end
	if type(entry) == "table" then
		return entry
	end
	return nil
end

-- Looks the icon up in a pack that is already loaded (never yields).
local function lookup(value)
	if not pack then
		return nil
	end
	local name = normalize(value)
	local entry = findEntry(pack, name)
	if not entry then
		if not warned[name] then
			warned[name] = true
			warn('[Ophyn] unknown Lucide icon "' .. tostring(value) .. '"')
		end
		return nil
	end

	local sheet = entry.Image
	if type(pack.Spritesheets) == "table" and pack.Spritesheets[tostring(entry.Image)] ~= nil then
		sheet = pack.Spritesheets[tostring(entry.Image)]
	end
	sheet = toAsset(sheet)
	if type(sheet) ~= "string" then
		return nil
	end

	preload(sheet)
	return {
		Image = sheet,
		RectSize = entry.ImageRectSize or entry.RectSize or Vector2.new(0, 0),
		RectOffset = entry.ImageRectPosition or entry.ImageRectOffset or entry.RectOffset or Vector2.new(0, 0),
	}
end

-- Blocking version (waits for the pack to download if needed).
function Lucide.resolve(value)
	if not Lucide.isName(value) then
		return nil
	end
	if not loadPack() then
		return nil
	end
	return lookup(value)
end

local function setSprite(label, sprite)
	label.Image = sprite.Image
	label.ImageRectSize = sprite.RectSize
	label.ImageRectOffset = sprite.RectOffset
end

local function flushPending()
	local items = {}
	for label, value in pairs(pending) do
		items[#items + 1] = { label, value }
	end
	for _, it in ipairs(items) do
		local label, value = it[1], it[2]
		pending[label] = nil
		if label.Parent ~= nil then
			local sprite = lookup(value)
			if sprite then
				setSprite(label, sprite)
			end
		end
	end
end

-- Never blocks the UI: if the pack isn't there yet, the icon is filled in as soon as it
-- finishes downloading (the label stays empty until then).
function Lucide.apply(label, value)
	if not Lucide.isName(value) then
		pending[label] = nil
		label.ImageRectSize = Vector2.new(0, 0)
		label.ImageRectOffset = Vector2.new(0, 0)
		label.Image = value or ""
		return value ~= nil
	end

	if pack then
		local sprite = lookup(value)
		pending[label] = nil
		if sprite then
			setSprite(label, sprite)
			return true
		end
		label.ImageRectSize = Vector2.new(0, 0)
		label.ImageRectOffset = Vector2.new(0, 0)
		label.Image = ""
		return false
	end

	label.ImageRectSize = Vector2.new(0, 0)
	label.ImageRectOffset = Vector2.new(0, 0)
	label.Image = ""
	pending[label] = value

	if not loading and not (failedAt and (os.clock() - failedAt) < RETRY_AFTER) then
		task.spawn(function()
			if loadPack() then
				flushPending()
			end
		end)
	elseif failedAt and not loading then
		-- the last download failed a moment ago: try again once the cooldown is over
		task.delay(RETRY_AFTER, function()
			if not pack and next(pending) ~= nil and loadPack() then
				flushPending()
			end
		end)
	end
	return false
end

return Lucide
