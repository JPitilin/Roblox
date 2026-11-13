local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
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
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local screen = Instance.new("ScreenGui")
screen.Name = "Luar de Cinzas"
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.None
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

local function resize()
	local size = backdrop.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		zoom.Scale = math.min(size.X / VIEW_WIDTH, size.Y / VIEW_HEIGHT)
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
local hint = Arte.text(header, "A/D mover  ESPAÇO pular", 251, 17, 121, 12, 9, 183)
hint.TextXAlignment = Enum.TextXAlignment.Right
local shopToggle = Arte.text(header, "", 12, 17, 91, 12, 9, Color3.fromRGB(194, 222, 245), true)
local fragmentCounter = Arte.text(header, "", 106, 17, 63, 12, 9, 183)
local rankingToggle = Arte.text(header, "T RECORDES", 180, 17, 68, 12, 9, Color3.fromRGB(194, 222, 245), true)

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
local replay = Arte.text(panel, "Recomeçar  [R]", 77, 104, 126, 19, 11, 245, true)
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

local leaderboard = Arte.rect(viewport, 48, 42, 288, 161, 19, 11)
Arte.rect(leaderboard, 0, 0, 288, 1, 134, 11)
Arte.rect(leaderboard, 0, 160, 288, 1, 134, 11)
Arte.text(leaderboard, "MELHORES TEMPOS", 12, 5, 170, 18, 13, 240)
local closeRanking = Arte.text(leaderboard, "T FECHAR", 209, 5, 67, 18, 10, 210, true)
closeRanking.TextXAlignment = Enum.TextXAlignment.Right
local rankingStatus = Arte.text(leaderboard, "", 12, 25, 264, 12, 9, 193)
local rankingRows = {}
for i = 1, 10 do
	local y = 39 + (i - 1) * 11
	local name = Arte.text(leaderboard, "", 12, y, 184, 11, 9, 229)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	local time = Arte.text(leaderboard, "", 205, y, 71, 11, 9, 229)
	time.TextXAlignment = Enum.TextXAlignment.Right
	rankingRows[i] = { name = name, time = time }
end
leaderboard.Visible = false

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
local equipped = "original"
local mistSlot = 1
local nextMist = 0
local checkpoint = 0
local won = false
local victoryBlink = 0
local left = false
local right = false
local jumpQueued = false
local facing = 1
local shownPose

local function capeProgress()
	local balance = foundFragments
	local unlocked = 0
	for _, outfit in outfits do
		if owned[outfit.id] then
			balance -= outfit.cost
			if outfit.cost > 0 then
				unlocked += 1
			end
		end
	end
	return balance, unlocked
end

local function updateShop()
	local balance, unlocked = capeProgress()
	shopToggle.Text = string.format("C CAPAS %d/%d", unlocked + 1, #outfits)
	fragmentCounter.Text = string.format("LUA %d/%d", foundFragments, #fragments)
	shopBalance.Text = string.format("Saldo: %d fragmentos  |  Capas: %d/%d", balance, unlocked + 1, #outfits)
	for _, outfit in outfits do
		local available = equipped ~= outfit.id and (owned[outfit.id] or balance >= outfit.cost)
		local button = outfit.button
		button.Interactable = available
		button.BackgroundTransparency = if available then 0 else 0.55
		button.Text = if equipped == outfit.id then "EM USO"
			elseif owned[outfit.id] then "EQUIPAR"
			elseif available then string.format("TROCAR %d", outfit.cost)
			else string.format("FALTAM %d", outfit.cost - balance)
	end
end

for _, outfit in outfits do
	outfit.button.Activated:Connect(function()
		if not shop.Visible or equipped == outfit.id then
			return
		end
		if not owned[outfit.id] then
			if capeProgress() < outfit.cost then
				return
			end
			owned[outfit.id] = true
		end
		equipped = outfit.id
		updateShop()
	end)
end

local function toggleMenu(menu)
	local open = not menu.Visible
	shop.Visible = open and menu == shop
	leaderboard.Visible = open and menu == leaderboard
	panel.Visible = (won or lives == 0) and not open
	left, right, jumpQueued = false, false, false
	accumulator = 0
end
local function toggleShop()
	toggleMenu(shop)
end
shopToggle.Activated:Connect(toggleShop)
closeShop.Activated:Connect(toggleShop)

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

local rankingRevision = 0
local function toggleRanking()
	toggleMenu(leaderboard)
	rankingRevision += 1
	if not leaderboard.Visible then
		return
	end
	local revision = rankingRevision
	rankingStatus.Text = "Carregando..."
	for _, row in rankingRows do
		row.name.Text = ""
		row.time.Text = ""
	end
	task.spawn(function()
		local ok, records = requestRecord("listar")
		if revision ~= rankingRevision or not leaderboard.Visible then
			return
		end
		rankingStatus.Text = if not ok then "Recordes indisponíveis. Reabra para tentar."
			elseif #records == 0 then "Nenhum recorde salvo."
			elseif RunService:IsStudio() then "Recordes desta sessão" else "10 melhores da fase"
		for i, record in records or {} do
			rankingRows[i].name.Text = string.format("%02d  %s", i, record.name)
			rankingRows[i].time.Text = formatRecord(record.milliseconds)
		end
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
	left, right, jumpQueued = false, false, false
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
	hint.Text = "A/D mover  ESPAÇO pular"
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
	left, right, jumpQueued = false, false, false
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

local function clearInput()
	left, right, jumpQueued = false, false, false
end
UserInputService.WindowFocusReleased:Connect(clearInput)

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
	if shop.Visible or leaderboard.Visible then
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
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.R, Enum.KeyCode.C, Enum.KeyCode.T)

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
	local direction = (if right then 1 else 0) - (if left then 1 else 0)
	if not won and lives > 0 and not shop.Visible and not leaderboard.Visible then
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
	renderMist(not won and lives > 0 and not shop.Visible and not leaderboard.Visible and (direction ~= 0 or not player.grounded))
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
