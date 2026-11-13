local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Arte = require(script.Arte)
local Fase = require(script.Fase)
local Movimento = require(script.Movimento)

local VIEW_WIDTH = 384
local VIEW_HEIGHT = Fase.height
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
local poses = Arte.nino(nino)

local relics = {}
for _, point in Fase.relics do
	local art = Arte.layer(world, "Relíquia", 9, 9, 10)
	Arte.relic(art)
	table.insert(relics, { x = point.x, y = point.y, art = art })
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
local timer = Arte.text(header, "TEMPO  00:00", 144, 3, 96, 14, 10, 231)
timer.TextXAlignment = Enum.TextXAlignment.Center
local counter = Arte.text(header, "", 200, 3, 172, 14, 11, 231)
counter.TextXAlignment = Enum.TextXAlignment.Right
local hint = Arte.text(header, "A/D  mover   ESPAÇO  saltar", 185, 17, 187, 12, 9, 183)
hint.TextXAlignment = Enum.TextXAlignment.Right

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

local player = Movimento.new(Fase.start)
local cameraX = 0
local elapsed = 0
local runTime = 0
local shownSeconds = 0
local accumulator = 0
local collected = 0
local checkpoint = false
local won = false
local left = false
local right = false
local jumpQueued = false
local facing = 1
local shownPose

local function updateCounter()
	counter.Text = string.format("RELÍQUIAS  %d/%d", collected, #relics)
end

local function formatTime(seconds)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function respawn()
	player = Movimento.new(if checkpoint then Fase.checkpoint else Fase.start)
	cameraX = math.clamp(player.x - VIEW_WIDTH * 0.38, 0, Fase.width - VIEW_WIDTH)
	jumpQueued = false
end

local function restart()
	won = false
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
	if input.KeyCode == Enum.KeyCode.A then
		left = down
	elseif input.KeyCode == Enum.KeyCode.D then
		right = down
	elseif input.KeyCode == Enum.KeyCode.Space and down and not won then
		jumpQueued = true
	elseif input.KeyCode == Enum.KeyCode.R and down and won then
		restart()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.R)

local function simulate(direction)
	elapsed += Movimento.step
	Movimento.update(player, Fase, direction, jumpQueued)
	jumpQueued = false
	for _, mummy in mummies do
		local path = mummy.path
		local length = path.right - path.left
		local distance = (elapsed * path.speed) % (2 * length)
		mummy.x = path.left + math.min(distance, 2 * length - distance)
		mummy.facing = if distance < length then 1 else 2
	end
	if player.y > VIEW_HEIGHT + 10 then
		respawn()
		return
	end
	for _, mummy in mummies do
		if Movimento.touches(player, mummy.x - 5, mummy.path.y - 21, 10, 21) then
			respawn()
			return
		end
	end
	for i, bat in bats do
		local phase = elapsed * bat.path.speed + i
		bat.x = bat.path.x + math.sin(phase) * bat.path.range
		bat.y = bat.path.y + math.sin(phase * 1.65) * 4
		if Movimento.touches(player, bat.x - 5, bat.y - 2, 10, 5) then
			respawn()
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
	local mark = Fase.checkpoint
	if not checkpoint and Movimento.touches(player, mark.x - 8, mark.y - 27, 16, 27) then
		checkpoint = true
		setCheckpointLight(true)
		hint.Text = "MARCO ATIVO"
	end
	local door = Fase.exit
	if Movimento.touches(player, door.x - 6, door.y - 25, 12, 25) then
		won = true
		result.Text = string.format("Tempo %s  |  Relíquias %d/%d", formatTime(math.floor(runTime)), collected, #relics)
		panel.Visible = true
	end
end

local function render(dt)
	local direction = (if right then 1 else 0) - (if left then 1 else 0)
	if not won then
		runTime += dt
		if direction ~= 0 then
			facing = if direction > 0 then 1 else 2
		end
		accumulator = math.min(accumulator + dt, 0.1)
		while accumulator >= Movimento.step and not won do
			simulate(direction)
			accumulator -= Movimento.step
		end
	end
	local seconds = math.floor(runTime)
	if shownSeconds ~= seconds then
		timer.Text = "TEMPO  " .. formatTime(seconds)
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
	elseif direction ~= 0 and not won then
		pose = 2 + math.floor(elapsed * 10) % 2
	end
	local sprite = poses[facing][pose]
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
render(0)
RunService.PreRender:Connect(render)
