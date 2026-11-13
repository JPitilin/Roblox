local Movimento = {}

Movimento.width = 10
Movimento.height = 19
Movimento.step = 1 / 120

local SPEED = 115
local JUMP = 218
local GRAVITY = 604

local function overlaps(a, sizeA, b, sizeB)
	return a < b + sizeB and a + sizeA > b
end

function Movimento.new(point)
	return {
		x = point.x - Movimento.width / 2,
		y = point.y - Movimento.height,
		vy = 0,
		coyote = 0,
		buffer = 0,
		grounded = true,
	}
end

function Movimento.touches(player, x, y, w, h)
	return overlaps(player.x, Movimento.width, x, w)
		and overlaps(player.y, Movimento.height, y, h)
end

function Movimento.update(player, level, direction, jump)
	local dt = Movimento.step
	local width, height = Movimento.width, Movimento.height
	player.buffer = if jump then 0.12 else math.max(0, player.buffer - dt)
	player.coyote = if player.grounded then 0.085 else math.max(0, player.coyote - dt)
	local jumped = player.buffer > 0 and player.coyote > 0
	if jumped then
		player.vy = -JUMP
		player.buffer = 0
		player.coyote = 0
	end

	local nextX = math.clamp(player.x + direction * SPEED * dt, 0, level.width - width)
	for _, block in level.platforms do
		if overlaps(player.y, height, block.y, block.h) and overlaps(nextX, width, block.x, block.w) then
			if player.x + width <= block.x then
				nextX = block.x - width
			elseif player.x >= block.x + block.w then
				nextX = block.x + block.w
			end
		end
	end
	player.x = nextX

	player.vy = math.min(340, player.vy + GRAVITY * dt)
	local nextY = player.y + player.vy * dt
	player.grounded = false
	for _, block in level.platforms do
		if overlaps(player.x, width, block.x, block.w) then
			if player.y + height <= block.y and nextY + height >= block.y then
				nextY = block.y - height
				player.grounded = true
			elseif player.y >= block.y + block.h and nextY <= block.y + block.h then
				nextY = block.y + block.h
			end
		end
	end
	if nextY ~= player.y + player.vy * dt or player.grounded then
		player.vy = 0
	end
	player.y = nextY
	return jumped
end

return Movimento
