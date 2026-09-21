local LIB_URL = "https://secure.pandauth.com/pv4/lib"

local REASONS = {
	INVALID_KEY = "key is invalid or expired.",
	RATE_LIMITED = "you are being rate limited, please wait a moment and try again.",
	NETWORK = "network error, please try again.",
	NO_SERVICE = "Panda ServiceId is missing or invalid.",
	NO_KEY = "key is empty.",
	NO_HTTP = "your executor doesn't support HTTP requests.",
	IDENTITY = "couldn't verify the Panda server identity, please try again later.",
	PROTOCOL = "Panda protocol error, please try again later.",
}

local Panda = {}
Panda.__index = Panda

function Panda.new(config)
	config = config or {}
	local self = setmetatable({}, Panda)

	local serviceId = config.ServiceId or config.Service or config.serviceId
	self.serviceId = serviceId ~= nil and tostring(serviceId) or ""
	self.debug = config.Debug == true

	self.lib = nil
	self.loading = false

	if self.serviceId == "" then
		warn("[Panda] ServiceId is missing — check your Panda dashboard")
	end

	return self
end

function Panda:_load()
	while self.loading do
		task.wait(0.1)
	end
	if self.lib then
		return self.lib
	end
	if self.serviceId == "" then
		return nil, REASONS.NO_SERVICE
	end

	self.loading = true
	local lib, err

	local okFetch, src = pcall(function()
		return game:HttpGet(LIB_URL)
	end)
	if not okFetch or type(src) ~= "string" or src == "" then
		err = "couldn't download the Panda library."
	elseif not loadstring then
		err = "loadstring is not available."
	else
		local fn, compileError = loadstring(src)
		if not fn then
			err = "couldn't load the Panda library: " .. tostring(compileError)
		else
			local okRun, result = pcall(fn)
			if okRun and type(result) == "table" and type(result.configure) == "function" then
				local okConfig, configError = pcall(result.configure, {
					serviceId = self.serviceId,
					debug = self.debug,
					kickOnDetect = false,
				})
				if okConfig then
					lib = result
				else
					err = "couldn't configure the Panda library: " .. tostring(configError)
				end
			else
				err = "Panda library failed to initialize."
			end
		end
	end

	self.loading = false
	if lib then
		self.lib = lib
		return lib
	end
	return nil, err
end

function Panda:CheckKey(key)
	key = tostring(key or ""):match("^%s*(.-)%s*$")
	if key == "" then
		return false, REASONS.NO_KEY
	end

	local lib, err = self:_load()
	if not lib then
		return false, err
	end

	if type(lib.validateEx) == "function" then
		local ok, valid, reason = pcall(lib.validateEx, key)
		if not ok then
			return false, tostring(valid)
		end
		if valid == true then
			return true
		end
		return false, REASONS[reason] or ("Panda error: " .. tostring(reason))
	end

	local ok, result = pcall(lib.validate, key)
	if not ok then
		return false, tostring(result)
	end
	if type(result) == "table" and result.success == true then
		return true
	end
	local reason = type(result) == "table" and (result.reason or result.error) or nil
	return false, REASONS[reason] or tostring(reason or "key is invalid.")
end

function Panda:GetKeyLink()
	local lib, err = self:_load()
	if not lib then
		return nil, err
	end
	if type(lib.getKeyUrl) ~= "function" then
		return nil, "Panda library has no getKeyUrl."
	end
	local ok, url = pcall(lib.getKeyUrl)
	if ok and type(url) == "string" and url ~= "" then
		return url
	end
	return nil, "Failed to get link."
end

return Panda
