local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- The prototype renders its own player sprite and has no 3D avatar.
Players.CharacterAutoLoads = false

local studio = RunService:IsStudio()

-- Set the Creator Hub product IDs here after publishing the experience.
local packages = {
	{ fragments = 10, productId = 0 },
	{ fragments = 25, productId = 0 },
	{ fragments = 50, productId = 0 },
}
local capeCosts = { curta = 3, nevoa = 6 }
local products = {}
for _, package in packages do
	if package.productId > 0 then
		assert(not products[package.productId], "ID de pacote duplicado")
		products[package.productId] = package.fragments
	end
end

local walletStore = if studio or next(products) == nil then nil
	else DataStoreService:GetDataStore("LuarDeCinzas_Fragmentos_v1")
local function emptyWallet()
	return { balance = 0, owned = {}, receipts = {}, revision = 0 }
end

local function showWallet(player, wallet)
	if player and wallet.revision >= (player:GetAttribute("VersaoCarteira") or -1) then
		player:SetAttribute("VersaoCarteira", wallet.revision)
		player:SetAttribute("CarteiraLua", HttpService:JSONEncode({
			balance = wallet.balance,
			owned = wallet.owned,
		}))
	end
end

local function loadWallet(player)
	if walletStore then
		local ok, wallet = pcall(walletStore.GetAsync, walletStore, tostring(player.UserId))
		if ok then
			showWallet(player, wallet or emptyWallet())
		end
	end
end
Players.PlayerAdded:Connect(loadWallet)
for _, player in Players:GetPlayers() do
	task.spawn(loadWallet, player)
end

MarketplaceService.ProcessReceipt = function(receipt)
	local amount = products[receipt.ProductId]
	if not walletStore or not amount then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, wallet = pcall(walletStore.UpdateAsync, walletStore, tostring(receipt.PlayerId), function(previous)
		local data = previous or emptyWallet()
		if not data.receipts[receipt.PurchaseId] then
			data.balance += amount
			data.revision += 1
			data.receipts[receipt.PurchaseId] = true
		end
		return data
	end)
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	showWallet(Players:GetPlayerByUserId(receipt.PlayerId), wallet)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local shopRequest = Instance.new("RemoteFunction")
shopRequest.Name = "LojaLua"
shopRequest.OnServerInvoke = function(player, action, cape)
	if action == "pacotes" then
		return packages, walletStore ~= nil
	end
	local price = if typeof(cape) == "string" then capeCosts[cape] else nil
	if action ~= "capa" or not price or not walletStore then
		return false
	end
	local ok, wallet = pcall(walletStore.UpdateAsync, walletStore, tostring(player.UserId), function(previous)
		local data = previous or emptyWallet()
		if not data.owned[cape] and data.balance >= price then
			data.balance -= price
			data.owned[cape] = true
			data.revision += 1
		end
		return data
	end)
	if ok then
		showWallet(player, wallet)
		return wallet.owned[cape] == true
	end
	return false
end
shopRequest.Parent = ReplicatedStorage

local store = if studio then nil else DataStoreService:GetDataStore("LuarDeCinzas_Recordes_v2")
local rankingStore = if studio then nil else DataStoreService:GetDataStore("LuarDeCinzas_Ranking_v2")
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
		or milliseconds ~= math.floor(milliseconds) or milliseconds < 1 or milliseconds > 720000
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
