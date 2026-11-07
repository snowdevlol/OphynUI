-- Based In LuaProtect Docs: https://docs.luaprotect.dev/api-keys-validate-public

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local VALIDATE_URL = "https://api.luaprotect.dev/v1/public/validate-key"

local LuaProtect = {}
LuaProtect.__index = LuaProtect

local function getRequestFunction()
	return request or http_request or (syn and syn.request) or (http and http.request)
end

local function getHwid()
	if gethwid then
		local ok, hwid = pcall(gethwid)
		if ok and hwid ~= nil and tostring(hwid) ~= "" then
			return tostring(hwid)
		end
	end
	local okClient, clientId = pcall(function()
		return game:GetService("RbxAnalyticsService"):GetClientId()
	end)
	if okClient and clientId and tostring(clientId) ~= "" then
		return tostring(clientId)
	end
	local lp = Players.LocalPlayer
	return tostring(lp and lp.UserId or 0)
end

local function decode(body)
	local ok, result = pcall(HttpService.JSONDecode, HttpService, body)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

function LuaProtect.new(config)
	config = config or {}
	local self = setmetatable({}, LuaProtect)
	self.__isLuaProtectInstance = true

	self.user = config.User or config.user or config.Username or config.username
	self.scriptId = config.ScriptId or config.scriptId or config.Script
	self.flow = config.Flow or config.flow
	self.getKeyUrl = config.GetKeyUrl or config.getKeyUrl or config.URL or config.Url
	self.hwid = config.Hwid or config.HWID or config.hwid
	self.requestSending = false

	if not (self.user or self.scriptId or self.flow) then
		warn("[LuaProtect] User is missing — set User = \"your_username\" (or ScriptId / Flow)")
	end

	return self
end

function LuaProtect:_hwid()
	if not self.hwid then
		self.hwid = getHwid()
	end
	return tostring(self.hwid)
end

local function appendQuery(url, name, value)
	if value == nil or tostring(value) == "" then
		return url
	end
	return url .. "&" .. name .. "=" .. HttpService:UrlEncode(tostring(value))
end

function LuaProtect:_check(key)
	local req = getRequestFunction()
	if not req then
		warn("your executor doesn't support HTTP requests.")
		return false
	end

	local url = VALIDATE_URL .. "?key=" .. HttpService:UrlEncode(key)
	url = appendQuery(url, "user", self.user)
	url = appendQuery(url, "scriptId", self.scriptId)
	url = appendQuery(url, "flow", self.flow)
	url = appendQuery(url, "hwid", self:_hwid())

	local okReq, res = pcall(req, { Url = url, Method = "GET" })
	if not okReq or type(res) ~= "table" then
		warn("network error, please try again.")
		return false
	end
	if res.StatusCode == 429 then
		warn("you are being rate limited, please wait a moment and try again.")
		return false
	end

	local data = type(res.Body) == "string" and decode(res.Body) or nil
	if not data then
		warn("invalid response from server.")
		return false
	end

	if data.valid == true then
		self.lastResult = data
		return true
	end

	local reason = data.reason or data.message or data.error
	warn(reason and tostring(reason) or "key is invalid or expired.")
	return false
end

function LuaProtect:CheckKey(key)
	key = tostring(key or ""):match("^%s*(.-)%s*$")
	if key == "" then
		warn("key is empty.")
		return false
	end
	if not (self.user or self.scriptId or self.flow) then
		warn("LuaProtect User (or ScriptId / Flow) is missing.")
		return false
	end
	if self.requestSending then
		warn("a request is already being sent, please slow down.")
		return false
	end

	self.requestSending = true
	local ok, valid = pcall(self._check, self, key)
	self.requestSending = false

	if not ok then
		warn("error checking key")
		return false
	end
	return valid == true
end

function LuaProtect:GetKeyLink()
	if type(self.getKeyUrl) == "string" and self.getKeyUrl ~= "" then
		return self.getKeyUrl
	end
	warn("LuaProtect GetKeyUrl is not set.")
	return nil
end

function LuaProtect:Validator()
	local instance = self
	return setmetatable({
		__isLuaProtect = true,
		__instance = instance,
	}, {
		__call = function(_, key)
			return instance:CheckKey(key)
		end,
	})
end

return LuaProtect
