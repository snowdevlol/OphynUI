local SDK_URL = "https://jnkie.com/sdk/library.lua"

local Jnkie = {}
Jnkie.__index = Jnkie

local function safeLoad(url)
	if not loadstring then
		return nil, "loadstring is not available"
	end
	local ok, result = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		return nil, tostring(result)
	end
	local fn, compileErr = loadstring(result)
	if not fn then
		return nil, tostring(compileErr)
	end
	local okRun, lib = pcall(fn)
	if not okRun then
		return nil, tostring(lib)
	end
	return lib
end

function Jnkie.new(config)
	config = config or {}
	local self = setmetatable({}, Jnkie)
	self.__isJnkieInstance = true
	self.service = config.Service or config.service
	self.identifier = config.Identifier or config.identifier
	self.provider = config.Provider or config.provider or "Mixed"
	self.client = nil
	self.loadError = nil

	if not self.service or self.service == "" then
		warn("[Jnkie] Service is missing — check your dashboard for the exact name")
	end
	if not self.identifier or self.identifier == "" then
		warn("[Jnkie] Identifier is missing — check your dashboard for your user ID")
	end

	return self
end

function Jnkie:_client()
	if self.client then
		return self.client
	end
	local lib, err = safeLoad(SDK_URL)
	if not lib then
		self.loadError = err
		warn("[Jnkie] failed to load SDK: " .. tostring(err))
		return nil
	end
	lib.service = self.service
	lib.identifier = self.identifier
	lib.provider = self.provider
	self.client = lib
	return lib
end

local function isSuccess(result)
	if type(result) ~= "table" then
		return false
	end
	if result.valid == true or result.success == true then
		return true
	end
	if result.message == "KEY_VALID" or result.message == "KEYLESS" then
		return true
	end
	return false
end

function Jnkie:CheckKey(key)
	local lib = self:_client()
	if not lib then
		return { valid = false, error = self.loadError or "SDK_LOAD_FAILED" }
	end
	local ok, result = pcall(lib.check_key, key)
	if not ok then
		return { valid = false, error = tostring(result) }
	end
	if type(result) ~= "table" then
		return { valid = false, error = "UNEXPECTED_RESPONSE: " .. tostring(result) }
	end
	result.valid = isSuccess(result)
	return result
end

function Jnkie:GetKeyLink()
	local lib = self:_client()
	if not lib then
		return nil, self.loadError or "SDK_LOAD_FAILED"
	end
	local ok, link, err = pcall(lib.get_key_link)
	if not ok then
		return nil, tostring(link)
	end
	return link, err
end

function Jnkie:Validator()
	local instance = self
	local adapter = setmetatable({
		__isJnkie = true,
		__instance = instance,
	}, {
		__call = function(_, key)
			local result = instance:CheckKey(key)
			local reason = result and (result.error or result.message)
			return result and result.valid == true, reason
		end,
	})
	return adapter
end

return Jnkie
