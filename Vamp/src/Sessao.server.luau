local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- The prototype renders its own player sprite and has no 3D avatar.
Players.CharacterAutoLoads = false

local studio = RunService:IsStudio()
local store = if studio then nil else DataStoreService:GetDataStore("LuarDeCinzas_Recordes_v1")
local rankingStore = if studio then nil else DataStoreService:GetDataStore("LuarDeCinzas_Ranking_v1")
local sessionRecords = {}
local nextSave = {}
local ranking = {}
local rankingReadAt = -math.huge
local rankingReading = false

local function insertBest(previous, candidate)
	local entries = {}
	for _, entry in previous or {} do
		if entry.key == candidate.key then
			if entry.milliseconds < candidate.milliseconds then
				candidate = entry
			end
		else
			table.insert(entries, entry)
		end
	end
	table.insert(entries, candidate)
	table.sort(entries, function(a, b)
		if a.milliseconds == b.milliseconds then
			return a.key < b.key
		end
		return a.milliseconds < b.milliseconds
	end)
	if #entries > 10 then
		table.remove(entries)
	end
	return entries
end

local function readRanking()
	if rankingStore and not rankingReading and os.clock() - rankingReadAt >= 15 then
		rankingReading = true
		local lastRead = rankingReadAt
		local ok, rows = pcall(rankingStore.GetAsync, rankingStore, "Top10")
		rankingReading = false
		if not ok then
			return false
		end
		if rankingReadAt == lastRead then
			ranking = rows or {}
			rankingReadAt = os.clock()
		end
	end
	local rows = {}
	for i, entry in ranking do
		rows[i] = { name = entry.name, milliseconds = entry.milliseconds }
	end
	return true, rows
end

local recordRequest = Instance.new("RemoteFunction")
recordRequest.Name = "RecordeDaFase"

recordRequest.OnServerInvoke = function(player, action, milliseconds, name)
	local key = tostring(player.UserId)
	if action == "listar" then
		return readRanking()
	end
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

	local ok, record, ranked = pcall(function()
		local filtered, safeName = pcall(function()
			return TextService:FilterStringAsync(name, player.UserId):GetNonChatStringForBroadcastAsync()
		end)
		if not filtered and not studio then
			error("Filtro de texto indisponível")
		end
		local displayName = if filtered then safeName else player.Name
		local candidate = { name = displayName, publicName = displayName, milliseconds = milliseconds }
		local function keepBest(previous)
			return if previous and previous.milliseconds < milliseconds then previous else candidate
		end
		local best
		if store then
			best = store:UpdateAsync(key, keepBest)
		else
			sessionRecords[key] = keepBest(sessionRecords[key])
			best = sessionRecords[key]
		end
		-- Older records have private names. Use the Roblox username for those times.
		local entry = { key = key, name = best.publicName or player.Name, milliseconds = best.milliseconds }
		if rankingStore then
			local updated, rows = pcall(function()
				return rankingStore:UpdateAsync("Top10", function(previous)
					return insertBest(previous, entry)
				end)
			end)
			if updated then
				ranking = rows
				rankingReadAt = os.clock()
			end
			return best, updated
		end
		ranking = insertBest(ranking, entry)
		return best, true
	end)
	return ok, if ok then record else nil, ranked == true
end

Players.PlayerRemoving:Connect(function(player)
	nextSave[tostring(player.UserId)] = nil
end)
recordRequest.Parent = ReplicatedStorage
