local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- The prototype renders its own player sprite and has no 3D avatar.
Players.CharacterAutoLoads = false

local studio = RunService:IsStudio()
local store = if studio then nil else DataStoreService:GetDataStore("LuarDeCinzas_Recordes_v1")
local sessionRecords = {}
local nextSave = {}

local recordRequest = Instance.new("RemoteFunction")
recordRequest.Name = "RecordeDaFase"

recordRequest.OnServerInvoke = function(player, action, milliseconds, name)
	local key = tostring(player.UserId)
	if action == "consultar" then
		local ok, record = pcall(function()
			return if store then store:GetAsync(key) else sessionRecords[key]
		end)
		return ok, record
	end
	if action ~= "salvar" or typeof(milliseconds) ~= "number"
		or milliseconds ~= math.floor(milliseconds) or milliseconds < 1 or milliseconds > 360000
		or typeof(name) ~= "string" or #name > 96 then
		return false
	end
	name = string.match(name, "^%s*(.-)%s*$")
	local length = utf8.len(name)
	if not length or length == 0 or length > 24 or string.find(name, "%c") then
		return false
	end
	local now = os.clock()
	if now < (nextSave[key] or 0) then
		return false
	end
	nextSave[key] = now + 2

	local ok, record = pcall(function()
		local filtered, safeName = pcall(function()
			return TextService:FilterStringAsync(name, player.UserId):GetNonChatStringForUserAsync(player.UserId)
		end)
		if not filtered and not studio then
			error("Filtro de texto indisponível")
		end
		local candidate = { name = if filtered then safeName else player.Name, milliseconds = milliseconds }
		local function keepBest(previous)
			return if previous and previous.milliseconds < milliseconds then previous else candidate
		end
		if store then
			return store:UpdateAsync(key, keepBest)
		end
		sessionRecords[key] = keepBest(sessionRecords[key])
		return sessionRecords[key]
	end)
	return ok, if ok then record else nil
end

Players.PlayerRemoving:Connect(function(player)
	nextSave[tostring(player.UserId)] = nil
end)
recordRequest.Parent = ReplicatedStorage
