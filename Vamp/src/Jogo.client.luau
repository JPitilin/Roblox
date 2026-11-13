local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Arte = require(script.Arte)
local Fase = require(script.Fase)
local Movimento = require(script.Movimento)

local VIEW_WIDTH = 384
local VIEW_HEIGHT = Fase.height

local function createSound(name, asset, volume, looped)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = asset
	sound.Volume = volume
	sound.Looped = looped
	sound.Parent = SoundService
	return sound
end

local music = createSound("Trilha do cemitério", "rbxassetid://1842988873", 0.18, true)
local jumpSound = createSound("Pulo do Nino", "rbxasset://sounds/action_jump.mp3", 0.28, false)
local hitSound = createSound("Nino atingido", "rbxasset://sounds/ouch.ogg", 0.5, false)
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local touchEnabled = UserInputService.TouchEnabled
if touchEnabled then
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
end
local screen = Instance.new("ScreenGui")
screen.Name = "Luar de Cinzas"
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
screen.Parent = playerGui

local backdrop = Arte.rect(screen, 0, 0, 0, 0, 8, 1)
backdrop.Size = UDim2.fromScale(1, 1)
local viewport = Arte.rect(backdrop, 0, 0, VIEW_WIDTH, VIEW_HEIGHT, 15, 1)
viewport.AnchorPoint = Vector2.new(0.5, 0.5)
viewport.Position = UDim2.fromScale(0.5, 0.5)
viewport.ClipsDescendants = true
local zoom = Instance.new("UIScale")
zoom.Parent = viewport
local touchBarHeight = if touchEnabled then 60 else 0
local touchBar = Arte.layer(backdrop, "Controles de toque", 0, touchBarHeight, 13)
touchBar.AnchorPoint = Vector2.new(0, 1)
touchBar.Position = UDim2.fromScale(0, 1)
touchBar.Size = UDim2.new(1, 0, 0, touchBarHeight)
touchBar.Visible = false

local function touchButton(text, x, width, rightAligned)
	local button = Arte.text(touchBar, text, x, 4, width, 48, 17, 245, true)
	if rightAligned then
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, x, 0, 4)
	end
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.BackgroundColor3 = Color3.fromRGB(53, 55, 62)
	button.BackgroundTransparency = 0.15
	button.ZIndex = 13
	return button
end
local moveLeftButton = touchButton("◀", 8, 54)
local moveRightButton = touchButton("▶", 70, 54)
local jumpButton = touchButton("PULAR", -8, 84, true)

local function resize()
	local size = backdrop.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		zoom.Scale = math.min(size.X / VIEW_WIDTH, math.max(1, size.Y - touchBarHeight) / VIEW_HEIGHT)
		viewport.Position = UDim2.new(0.5, 0, 0.5, -touchBarHeight / 2)
	end
end
backdrop:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()

local sky, hills = Arte.background(viewport, Fase, VIEW_WIDTH)
local world = Arte.layer(viewport, "Cemitério", Fase.width, VIEW_HEIGHT, 5)
Arte.terrain(world, Fase)
local checkpoints = {}
for _, point in Fase.checkpoints do
	local setLight = Arte.lantern(world, point)
	setLight(false)
	table.insert(checkpoints, { point = point, setLight = setLight })
end
Arte.door(world, Fase.exit)
local nino = Arte.layer(world, "Nino", Arte.ninoWidth, Arte.ninoHeight, 10)
local outfits = {
	{ id = "original", name = "Capa original", detail = "Gola alta vermelha", cost = 0 },
	{ id = "curta", name = "Capa curta", detail = "Ombros largos, corte curto", cost = 3 },
	{ id = "nevoa", name = "Capa de névoa", detail = "Barra recortada e rastro cinza", cost = 6 },
}
local poses = {}
for _, outfit in outfits do
	poses[outfit.id] = Arte.nino(nino, outfit.id)
end

local mist = {}
for i = 1, 8 do
	local puff = Arte.rect(world, 0, 0, 4, 2, 153, 8)
	puff.Visible = false
	mist[i] = { art = puff, age = 0 }
end

local relics = {}
for _, point in Fase.relics do
	local art = Arte.layer(world, "Relíquia", 9, 9, 10)
	Arte.relic(art)
	table.insert(relics, { x = point.x, y = point.y, art = art })
end

local fragments = {}
for _, point in Fase.fragments do
	local art = Arte.layer(world, "Fragmento de Lua", 7, 7, 10)
	Arte.fragment(art)
	table.insert(fragments, { x = point.x, y = point.y, art = art })
end

local bats = {}
for _, path in Fase.bats do
	local art = Arte.layer(world, "Morcego", 15, 7, 10)
	table.insert(bats, { path = path, art = art, wings = Arte.bat(art) })
end

local walkers = {}
local walkerTypes = {
	{ paths = Fase.mummies, name = "Múmia", width = Arte.mummyWidth, height = Arte.mummyHeight,
		hitHeight = 21, cadence = 3, sprite = Arte.mummy, defeat = "Uma múmia acertou Nino." },
	{ paths = Fase.frankensteins, name = "Frankenstein", width = Arte.frankensteinWidth, height = Arte.frankensteinHeight,
		hitHeight = 23, cadence = 2.4, sprite = Arte.frankenstein, defeat = "Um Frankenstein acertou Nino." },
}
for _, kind in walkerTypes do
	for _, path in kind.paths do
		local art = Arte.layer(world, kind.name, kind.width, kind.height, 10)
		table.insert(walkers, { kind = kind, path = path, art = art, poses = kind.sprite(art), x = path.left, facing = 1 })
	end
end

local header = Arte.rect(viewport, 0, 0, VIEW_WIDTH, 33, 10, 11)
header.BackgroundTransparency = 0.12
Arte.rect(viewport, 0, 33, VIEW_WIDTH, 1, 66, 11)
Arte.text(header, "LUAR DE CINZAS", 12, 3, 190, 14, 12, 240)
local timer = Arte.text(header, "", 140, 3, 86, 14, 10, 231)
timer.TextXAlignment = Enum.TextXAlignment.Center
local lifeIcons = {}
for i = 1, Fase.startingLives do
	lifeIcons[i] = Arte.lifeIcon(header, 224 + (i - 1) * 21)
end
local counter = Arte.text(header, "", 288, 3, 84, 14, 10, 231)
counter.TextXAlignment = Enum.TextXAlignment.Right
local controlsHint = if touchEnabled then "" else "A/D   ESPAÇO"
local hint = Arte.text(header, controlsHint, 246, 17, 72, 12, 9, 183)
hint.TextXAlignment = Enum.TextXAlignment.Right
local shopToggle = Arte.text(header, "", 12, 17, 91, 12, 9, Color3.fromRGB(194, 222, 245), true)
local fragmentCounter = Arte.text(header, "", 106, 17, 63, 12, 9, 183)
local rankingToggle = Arte.text(header, if touchEnabled then "RECORDES" else "T RECORDES", 171, 17, 68, 12, 9, Color3.fromRGB(194, 222, 245), true)
local helpToggle = Arte.text(header, if touchEnabled then "AJUDA" else "H AJUDA", 327, 17, 45, 12, 9, Color3.fromRGB(194, 222, 245), true)
helpToggle.TextXAlignment = Enum.TextXAlignment.Right

local panel = Arte.rect(viewport, 52, 54, 280, 130, 15, 11)
Arte.rect(panel, 0, 0, 280, 1, 153, 11)
local panelBorder = Arte.rect(panel, 0, 129, 280, 1, 153, 11)
local title = Arte.text(panel, "", 12, 8, 256, 24, 18, 244)
title.TextXAlignment = Enum.TextXAlignment.Center
local result = Arte.text(panel, "", 12, 32, 256, 15, 11, 209)
result.TextXAlignment = Enum.TextXAlignment.Center
local recordForm = Arte.layer(panel, "Recorde pessoal", 280, 130, 11)
local bestLabel = Arte.text(recordForm, "", 10, 49, 260, 14, 10, 220)
bestLabel.TextXAlignment = Enum.TextXAlignment.Center
bestLabel.TextTruncate = Enum.TextTruncate.AtEnd
local nameInput = Instance.new("TextBox")
nameInput.Name = "Nome do jogador"
nameInput.Position = UDim2.fromOffset(14, 66)
nameInput.Size = UDim2.fromOffset(149, 20)
nameInput.BorderSizePixel = 0
nameInput.BackgroundColor3 = Color3.fromRGB(40, 42, 46)
nameInput.TextColor3 = Color3.fromRGB(245, 245, 245)
nameInput.Font = Enum.Font.Code
nameInput.TextSize = 11
nameInput.PlaceholderText = "Seu nome (até 24)"
nameInput.ClearTextOnFocus = false
nameInput.Text = ""
nameInput.ZIndex = 12
nameInput.Parent = recordForm
local saveRecord = Arte.text(recordForm, "Salvar recorde", 171, 66, 95, 20, 10, 245, true)
saveRecord.TextXAlignment = Enum.TextXAlignment.Center
saveRecord.BackgroundColor3 = Color3.fromRGB(50, 68, 85)
saveRecord.BackgroundTransparency = 0
local recordStatus = Arte.text(recordForm, "", 12, 86, 256, 14, 9, 185)
recordStatus.TextXAlignment = Enum.TextXAlignment.Center
local replay = Arte.text(panel, if touchEnabled then "Recomeçar" else "Recomeçar  [R]", 77, 104, 126, 19, 11, 245, true)
replay.TextXAlignment = Enum.TextXAlignment.Center
replay.BackgroundColor3 = Color3.fromRGB(56, 58, 64)
replay.BackgroundTransparency = 0
panel.Visible = false

local shop = Arte.rect(viewport, 58, 45, 268, 151, 19, 11)
Arte.rect(shop, 0, 0, 268, 1, 134, 11)
Arte.rect(shop, 0, 150, 268, 1, 134, 11)
Arte.text(shop, "CAPAS", 12, 7, 105, 16, 14, 240)
local closeShop = Arte.text(shop, "C  FECHAR", 190, 7, 66, 16, 10, 212, true)
closeShop.TextXAlignment = Enum.TextXAlignment.Right
local shopBalance = Arte.text(shop, "", 12, 25, 244, 14, 10, Color3.fromRGB(194, 222, 245))
local openPackages = Arte.text(shop, "Comprar fragmentos", 12, 134, 244, 14, 10, Color3.fromRGB(194, 222, 245), true)
openPackages.TextXAlignment = Enum.TextXAlignment.Center
for i, outfit in outfits do
	local y = 46 + (i - 1) * 32
	Arte.text(shop, outfit.name, 12, y, 160, 13, 11, 239)
	Arte.text(shop, outfit.detail, 12, y + 13, 178, 11, 9, 173)
	local button = Arte.text(shop, "", 188, y + 2, 68, 20, 9, 230, true)
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.BackgroundColor3 = Color3.fromRGB(53, 55, 58)
	outfit.button = button
end
shop.Visible = false

local packageMenu = Arte.rect(viewport, 58, 45, 268, 151, 19, 11)
Arte.rect(packageMenu, 0, 0, 268, 1, 134, 11)
Arte.rect(packageMenu, 0, 150, 268, 1, 134, 11)
Arte.text(packageMenu, "FRAGMENTOS DE LUA", 12, 7, 170, 16, 13, 240)
local backToCapes = Arte.text(packageMenu, "VOLTAR", 190, 7, 66, 16, 10, 212, true)
backToCapes.TextXAlignment = Enum.TextXAlignment.Right
local walletLabel = Arte.text(packageMenu, "", 12, 27, 244, 13, 10, 210)
local packageStatus = Arte.text(packageMenu, "", 12, 128, 244, 14, 9, 185)
local packageButtons = {}
for i, amount in { 10, 25, 50 } do
	local y = 46 + (i - 1) * 26
	Arte.text(packageMenu, string.format("%d fragmentos", amount), 12, y, 120, 19, 11, 239)
	local button = Arte.text(packageMenu, "", 143, y, 113, 19, 10, 225, true)
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.BackgroundColor3 = Color3.fromRGB(53, 55, 58)
	button.Interactable = false
	packageButtons[i] = button
end
packageMenu.Visible = false

local leaderboard = Arte.rect(viewport, 165, 34, 196, 90, 19, 11)
Arte.rect(leaderboard, 0, 0, 196, 1, 134, 11)
Arte.rect(leaderboard, 0, 89, 196, 1, 134, 11)
Arte.text(leaderboard, "TOP 3 DA FASE", 9, 5, 123, 15, 11, 240)
local closeRanking = Arte.text(leaderboard, "FECHAR", 135, 4, 52, 18, 9, 210, true)
closeRanking.TextXAlignment = Enum.TextXAlignment.Right
local rankingStatus = Arte.text(leaderboard, "", 9, 71, 178, 13, 9, 193)
local rankingRows = {}
for i = 1, 3 do
	local y = 23 + (i - 1) * 15
	local name = Arte.text(leaderboard, "", 9, y, 116, 14, 9, 229)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	local time = Arte.text(leaderboard, "", 130, y, 57, 14, 9, 229)
	time.TextXAlignment = Enum.TextXAlignment.Right
	rankingRows[i] = { name = name, time = time }
end
leaderboard.Visible = false

local helpMenu = Arte.rect(viewport, 35, 42, 314, 164, 19, 11)
Arte.rect(helpMenu, 0, 0, 314, 1, 134, 11)
Arte.rect(helpMenu, 0, 163, 314, 1, 134, 11)
Arte.text(helpMenu, "COMO JOGAR", 12, 6, 160, 18, 14, 244)
local closeHelp = Arte.text(helpMenu, if touchEnabled then "FECHAR" else "H FECHAR", 229, 6, 73, 18, 10, 212, true)
closeHelp.TextXAlignment = Enum.TextXAlignment.Right
local helpText = {
	"Chegue à cripta, desviando dos monstros e abismos.",
	string.format("Você tem %d vidas e %d minutos por vida.", Fase.startingLives, Fase.timeLimit / 60),
	"Sem tempo, ao cair ou ao ser atingido, perde uma vida.",
	"As lanternas azuis são pontos de retorno.",
	"Relíquias douradas são opcionais. Lua troca por capas.",
	"Na vitória, salve seu tempo com um nome em Recordes.",
	"Teclado: A/D anda, Espaço pula, R recomeça.",
	"Atalhos: C capas, T recordes, H ajuda.",
	"Toque: segure ◀ ou ▶ e toque em PULAR.",
}
for i, line in helpText do
	Arte.text(helpMenu, line, 12, 27 + (i - 1) * 14, 290, 14, 9, if i >= 7 then 233 else 200)
end
helpMenu.Visible = false

local player = Movimento.new(Fase.start)
local cameraX = 0
local elapsed = 0
local runTime = 0
local attemptTime = 0
local completedTime
local recordRevision = 0
local savingRecord = false
local shownSeconds
local lives = Fase.startingLives
local accumulator = 0
local collected = 0
local foundFragments = 0
local owned = { original = true }
local purchasedWallet = { balance = 0, owned = {} }
local exchanging = false
local equipped = "original"
local mistSlot = 1
local nextMist = 0
local checkpoint = 0
local won = false
local victoryBlink = 0
local left = false
local right = false
local jumpQueued = false
local leftTouches, rightTouches = {}, {}
local facing = 1
local shownPose

local function capeProgress()
	local balance = foundFragments
	local unlocked = 0
	for _, outfit in outfits do
		if owned[outfit.id] then
			balance -= outfit.cost
		end
		if outfit.cost > 0 and (owned[outfit.id] or purchasedWallet.owned[outfit.id]) then
			unlocked += 1
		end
	end
	return balance, unlocked
end

local function updateShop()
	local balance, unlocked = capeProgress()
	shopToggle.Text = string.format("%sCAPAS %d/%d", if touchEnabled then "" else "C ", unlocked + 1, #outfits)
	fragmentCounter.Text = string.format("LUA %d/%d", foundFragments, #fragments)
	shopBalance.Text = string.format("Mapa: %d   Comprados: %d   Capas: %d/%d", balance, purchasedWallet.balance, unlocked + 1, #outfits)
	walletLabel.Text = string.format("Saldo comprado: %d", purchasedWallet.balance)
	for _, outfit in outfits do
		local unlockedCape = owned[outfit.id] or purchasedWallet.owned[outfit.id]
		local available = equipped ~= outfit.id and (unlockedCape or balance >= outfit.cost or purchasedWallet.balance >= outfit.cost)
		local button = outfit.button
		button.Interactable = available and not exchanging
		button.BackgroundTransparency = if available then 0 else 0.55
		button.Text = if equipped == outfit.id then "EM USO"
			elseif unlockedCape then "EQUIPAR"
			elseif balance >= outfit.cost then string.format("TROCAR %d", outfit.cost)
			elseif available then string.format("USAR %d", outfit.cost)
			else string.format("FALTAM %d", outfit.cost - math.max(balance, purchasedWallet.balance))
	end
end

local function refreshWallet()
	local encoded = localPlayer:GetAttribute("CarteiraLua")
	if encoded then
		purchasedWallet = HttpService:JSONDecode(encoded)
		updateShop()
	end
end
localPlayer:GetAttributeChangedSignal("CarteiraLua"):Connect(refreshWallet)
refreshWallet()

local function requestShop(action, ...)
	local remote = ReplicatedStorage:FindFirstChild("LojaLua")
	if not remote then
		return false
	end
	return pcall(remote.InvokeServer, remote, action, ...)
end

for _, outfit in outfits do
	outfit.button.Activated:Connect(function()
		if not shop.Visible or equipped == outfit.id or exchanging then
			return
		end
		if not (owned[outfit.id] or purchasedWallet.owned[outfit.id]) then
			if capeProgress() >= outfit.cost then
				owned[outfit.id] = true
			elseif purchasedWallet.balance >= outfit.cost then
				exchanging = true
				updateShop()
				local ok, unlocked = requestShop("capa", outfit.id)
				exchanging = false
				if not ok or not unlocked then
					updateShop()
					shopBalance.Text = "Não foi possível trocar. Tente novamente."
					return
				end
				refreshWallet()
			else
				return
			end
		end
		equipped = outfit.id
		updateShop()
	end)
end

local function clearInput()
	left, right, jumpQueued = false, false, false
	table.clear(leftTouches)
	table.clear(rightTouches)
end
UserInputService.WindowFocusReleased:Connect(clearInput)

local function menuOpen()
	return shop.Visible or packageMenu.Visible or leaderboard.Visible or helpMenu.Visible
end

local function canPlay()
	return not won and lives > 0 and not menuOpen()
end

local function toggleMenu(menu)
	local open = not menu.Visible
	shop.Visible = open and menu == shop
	packageMenu.Visible = open and menu == packageMenu
	leaderboard.Visible = open and menu == leaderboard
	helpMenu.Visible = open and menu == helpMenu
	panel.Visible = (won or lives == 0) and not open
	clearInput()
	accumulator = 0
end
local function toggleHelp()
	toggleMenu(helpMenu)
end
helpToggle.Activated:Connect(toggleHelp)
closeHelp.Activated:Connect(toggleHelp)
local function toggleShop()
	toggleMenu(shop)
end
shopToggle.Activated:Connect(toggleShop)
closeShop.Activated:Connect(toggleShop)

local packageRevision = 0
local availableProducts = {}
for i, button in packageButtons do
	button.Activated:Connect(function()
		local productId = availableProducts[i]
		if packageMenu.Visible and productId then
			local ok = pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, localPlayer, productId)
			if not ok then
				packageStatus.Text = "Compra indisponível. Tente novamente."
			end
		end
	end)
end
openPackages.Activated:Connect(function()
	toggleMenu(packageMenu)
	packageRevision += 1
	local revision = packageRevision
	table.clear(availableProducts)
	for _, button in packageButtons do
		button.Text = "INDISPONÍVEL"
		button.Interactable = false
	end
	packageStatus.Text = "Verificando pacotes..."
	local ok, packages, enabled = requestShop("pacotes")
	if revision ~= packageRevision or not packageMenu.Visible then
		return
	end
	if not ok or not enabled then
		packageStatus.Text = "Compras em Robux ainda não ativadas."
		return
	end
	packageStatus.Text = ""
	for i, package in packages do
		if package.productId > 0 then
			local loaded, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, package.productId, Enum.InfoType.Product)
			if revision ~= packageRevision or not packageMenu.Visible then
				return
			end
			if loaded and info.IsForSale and info.PriceInRobux then
				local button = packageButtons[i]
				button.Text = string.format("%d Robux", info.PriceInRobux)
				availableProducts[i] = package.productId
				button.Interactable = true
			end
		end
	end
end)
backToCapes.Activated:Connect(toggleShop)

local function updateCounter()
	counter.Text = string.format("RELÍQUIAS  %d/%d", collected, #relics)
	for i, showLife in lifeIcons do
		showLife(i <= lives)
	end
end

local function formatTime(seconds)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function formatRecord(milliseconds)
	return string.format("%s.%03d", formatTime(math.floor(milliseconds / 1000)), milliseconds % 1000)
end

local function showBest(record)
	bestLabel.Text = if record then string.format("Recorde: %s  %s", formatRecord(record.milliseconds), record.name)
		else "Nenhum recorde salvo"
end

local function requestRecord(action, milliseconds, name)
	local remote = ReplicatedStorage:FindFirstChild("RecordeDaFase")
	if not remote then
		return false
	end
	local called, ok, record, ranked = pcall(function()
		return remote:InvokeServer(action, milliseconds, name)
	end)
	return called and ok, record, ranked
end

local function showRankingRows(rows, records)
	for i, row in rows do
		local record = records and records[i]
		row.name.Text = if record then string.format("%02d  %s", i, record.name) else ""
		row.time.Text = if record then formatRecord(record.milliseconds) else ""
	end
end

local rankingRevision = 0
local function toggleRanking()
	toggleMenu(leaderboard)
	rankingRevision += 1
	if not leaderboard.Visible then
		return
	end
	local revision = rankingRevision
	rankingStatus.Text = "Carregando..."
	showRankingRows(rankingRows)
	task.spawn(function()
		local ok, records = requestRecord("listar")
		if revision ~= rankingRevision or not leaderboard.Visible then
			return
		end
		rankingStatus.Text = if not ok then "Recordes indisponíveis."
			elseif #records == 0 then "Nenhum recorde salvo."
			elseif RunService:IsStudio() then "Recordes desta sessão" else ""
		showRankingRows(rankingRows, if ok then records else nil)
	end)
end
rankingToggle.Activated:Connect(toggleRanking)
closeRanking.Activated:Connect(toggleRanking)

local function saveBest()
	if not won or not panel.Visible or savingRecord then
		return
	end
	local name = string.match(nameInput.Text, "^%s*(.-)%s*$")
	local length = utf8.len(name)
	if not length or length == 0 or length > 24 or string.find(name, "%c") then
		recordStatus.Text = "Digite um nome de 1 a 24 caracteres."
		return
	end
	recordRevision += 1
	local revision = recordRevision
	savingRecord = true
	saveRecord.Interactable = false
	recordStatus.Text = "Salvando..."
	local ok, record, ranked = requestRecord("salvar", completedTime, name)
	if revision ~= recordRevision then
		return
	end
	savingRecord = false
	saveRecord.Interactable = true
	if not ok or not record then
		recordStatus.Text = "Falha ao salvar. Tente de novo."
		return
	end
	showBest(record)
	recordStatus.Text = if not ranked then "Salvo. Tente novamente para atualizar o ranking."
		elseif record.milliseconds < completedTime then "Seu melhor tempo foi mantido."
		elseif RunService:IsStudio() then "Recorde salvo neste teste." else "Recorde salvo."
end
saveRecord.Activated:Connect(saveBest)
nameInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		saveBest()
	end
end)

local function respawn()
	player = Movimento.new(if checkpoint > 0 then checkpoints[checkpoint].point else Fase.start)
	cameraX = math.clamp(player.x - VIEW_WIDTH * 0.38, 0, Fase.width - VIEW_WIDTH)
	clearInput()
	runTime = 0
	accumulator = 0
	nextMist = elapsed
	for _, puff in mist do
		puff.art.Visible = false
	end
end

local function restart()
	won = false
	victoryBlink = 0
	title.TextTransparency = 0
	lives = Fase.startingLives
	checkpoint = 0
	elapsed = 0
	runTime = 0
	attemptTime = 0
	completedTime = nil
	recordRevision += 1
	savingRecord = false
	saveRecord.Interactable = true
	collected = 0
	facing = 1
	left, right = false, false
	panel.Visible = false
	for _, marker in checkpoints do
		marker.setLight(false)
	end
	hint.Text = controlsHint
	for _, relic in relics do
		relic.art.Visible = true
	end
	respawn()
	updateCounter()
end

replay.Activated:Connect(function()
	if panel.Visible and (won or lives == 0) then
		restart()
	end
end)

local function loseLife(reason)
	lives -= 1
	updateCounter()
	if lives > 0 then
		respawn()
		return
	end
	clearInput()
	accumulator = 0
	title.Text = "GAME OVER"
	title.TextTransparency = 0
	result.Text = reason
	recordForm.Visible = false
	panel.Size = UDim2.fromOffset(280, 90)
	panelBorder.Position = UDim2.fromOffset(0, 89)
	replay.Position = UDim2.fromOffset(77, 61)
	panel.Visible = true
end

local function acceptTouch(input)
	return input.UserInputType == Enum.UserInputType.Touch and canPlay() and not UserInputService:GetFocusedTextBox()
end
moveLeftButton.InputBegan:Connect(function(input)
	if acceptTouch(input) then
		leftTouches[input] = true
	end
end)
moveRightButton.InputBegan:Connect(function(input)
	if acceptTouch(input) then
		rightTouches[input] = true
	end
end)
jumpButton.InputBegan:Connect(function(input)
	if acceptTouch(input) then
		jumpQueued = true
	end
end)
UserInputService.TouchEnded:Connect(function(input)
	leftTouches[input] = nil
	rightTouches[input] = nil
end)
UserInputService.TextBoxFocused:Connect(clearInput)

ContextActionService:BindActionAtPriority("LuarControls", function(_, state, input)
	if state == Enum.UserInputState.Cancel then
		clearInput()
		return Enum.ContextActionResult.Sink
	end
	if UserInputService:GetFocusedTextBox() then
		clearInput()
		return Enum.ContextActionResult.Pass
	end
	local down = state == Enum.UserInputState.Begin
	if input.KeyCode == Enum.KeyCode.C then
		if down then
			toggleShop()
		end
		return Enum.ContextActionResult.Sink
	end
	if input.KeyCode == Enum.KeyCode.T then
		if down then
			toggleRanking()
		end
		return Enum.ContextActionResult.Sink
	end
	if input.KeyCode == Enum.KeyCode.H then
		if down then
			toggleHelp()
		end
		return Enum.ContextActionResult.Sink
	end
	if menuOpen() then
		return Enum.ContextActionResult.Sink
	end
	if won or lives == 0 then
		if input.KeyCode == Enum.KeyCode.R and down then
			restart()
		end
		return Enum.ContextActionResult.Sink
	end
	if input.KeyCode == Enum.KeyCode.A then
		left = down
	elseif input.KeyCode == Enum.KeyCode.D then
		right = down
	elseif input.KeyCode == Enum.KeyCode.Space and down then
		jumpQueued = true
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.R, Enum.KeyCode.C, Enum.KeyCode.T, Enum.KeyCode.H)

local function fragmentY(fragment)
	return fragment.y + math.sin(elapsed * 3 + fragment.x) * 1.5
end

local function simulate(direction)
	elapsed += Movimento.step
	local jumped = Movimento.update(player, Fase, direction, jumpQueued)
	jumpQueued = false
	if jumped then
		jumpSound:Play()
	end
	for _, walker in walkers do
		local path = walker.path
		local length = path.right - path.left
		local distance = (elapsed * path.speed) % (2 * length)
		walker.x = path.left + math.min(distance, 2 * length - distance)
		walker.facing = if distance < length then 1 else 2
	end
	if player.y > VIEW_HEIGHT + 10 then
		loseLife("Nino caiu no abismo.")
		return
	end
	for _, walker in walkers do
		local height = walker.kind.hitHeight
		if Movimento.touches(player, walker.x - 5, walker.path.y - height, 10, height) then
			hitSound:Play()
			loseLife(walker.kind.defeat)
			return
		end
	end
	for i, bat in bats do
		local phase = elapsed * bat.path.speed + i
		bat.x = bat.path.x + math.sin(phase) * bat.path.range
		bat.y = bat.path.y + math.sin(phase * 1.65) * 4
		if Movimento.touches(player, bat.x - 5, bat.y - 2, 10, 5) then
			hitSound:Play()
			loseLife("Um morcego acertou Nino.")
			return
		end
	end
	for _, relic in relics do
		local y = relic.y + math.sin(elapsed * 3 + relic.x) * 2
		if relic.art.Visible and Movimento.touches(player, relic.x - 4, y - 4, 8, 8) then
			relic.art.Visible = false
			collected += 1
			updateCounter()
		end
	end
	for _, fragment in fragments do
		if fragment.art.Visible and Movimento.touches(player, fragment.x - 4, fragmentY(fragment) - 4, 8, 8) then
			fragment.art.Visible = false
			foundFragments += 1
			updateShop()
		end
	end
	for i = checkpoint + 1, #checkpoints do
		local marker = checkpoints[i]
		local point = marker.point
		if Movimento.touches(player, point.x - 8, point.y - 27, 16, 27) then
			checkpoint = i
			marker.setLight(true)
			hint.Text = "MARCO ATIVO"
			break
		end
	end
	local door = Fase.exit
	if Movimento.touches(player, door.x - 6, door.y - 25, 12, 25) then
		won = true
		completedTime = math.max(1, math.round(attemptTime * 1000))
		title.Text = "CONGRATULATION"
		title.TextTransparency = 0
		result.Text = string.format("Tempo %s  |  Relíquias %d/%d", formatRecord(completedTime), collected, #relics)
		recordForm.Visible = true
		panel.Size = UDim2.fromOffset(280, 130)
		panelBorder.Position = UDim2.fromOffset(0, 129)
		replay.Position = UDim2.fromOffset(77, 104)
		bestLabel.Text = "Carregando recorde..."
		recordStatus.Text = ""
		panel.Visible = true
		local revision = recordRevision
		task.spawn(function()
			local ok, record = requestRecord("consultar")
			if revision == recordRevision then
				if ok then
					showBest(record)
				else
					bestLabel.Text = "Recorde indisponível"
				end
			end
		end)
	end
end

local function renderMist(moving)
	if equipped == "nevoa" and moving and elapsed >= nextMist then
		local puff = mist[mistSlot]
		puff.x = player.x + (if facing == 1 then 0 else Movimento.width)
		puff.y = player.y + 13
		puff.drift = if facing == 1 then -14 else 14
		puff.age = elapsed
		puff.art.Visible = true
		mistSlot = mistSlot % #mist + 1
		nextMist = elapsed + 0.065
	end
	for _, puff in mist do
		if puff.art.Visible then
			local age = elapsed - puff.age
			puff.art.Visible = age < 0.42 and equipped == "nevoa"
			puff.art.Position = UDim2.fromOffset(math.round(puff.x + puff.drift * age), math.round(puff.y - 12 * age))
			puff.art.BackgroundTransparency = math.min(1, 0.38 + age * 1.5)
		end
	end
end

local function render(dt)
	local direction = (if right or next(rightTouches) then 1 else 0) - (if left or next(leftTouches) then 1 else 0)
	local playing = canPlay()
	if playing then
		attemptTime += math.min(dt, Fase.timeLimit - runTime)
		runTime = math.min(Fase.timeLimit, runTime + dt)
		if direction ~= 0 then
			facing = if direction > 0 then 1 else 2
		end
		if runTime >= Fase.timeLimit then
			loseLife("O tempo acabou.")
		else
			accumulator = math.min(accumulator + dt, 0.1)
			while accumulator >= Movimento.step and not won do
				accumulator -= Movimento.step
				simulate(direction)
			end
		end
	end
	touchBar.Visible = touchEnabled and canPlay()
	if won and panel.Visible then
		victoryBlink = (victoryBlink + dt) % 1.2
		title.TextTransparency = if victoryBlink < 0.8 then 0 else 1
	end
	local seconds = math.ceil(Fase.timeLimit - runTime)
	if shownSeconds ~= seconds then
		timer.Text = "TEMPO  " .. formatTime(seconds)
		timer.TextColor3 = if seconds <= 15 then Color3.fromRGB(245, 150, 150) else Color3.fromRGB(231, 231, 231)
		shownSeconds = seconds
	end

	local target = math.clamp(player.x - VIEW_WIDTH * 0.38, 0, Fase.width - VIEW_WIDTH)
	cameraX += (target - cameraX) * (1 - math.exp(-11 * dt))
	world.Position = UDim2.fromOffset(-math.round(cameraX), 0)
	sky.Position = UDim2.fromOffset(-math.round(cameraX * 0.31), 0)
	hills.Position = UDim2.fromOffset(-math.round(cameraX * 0.57), 0)
	nino.Position = UDim2.fromOffset(
		math.round(player.x + (Movimento.width - Arte.ninoWidth) / 2),
		math.round(player.y + Movimento.height - Arte.ninoHeight)
	)

	local pose = 1
	if not player.grounded then
		pose = 4
	elseif direction ~= 0 and not won and lives > 0 then
		pose = 2 + math.floor(elapsed * 10) % 2
	end
	local sprite = poses[equipped][facing][pose]
	if shownPose ~= sprite then
		if shownPose then
			shownPose.Visible = false
		end
		sprite.Visible = true
		shownPose = sprite
	end
	for _, relic in relics do
		relic.art.Position = UDim2.fromOffset(relic.x - 4, math.round(relic.y - 4 + math.sin(elapsed * 3 + relic.x) * 2))
	end
	for _, fragment in fragments do
		fragment.art.Position = UDim2.fromOffset(fragment.x - 3, math.round(fragmentY(fragment)) - 3)
	end
	renderMist(playing and not won and lives > 0 and (direction ~= 0 or not player.grounded))
	for _, bat in bats do
		bat.art.Position = UDim2.fromOffset(math.round(bat.x or bat.path.x) - 7, math.round(bat.y or bat.path.y) - 3)
		local raised = math.floor(elapsed * 9) % 2 == 0
		bat.wings[1].Visible = raised
		bat.wings[2].Visible = not raised
	end
	for _, walker in walkers do
		local step = 1 + math.floor(elapsed * walker.kind.cadence) % 2
		walker.art.Position = UDim2.fromOffset(
			math.round(walker.x - walker.kind.width / 2),
			walker.path.y - walker.kind.height
		)
		local pose = walker.poses[walker.facing][step]
		if walker.shownPose ~= pose then
			if walker.shownPose then
				walker.shownPose.Visible = false
			end
			pose.Visible = true
			walker.shownPose = pose
		end
	end
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
updateCounter()
updateShop()
render(0)
RunService.PreRender:Connect(render)
music:Play()
