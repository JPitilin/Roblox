local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
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
local setCheckpointLight = Arte.lantern(world, Fase.checkpoint)
setCheckpointLight(false)
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

local mummies = {}
for _, path in Fase.mummies do
	local art = Arte.layer(world, "Múmia", Arte.mummyWidth, Arte.mummyHeight, 10)
	table.insert(mummies, { path = path, art = art, poses = Arte.mummy(art), x = path.left, facing = 1 })
end

local header = Arte.rect(viewport, 0, 0, VIEW_WIDTH, 33, 10, 11)
header.BackgroundTransparency = 0.12
Arte.rect(viewport, 0, 33, VIEW_WIDTH, 1, 66, 11)
Arte.text(header, "LUAR DE CINZAS", 12, 3, 190, 14, 12, 240)
Arte.text(header, "Nino  /  Cemitério", 12, 17, 175, 12, 9, 170)
local timer = Arte.text(header, "", 140, 3, 86, 14, 10, 231)
timer.TextXAlignment = Enum.TextXAlignment.Center
local lifeCounter = Arte.text(header, "", 227, 3, 62, 14, 10, 231)
local counter = Arte.text(header, "", 288, 3, 84, 14, 10, 231)
counter.TextXAlignment = Enum.TextXAlignment.Right
local hint = Arte.text(header, "A/D  mover   ESPAÇO  saltar", 227, 17, 145, 12, 9, 183)
hint.TextXAlignment = Enum.TextXAlignment.Right
local shopToggle = Arte.text(header, "", 117, 17, 110, 12, 9, Color3.fromRGB(194, 222, 245), true)
shopToggle.TextXAlignment = Enum.TextXAlignment.Center

local panel = Arte.rect(viewport, 64, 65, 256, 90, 15, 11)
Arte.rect(panel, 0, 0, 256, 1, 153, 11)
Arte.rect(panel, 0, 89, 256, 1, 153, 11)
local title = Arte.text(panel, "Cripta alcançada", 12, 12, 232, 24, 18, 244)
title.TextXAlignment = Enum.TextXAlignment.Center
local result = Arte.text(panel, "", 12, 39, 232, 16, 11, 209)
result.TextXAlignment = Enum.TextXAlignment.Center
local replay = Arte.text(panel, "R  jogar novamente", 12, 63, 232, 13, 10, 177)
replay.TextXAlignment = Enum.TextXAlignment.Center
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

local player = Movimento.new(Fase.start)
local cameraX = 0
local elapsed = 0
local runTime = 0
local shownSeconds
local lives = Fase.startingLives
local accumulator = 0
local collected = 0
local foundFragments = 0
local owned = { original = true }
local equipped = "original"
local mistSlot = 1
local nextMist = 0
local checkpoint = false
local won = false
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
	shopToggle.Text = string.format("C CAPAS  |  LUA %d/%d", foundFragments, #fragments)
	shopBalance.Text = string.format("Saldo: %d fragmentos  |  Capas extras: %d/%d", balance, unlocked, #outfits - 1)
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

local function toggleShop()
	shop.Visible = not shop.Visible
	panel.Visible = (won or lives == 0) and not shop.Visible
	left, right, jumpQueued = false, false, false
	accumulator = 0
end
shopToggle.Activated:Connect(toggleShop)
closeShop.Activated:Connect(toggleShop)

local function updateCounter()
	counter.Text = string.format("RELÍQUIAS  %d/%d", collected, #relics)
	lifeCounter.Text = string.format("VIDAS  %d/%d", lives, Fase.startingLives)
end

local function formatTime(seconds)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function respawn()
	player = Movimento.new(if checkpoint then Fase.checkpoint else Fase.start)
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
	lives = Fase.startingLives
	checkpoint = false
	elapsed = 0
	runTime = 0
	collected = 0
	facing = 1
	left, right = false, false
	panel.Visible = false
	setCheckpointLight(false)
	hint.Text = "A/D  mover   ESPAÇO  saltar"
	for _, relic in relics do
		relic.art.Visible = true
	end
	respawn()
	updateCounter()
end

local function loseLife(reason)
	lives -= 1
	updateCounter()
	if lives > 0 then
		respawn()
		return
	end
	left, right, jumpQueued = false, false, false
	accumulator = 0
	title.Text = "Fim de jogo"
	result.Text = reason
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
	if shop.Visible then
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
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.R, Enum.KeyCode.C)

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
	for _, mummy in mummies do
		local path = mummy.path
		local length = path.right - path.left
		local distance = (elapsed * path.speed) % (2 * length)
		mummy.x = path.left + math.min(distance, 2 * length - distance)
		mummy.facing = if distance < length then 1 else 2
	end
	if player.y > VIEW_HEIGHT + 10 then
		loseLife("Nino caiu no abismo.")
		return
	end
	for _, mummy in mummies do
		if Movimento.touches(player, mummy.x - 5, mummy.path.y - 21, 10, 21) then
			hitSound:Play()
			loseLife("Uma múmia acertou Nino.")
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
	local mark = Fase.checkpoint
	if not checkpoint and Movimento.touches(player, mark.x - 8, mark.y - 27, 16, 27) then
		checkpoint = true
		setCheckpointLight(true)
		hint.Text = "MARCO ATIVO"
	end
	local door = Fase.exit
	if Movimento.touches(player, door.x - 6, door.y - 25, 12, 25) then
		won = true
		title.Text = "Cripta alcançada"
		result.Text = string.format("Tempo %s  |  Relíquias %d/%d", formatTime(math.floor(runTime)), collected, #relics)
		panel.Visible = true
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
	if not won and lives > 0 and not shop.Visible then
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
	renderMist(not won and lives > 0 and not shop.Visible and (direction ~= 0 or not player.grounded))
	for _, bat in bats do
		bat.art.Position = UDim2.fromOffset(math.round(bat.x or bat.path.x) - 7, math.round(bat.y or bat.path.y) - 3)
		local raised = math.floor(elapsed * 9) % 2 == 0
		bat.wings[1].Visible = raised
		bat.wings[2].Visible = not raised
	end
	local step = 1 + math.floor(elapsed * 3) % 2
	for _, mummy in mummies do
		mummy.art.Position = UDim2.fromOffset(
			math.round(mummy.x - Arte.mummyWidth / 2),
			mummy.path.y - Arte.mummyHeight
		)
		local pose = mummy.poses[mummy.facing][step]
		if mummy.shownPose ~= pose then
			if mummy.shownPose then
				mummy.shownPose.Visible = false
			end
			pose.Visible = true
			mummy.shownPose = pose
		end
	end
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
updateCounter()
updateShop()
render(0)
RunService.PreRender:Connect(render)
music:Play()
