-- Platoboost adapter for Ophyn.
--
--   KeySystem = {
--       API = {
--           {
--               Type = "platoboost",
--               ServiceId = 1234,               -- your Platoboost service id
--               Secret = "platoboost-secret",   -- your Platoboost secret
--           },
--       },
--   }
--
-- Based on Platoboost's official Lua library. The SHA-256 below is copied
-- from it unchanged; the requests use HttpService for JSON.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- SHA-256 (hex digest) from the official Platoboost library.
local sha256 = (function()
local a=2^32;local b=a-1;local function c(d,e)local f,g=0,1;while d~=0 or e~=0 do local h,i=d%2,e%2;local j=(h+i)%2;f=f+j*g;d=math.floor(d/2)e=math.floor(e/2)g=g*2 end;return f%a end;local function k(d,e,l,...)local m;if e then d=d%a;e=e%a;m=c(d,e)if l then m=k(m,l,...)end;return m elseif d then return d%a else return 0 end end;local function n(d,e,l,...)local m;if e then d=d%a;e=e%a;m=(d+e-c(d,e))/2;if l then m=n(m,l,...)end;return m elseif d then return d%a else return b end end;local function o(p)return b-p end;local function q(d,r)if r<0 then return lshift(d,-r)end;return math.floor(d%2^32/2^r)end;local function s(p,r)if r>31 or r<-31 then return 0 end;return q(p%a,r)end;local function lshift(d,r)if r<0 then return s(d,-r)end;return d*2^r%2^32 end;local function t(p,r)p=p%a;r=r%32;local u=n(p,2^r-1)return s(p,r)+lshift(u,32-r)end;local v={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(x)return string.gsub(x,".",function(l)return string.format("%02x",string.byte(l))end)end;local function y(z,A)local x=""for B=1,A do local C=z%256;x=string.char(C)..x;z=(z-C)/256 end;return x end;local function D(x,B)local A=0;for B=B,B+3 do A=A*256+string.byte(x,B)end;return A end;local function E(F,G)local H=64-(G+9)%64;G=y(8*G,8)F=F.."\128"..string.rep("\0",H)..G;assert(#F%64==0)return F end;local function I(J)J[1]=0x6a09e667;J[2]=0xbb67ae85;J[3]=0x3c6ef372;J[4]=0xa54ff53a;J[5]=0x510e527f;J[6]=0x9b05688c;J[7]=0x1f83d9ab;J[8]=0x5be0cd19;return J end;local function K(F,B,J)local L={}for M=1,16 do L[M]=D(F,B+(M-1)*4)end;for M=17,64 do local N=L[M-15]local O=k(t(N,7),t(N,18),s(N,3))N=L[M-2]L[M]=(L[M-16]+O+L[M-7]+k(t(N,17),t(N,19),s(N,10)))%a end;local d,e,l,P,Q,R,S,T=J[1],J[2],J[3],J[4],J[5],J[6],J[7],J[8]for B=1,64 do local O=k(t(d,2),t(d,13),t(d,22))local U=k(n(d,e),n(d,l),n(e,l))local V=(O+U)%a;local W=k(t(Q,6),t(Q,11),t(Q,25))local X=k(n(Q,R),n(o(Q),S))local Y=(T+W+X+v[B]+L[B])%a;T=S;S=R;R=Q;Q=(P+Y)%a;P=l;l=e;e=d;d=(Y+V)%a end;J[1]=(J[1]+d)%a;J[2]=(J[2]+e)%a;J[3]=(J[3]+l)%a;J[4]=(J[4]+P)%a;J[5]=(J[5]+Q)%a;J[6]=(J[6]+R)%a;J[7]=(J[7]+S)%a;J[8]=(J[8]+T)%a end;local function Z(F)F=E(F,#F)local J=I({})for B=1,#F,64 do K(F,B,J)end;return w(y(J[1],4)..y(J[2],4)..y(J[3],4)..y(J[4],4)..y(J[5],4)..y(J[6],4)..y(J[7],4)..y(J[8],4))end;
	return Z
end)()

local Platoboost = {}
Platoboost.__index = Platoboost

local HOSTS = { "https://api.platoboost.com", "https://api.platoboost.net" }
local LINK_CACHE_TIME = 10 * 60
local RATE_LIMIT_MESSAGE = "you are being rate limited, please wait 20 seconds and try again."
local BAD_STATUS_MESSAGE = "server returned an invalid status code, please try again later."
local JSON_HEADERS = { ["Content-Type"] = "application/json" }

local rng = Random.new()

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
	local lp = Players.LocalPlayer
	return tostring(lp and lp.UserId or 0)
end

local function generateNonce()
	local chars = table.create(16)
	for i = 1, 16 do
		chars[i] = string.char(rng:NextInteger(97, 122))
	end
	return table.concat(chars)
end

local function decode(body)
	local ok, result = pcall(HttpService.JSONDecode, HttpService, body)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

function Platoboost.new(config)
	config = config or {}
	local self = setmetatable({}, Platoboost)
	self.__isPlatoboostInstance = true

	local service = config.ServiceId or config.Service or config.service
	self.service = tonumber(service) or service
	self.secret = config.Secret or config.secret

	local useNonce = config.UseNonce
	if useNonce == nil then
		useNonce = config.useNonce
	end
	self.useNonce = useNonce ~= false

	self.host = nil
	self.identifier = nil
	self.requestSending = false
	self.cachedLink = nil
	self.cachedTime = 0

	if self.service == nil or self.service == "" then
		warn("[Platoboost] ServiceId is missing — check your Platoboost dashboard")
	end
	if self.useNonce and (type(self.secret) ~= "string" or self.secret == "") then
		warn("[Platoboost] Secret is missing — keys can't be verified without it")
	end

	return self
end

-- .com first, .net as the fallback (same behavior the official library intends)
function Platoboost:_host()
	if self.host then
		return self.host
	end
	local req = getRequestFunction()
	if req then
		local ok, res = pcall(req, { Url = HOSTS[1] .. "/public/connectivity", Method = "GET" })
		if ok and type(res) == "table" and (res.StatusCode == 200 or res.StatusCode == 429) then
			self.host = HOSTS[1]
			return self.host
		end
	end
	self.host = HOSTS[2]
	return self.host
end

function Platoboost:_identifier()
	if not self.identifier then
		self.identifier = sha256(getHwid())
	end
	return self.identifier
end

function Platoboost:_send(options)
	local req = getRequestFunction()
	if not req then
		return nil, "your executor doesn't support HTTP requests."
	end
	local ok, res = pcall(req, options)
	if not ok then
		return nil, tostring(res)
	end
	if type(res) ~= "table" then
		return nil, "invalid response from server."
	end
	return res
end

-- Returns link, or nil + reason
function Platoboost:GetKeyLink()
	if self.cachedLink and self.cachedTime + LINK_CACHE_TIME > os.time() then
		return self.cachedLink
	end
	if self.service == nil or self.service == "" then
		return nil, "Platoboost ServiceId is missing."
	end

	local res, err = self:_send({
		Url = self:_host() .. "/public/start",
		Method = "POST",
		Body = HttpService:JSONEncode({
			service = self.service,
			identifier = self:_identifier(),
		}),
		Headers = JSON_HEADERS,
	})
	if not res then
		return nil, err
	end

	if res.StatusCode == 200 then
		local decoded = decode(res.Body)
		if decoded then
			if decoded.success == true and type(decoded.data) == "table" and decoded.data.url then
				self.cachedLink = decoded.data.url
				self.cachedTime = os.time()
				return self.cachedLink
			end
			return nil, tostring(decoded.message or "Failed to get link.")
		end
	elseif res.StatusCode == 429 then
		return nil, RATE_LIMIT_MESSAGE
	end
	return nil, "Failed to get link."
end

-- With UseNonce the server signs its answer with the secret; check it.
function Platoboost:_integrityOk(data, nonce)
	if not self.useNonce then
		return true
	end
	return data.hash == sha256("true" .. "-" .. nonce .. "-" .. tostring(self.secret))
end

function Platoboost:_redeem(key)
	local nonce = generateNonce()
	local body = {
		identifier = self:_identifier(),
		key = key,
	}
	if self.useNonce then
		body.nonce = nonce
	end

	local res, err = self:_send({
		Url = self:_host() .. "/public/redeem/" .. tostring(self.service),
		Method = "POST",
		Body = HttpService:JSONEncode(body),
		Headers = JSON_HEADERS,
	})
	if not res then
		return false, err
	end
	if res.StatusCode == 429 then
		return false, RATE_LIMIT_MESSAGE
	end
	if res.StatusCode ~= 200 then
		return false, BAD_STATUS_MESSAGE
	end

	local decoded = decode(res.Body)
	if not decoded then
		return false, "invalid response from server."
	end
	if decoded.success ~= true then
		local message = tostring(decoded.message or "request failed.")
		if message:sub(1, 27) == "unique constraint violation" then
			return false, "you already have an active key, please wait for it to expire before redeeming it."
		end
		return false, message
	end

	local data = type(decoded.data) == "table" and decoded.data or {}
	if data.valid ~= true then
		return false, "key is invalid."
	end
	if not self:_integrityOk(data, nonce) then
		return false, "failed to verify integrity."
	end
	return true
end

function Platoboost:_verify(key)
	local nonce = generateNonce()
	local url = self:_host()
		.. "/public/whitelist/"
		.. tostring(self.service)
		.. "?identifier="
		.. self:_identifier()
		.. "&key="
		.. HttpService:UrlEncode(key)
	if self.useNonce then
		url = url .. "&nonce=" .. nonce
	end

	local res, err = self:_send({ Url = url, Method = "GET" })
	if not res then
		return false, err
	end
	if res.StatusCode == 429 then
		return false, RATE_LIMIT_MESSAGE
	end
	if res.StatusCode ~= 200 then
		return false, BAD_STATUS_MESSAGE
	end

	local decoded = decode(res.Body)
	if not decoded then
		return false, "invalid response from server."
	end
	if decoded.success ~= true then
		return false, tostring(decoded.message or "request failed.")
	end

	local data = type(decoded.data) == "table" and decoded.data or {}
	if data.valid == true then
		if not self:_integrityOk(data, nonce) then
			return false, "failed to verify integrity."
		end
		return true
	end

	-- Keys from the Platoboost site start with KEY_ and must be redeemed first
	if key:sub(1, 4) == "KEY_" then
		return self:_redeem(key)
	end
	return false, "key is invalid."
end

-- Returns valid (boolean), reason (string when invalid)
function Platoboost:CheckKey(key)
	key = tostring(key or ""):match("^%s*(.-)%s*$")
	if key == "" then
		return false, "key is empty."
	end
	if self.service == nil or self.service == "" then
		return false, "Platoboost ServiceId is missing."
	end
	if self.useNonce and (type(self.secret) ~= "string" or self.secret == "") then
		return false, "Platoboost Secret is missing."
	end
	if self.requestSending then
		return false, "a request is already being sent, please slow down."
	end

	self.requestSending = true
	local ok, valid, reason = pcall(self._verify, self, key)
	self.requestSending = false

	if not ok then
		return false, tostring(valid)
	end
	return valid == true, reason
end

function Platoboost:Validator()
	local instance = self
	return setmetatable({
		__isPlatoboost = true,
		__instance = instance,
	}, {
		__call = function(_, key)
			return instance:CheckKey(key)
		end,
	})
end

return Platoboost
