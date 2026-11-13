local Arte = {}

local function color(value)
	if typeof(value) == "Color3" then
		return value
	end
	return Color3.fromRGB(value, value, value)
end

function Arte.rect(parent, x, y, w, h, value, z)
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color(value)
	frame.Position = UDim2.fromOffset(x, y)
	frame.Size = UDim2.fromOffset(w, h)
	frame.ZIndex = z
	frame.Parent = parent
	return frame
end

function Arte.layer(parent, name, w, h, z)
	local frame = Arte.rect(parent, 0, 0, w, h, 0, z)
	frame.Name = name
	frame.BackgroundTransparency = 1
	return frame
end

function Arte.text(parent, text, x, y, w, h, size, value, button)
	local label = Instance.new(if button then "TextButton" else "TextLabel")
	label.BorderSizePixel = 0
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(x, y)
	label.Size = UDim2.fromOffset(w, h)
	label.Font = Enum.Font.Code
	label.TextSize = size
	label.TextColor3 = color(value)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.ZIndex = 12
	label.Parent = parent
	return label
end

local function disk(parent, cx, cy, radius, step, value, z)
	for y = -radius, radius, step do
		local extent = math.floor(math.sqrt(radius * radius - y * y) / step) * step
		Arte.rect(parent, cx - extent, cy + y, extent * 2 + step, step, value, z)
	end
end

function Arte.background(root, level, viewWidth)
	local skyWidth = viewWidth + math.ceil((level.width - viewWidth) * 0.31)
	local hillsWidth = viewWidth + math.ceil((level.width - viewWidth) * 0.57)
	local sky = Arte.layer(root, "Céu", skyWidth, level.height, 1)
	local hills = Arte.layer(root, "Colinas", hillsWidth, level.height, 3)
	local random = Random.new(32)
	for y = 0, 210, 6 do
		Arte.rect(sky, 0, y, skyWidth, 6, 15 + math.floor(y / 7), 1)
	end
	for _ = 1, math.floor(skyWidth / 5) do
		local x, y = random:NextInteger(1, skyWidth - 1), random:NextInteger(9, 135)
		Arte.rect(sky, x, y, 1, 1, random:NextInteger(48, 121), 2)
	end
	disk(sky, 261, 68, 41, 2, 38, 2)
	disk(sky, 261, 68, 33, 2, 57, 2)
	disk(sky, 261, 68, 27, 2, 179, 2)
	disk(sky, 253, 64, 6, 2, 160, 2)
	disk(sky, 272, 77, 4, 2, 155, 2)
	for i = 0, math.ceil(skyWidth / 42) do
		local x = i * 42 - 20
		local y = random:NextInteger(88, 136)
		Arte.rect(sky, x, y, random:NextInteger(22, 54), 2, 70, 2)
		Arte.rect(sky, x + 12, y + 2, random:NextInteger(28, 53), 3, 59, 2)
	end
	for x = 0, hillsWidth - 1, 5 do
		local top = 142 + math.floor(11 * math.sin(x / 58) + 8 * math.cos(x / 21))
		Arte.rect(hills, x, top, 5, level.height - top, 35, 3)
		local near = 161 + math.floor(8 * math.sin(x / 33) + 5 * math.sin(x / 14))
		Arte.rect(hills, x, near, 5, level.height - near, 26, 4)
	end
	for _, x in { 190, 455, 686, 840, 1090, 1390 } do
		for i = 0, 3 do
			local tower = x + 13 * i
			local top = 125 - (i % 2) * 16
			Arte.rect(hills, tower, top, 9, 40, 27, 4)
			Arte.rect(hills, tower + 2, top - 3, 5, 3, 27, 4)
			Arte.rect(hills, tower + 4, top + 6, 1, 5, 67, 4)
		end
		Arte.rect(hills, x, 135, 48, 31, 27, 4)
	end
	return sky, hills
end

local function grave(parent, x, y, w, h)
	Arte.rect(parent, x - 1, y - h + 3, w + 2, h - 3, 20, 5)
	Arte.rect(parent, x, y - h + 2, w, h - 2, 55, 5)
	Arte.rect(parent, x + 2, y - h, w - 4, 2, 68, 5)
	Arte.rect(parent, x + 2, y - h + 5, 1, h - 7, 84, 5)
	Arte.rect(parent, x + w - 3, y - h + 5, 2, h - 5, 40, 5)
	Arte.rect(parent, x + 3, y - h + 8, w - 6, 1, 36, 5)
end

local function tree(parent, x, y)
	local segments = {
		{ -3, -40, 5, 40 }, { -2, -50, 3, 15 }, { -6, -55, 5, 8 },
		{ -10, -33, 9, 4 }, { -13, -38, 4, 8 }, { -16, -42, 4, 6 },
		{ 1, -25, 10, 4 }, { 8, -31, 4, 8 }, { 11, -35, 6, 4 },
		{ 15, -40, 3, 7 }, { -8, -4, 16, 4 },
	}
	for _, segment in segments do
		Arte.rect(parent, x + segment[1], y + segment[2], segment[3], segment[4], 18, 5)
	end
end

function Arte.terrain(world, level)
	local random = Random.new(76)
	for _, p in level.platforms do
		Arte.rect(world, p.x, p.y, p.w, p.h, 24, 6)
		Arte.rect(world, p.x, p.y, p.w, 2, 128, 7)
		Arte.rect(world, p.x, p.y + 2, p.w, 3, 76, 7)
		for y = p.y + 6, math.min(level.height, p.y + p.h - 2), 8 do
			local x = p.x + random:NextInteger(0, 6)
			while x < p.x + p.w - 3 do
				local width = math.min(random:NextInteger(7, 19), p.x + p.w - x)
				Arte.rect(world, x, y, width - 1, 4, random:NextInteger(36, 58), 7)
				Arte.rect(world, x, y, width - 1, 1, 67, 7)
				x += width
			end
		end
		if p.h > 20 then
			for x = p.x + 13, p.x + p.w - 13, 27 do
				if random:NextInteger(1, 5) == 1 then
					tree(world, x, p.y)
				else
					grave(world, x, p.y, random:NextInteger(7, 11), random:NextInteger(10, 19))
				end
				Arte.rect(world, x + 12, p.y - 4, 1, 4, 78, 5)
				Arte.rect(world, x + 13, p.y - 2, 2, 2, 58, 5)
			end
		end
	end
end

Arte.ninoWidth = 22
Arte.ninoHeight = 26

local ninoColors = {
	K = 12,
	H = 36,
	E = 60,
	I = 236,
	W = 213,
	O = 41,
	R = Color3.fromRGB(138, 34, 47),
	S = Color3.fromRGB(238, 206, 179),
	T = Color3.fromRGB(199, 147, 127),
	B = Color3.fromRGB(212, 129, 125),
	M = Color3.fromRGB(173, 83, 79),
}
local nino = {
	".........KK...........",
	".....KK.KHHKK.........",
	"......KKHHHHHKK.......",
	"....KKHHHHHHHHHKK.K...",
	"...KHHHHHHHHHHHHHKK...",
	"..KHHHHHHHHHHHHHHK....",
	"..KHHHHHHKKHHHHHHHK...",
	"..KHHHHKSSSKKHHHHHK...",
	"..KHHKSSSSSSSKKHHHK...",
	".RKHKSSEESSEESKHHKR...",
	".RKKSSSFISSSFISKKRR...",
	"RKTSSTSFISSSFISTKRRR..",
	"RKTSSSSSSSSSSSSTKRRRR.",
	"RRKSSSBSSSSSBSSKRRRRR.",
	"RRRKSSTTMMTTSSKRRRRRR.",
	"RRRRKKSSMMSSKKRRRRRRR.",
	"RRRKKKRRRRRKKKRRRRRRR.",
	"..RKHKRRWRRKHKRRRRK...",
	"..RKHHKWWWKHHKRRRK....",
	"..RKHKKWOWKKHKRRRK....",
	"..RKTKKWWWKKTKRRRK....",
	"..RKKKKWOWKKKKRRRK....",
	"..RKKKKKKKKKKKRRRK....",
}

function Arte.sprite(parent, rows, colors, flipped, z)
	for y, row in rows do
		local x = 1
		while x <= #row do
			local symbol = string.sub(row, x, x)
			local nextX = x + 1
			while string.sub(row, nextX, nextX) == symbol do
				nextX += 1
			end
			if colors[symbol] then
				Arte.rect(parent, if flipped then #row - nextX + 1 else x - 1, y - 1, nextX - x, 1, colors[symbol], z or 10)
			end
			x = nextX
		end
	end
end

function Arte.lifeIcon(parent, x)
	local icon = Arte.layer(parent, "Vida do Nino", 22, 16, 12)
	icon.Position = UDim2.fromOffset(x, 0)
	local full = Arte.layer(icon, "Preenchido", 22, 16, 12)
	local empty = Arte.layer(icon, "Vazado", 22, 16, 12)
	local face, outline = {}, {}
	for y = 1, 16 do
		face[y] = nino[y]
	end
	local function filled(x, y)
		local row = face[y]
		return row ~= nil and x >= 1 and x <= 22 and string.sub(row, x, x) ~= "."
	end
	for y, row in face do
		local pixels = {}
		for column = 1, #row do
			local edge = filled(column, y) and not (
				filled(column - 1, y) and filled(column + 1, y)
				and filled(column, y - 1) and filled(column, y + 1)
			)
			pixels[column] = if edge then "E" else "."
		end
		outline[y] = table.concat(pixels)
	end
	Arte.sprite(full, face, ninoColors, false, 12)
	Arte.sprite(empty, outline, { E = 148 }, false, 12)
	return function(active)
		full.Visible = active
		empty.Visible = not active
	end
end

local capes = {
	curta = {
		"......EEEEE...........",
		"....ECCCCCCEE.........",
		"...ECCCCCCCCCEE.......",
		"..ECCCCCCCCCCCCEE.....",
		".ECCCCCCCCCCCCCEEE....",
		"EEECCCCCCEEEEEEE......",
		"...EEEEEEE............",
	},
	nevoa = {
		"......EEEEE...........",
		"....EECCCCCEE.........",
		"...ECCCCCCCCCEE.......",
		"..ECCCCCCCCCCCCE......",
		"..ECCCCCCCCCCCCCE.....",
		".ECCCCCCCCCCCCCCCE....",
		".ECCCCCCCCCCCCCCCCE...",
		"ECCCCCCCCCCCCCCCCCCE..",
		"ECCCCCCCCCCCCCCCCCCCE.",
		"ECCECCCCCCCECCCECCEE..",
		"EEE.ECCCEEE.ECE.EE....",
		"E....EEE.....E........",
	},
}

function Arte.nino(parent, cape)
	local poses = {}
	for _, flipped in { false, true } do
		local facing = {}
		for pose, feet in {
			{ "..RKKKTTK.KTTKRRRK....", "..RKKKWWK.KWWKRRRK....", "..RKKKKKK.KKKKRRRK...." },
			{ "..RKKTTK...KTTKRRK....", "..RKKWWK...KWWKRRK....", "..RKKKKKK..KKKKKRK...." },
			{ "..RRKKKTTK.KTTKRRK....", "..RRRKKWWK.KWWKRRK....", "..RRRRKKKK.KKKKRRK...." },
			{ "...RRKKKTTKKTTKRRK....", "....RRKKWWKKWWKRRK....", ".....RRKKKK.KKKRRK...." },
		} do
			local sprite = Arte.layer(parent, "Pose " .. pose, Arte.ninoWidth, Arte.ninoHeight, 10)
			local rows = table.clone(nino)
			for _, row in feet do
				table.insert(rows, row)
			end
			local silhouette = capes[cape]
			if silhouette then
				local fabric = Arte.layer(sprite, "Capa", Arte.ninoWidth, #silhouette, 9)
				fabric.Position = UDim2.fromOffset(0, 13)
				Arte.sprite(fabric, silhouette, { C = if cape == "nevoa" then 85 else 49, E = if cape == "nevoa" then 155 else 117 }, flipped, 9)
				for index, row in rows do
					rows[index] = string.gsub(row, "R", ".")
				end
			end
			Arte.sprite(sprite, rows, ninoColors, flipped)
			sprite.Visible = false
			facing[pose] = sprite
		end
		table.insert(poses, facing)
	end
	return poses
end

function Arte.fragment(parent)
	Arte.sprite(parent, {
		"...LL..",
		"..LV...",
		".LV....",
		".LV....",
		".LVH...",
		"..LVVL.",
		"...LL..",
	}, { L = Color3.fromRGB(215, 236, 252), V = Color3.fromRGB(157, 194, 226), H = Color3.fromRGB(87, 132, 179) }, false)
end

function Arte.bat(parent)
	local wings = {
		{
			"O.............O", "OO...........OO", "OMOO.O...O.OOMO",
			".OMMOOO.OOOMMO.", "..OOOHOHOOHOO..", ".....OVOVO.....", "......OOO......",
		},
		{
			".....O...O.....", "....OOO.OOO....", ".OOOOMOHOHOOOO.",
			"OMMOOOVOVOOOMMO", "OMOO..OOO..OOMO", "OO...........OO", "O.............O",
		},
	}
	local frames = {}
	for i, rows in wings do
		frames[i] = Arte.layer(parent, "Asas", 15, 7, 10)
		Arte.sprite(frames[i], rows, { O = 10, H = 47, M = 95, V = 230 }, false)
	end
	return frames
end

function Arte.relic(parent)
	local gold = Color3.fromRGB(235, 177, 68)
	for y = -3, 11 do
		local width = 15 - 2 * math.max(0, math.abs(y - 4) - 2)
		local halo = Arte.rect(parent, (9 - width) / 2, y, width, 1, gold, 9)
		halo.BackgroundTransparency = 0.85 + math.abs(y - 4) * 0.014
	end
	Arte.sprite(parent, {
		"....O....", "...OVO...", "..OVVVO..", ".OVLVHVO.", "OVLVHVHVO",
		".OVHVHVO.", "..OVHVO..", "...OVO...", "....O....",
	}, {
		O = Color3.fromRGB(122, 82, 34),
		H = Color3.fromRGB(191, 133, 49),
		L = Color3.fromRGB(255, 243, 184),
		V = Color3.fromRGB(235, 187, 84),
	}, false)
end

Arte.mummyWidth = 22
Arte.mummyHeight = 25

local mummyColors = {
	S = Color3.fromRGB(128, 108, 83),
	D = Color3.fromRGB(186, 160, 121),
	L = Color3.fromRGB(225, 204, 163),
	E = Color3.fromRGB(41, 34, 30),
	O = Color3.fromRGB(197, 132, 61),
	I = Color3.fromRGB(238, 190, 109),
}
local mummy = {
	".......SSSSSS.........",
	".....SSLLLLLLSS.......",
	"....SLLLLLLDDLLS......",
	"...SLLLLLDDLLLLLS.....",
	"...SLLLDDLLLLLLLS.....",
	"..SLLDDLLEEEEEELLS....",
	"..SLDLEEEOEEOEEELS....",
	"..SLLLEEEIEEIEELLS....",
	"..SLLLLLLLLDDLLLDS....",
	"...SLLLLDDLLLLDDS.....",
	"....SLDDLLLLDDS.......",
	".....SSLLLLSS....S....",
	".......SSSS.....SLS...",
	"...SS...SDLSS.SSLDS...",
	"..SLDS.SLDLLSSLDS.S...",
	"...SLLSLDLLDLLS.......",
	"....SSLDLDLLDS........",
	"......SLDLLDLS........",
	"......SLDLDLLS........",
	"......SDLDLDLS........",
	".......SSDLSS.........",
}
local mummySteps = {
	{ "......SLDSLS..........", ".....SLDS.SLS.........", "....SLLS..SLDS........", "....SSS....SSS........" },
	{ "......SDLSLDS.........", "......SLDS.SLS........", "......SLDS..SLDS......", "......SSS....SSS......" },
}

Arte.frankensteinWidth = 22
Arte.frankensteinHeight = 28

local frankensteinColors = {
	K = Color3.fromRGB(25, 25, 30),
	H = Color3.fromRGB(45, 45, 66),
	G = Color3.fromRGB(156, 190, 64),
	S = Color3.fromRGB(72, 99, 35),
	B = Color3.fromRGB(167, 170, 160),
	E = 232,
	W = Color3.fromRGB(126, 100, 176),
	O = Color3.fromRGB(214, 141, 49),
	P = Color3.fromRGB(99, 56, 128),
	V = Color3.fromRGB(61, 39, 82),
	Y = Color3.fromRGB(205, 149, 58),
	A = Color3.fromRGB(162, 97, 44),
	N = Color3.fromRGB(115, 82, 56),
	D = 76,
}
local frankenstein = {
	"......KKKKKKKKKKK.....",
	".....KKHHHHHHHHKKK....",
	".....KHHHHHHHHHHKK....",
	".....KHHKHHHHKHHKK....",
	".....KHHKHGHHKHHKK....",
	".....KHKGGGHGGKHKK....",
	".....KKGGGGGGGGGKK....",
	".....KGSGSGSGGGGKK....",
	"....BKGSSSSSGGGGGKB...",
	"....BKGGEWGGEOGGGKB...",
	".....KGGEKGGEKGGGK....",
	".....KGGGGGGGGGGGK....",
	"......KGGGGKKGGGK.....",
	"......KGGGGGGGGK......",
	"..KK...KKGGGGKK..KK...",
	".KGGK..PKKKKKK..KGGK..",
	".KGSK.PPPYYYYPP.KSGK..",
	"..KGKPPPVYYYVPPPKGK...",
	"...KKPPPVAAAVPPPKK....",
	".....KPPVYYYYVPPK.....",
	"......KPVAAAVPK.......",
	"......KPVYYYYVPK......",
	"......KNNNNNNNNK......",
}
local frankensteinSteps = {
	{ "......KNNNKNNNNK......", ".....KNNNK.KNNNK......", ".....KDDDK.KDDDK......", "....KKDDDK.KDDDKK.....", "....KKKKKK.KKKKKK....." },
	{ "......KNNNKNNNNK......", "......KNNK.KNNNNK.....", "......KDDK..KDDDK.....", ".....KDDDK..KDDDKK....", ".....KKKKK..KKKKKK...." },
}

local function walkingSprite(parent, width, height, body, steps, colors)
	local poses = {}
	for _, flipped in { false, true } do
		local facing = {}
		for pose, feet in steps do
			local frame = Arte.layer(parent, "Passo " .. pose, width, height, 10)
			local rows = table.clone(body)
			for _, row in feet do
				table.insert(rows, row)
			end
			Arte.sprite(frame, rows, colors, flipped)
			frame.Visible = false
			facing[pose] = frame
		end
		table.insert(poses, facing)
	end
	return poses
end

function Arte.mummy(parent)
	return walkingSprite(parent, Arte.mummyWidth, Arte.mummyHeight, mummy, mummySteps, mummyColors)
end

function Arte.frankenstein(parent)
	return walkingSprite(parent, Arte.frankensteinWidth, Arte.frankensteinHeight, frankenstein, frankensteinSteps, frankensteinColors)
end

function Arte.lantern(parent, point)
	local flag = Arte.layer(parent, "Marco", 18, 32, 8)
	flag.Position = UDim2.fromOffset(point.x - 9, point.y - 32)
	Arte.rect(flag, 8, 8, 2, 24, 107, 8)
	Arte.rect(flag, 5, 3, 8, 9, 12, 8)
	Arte.rect(flag, 7, 5, 4, 5, Color3.fromRGB(43, 80, 117), 9)
	local light = Arte.rect(flag, 8, 6, 2, 3, 118, 10)
	local halo = {}
	for dy = -6, 6 do
		local width = 14 - 2 * math.max(0, math.abs(dy) - 2)
		local row = Arte.rect(flag, (18 - width) / 2, 7 + dy, width, 1, Color3.fromRGB(92, 155, 216), 9)
		table.insert(halo, row)
	end
	return function(active)
		light.BackgroundColor3 = if active then Color3.fromRGB(176, 220, 255) else Color3.fromRGB(100, 156, 206)
		for i, row in halo do
			row.BackgroundTransparency = (if active then 0.78 else 0.87) + math.abs(i - 7) * 0.014
		end
	end
end

function Arte.door(parent, point)
	local x, y = point.x - 16, point.y - 42
	Arte.rect(parent, x + 6, y, 20, 4, 101, 8)
	Arte.rect(parent, x + 3, y + 4, 26, 5, 91, 8)
	Arte.rect(parent, x, y + 9, 32, 33, 82, 8)
	Arte.rect(parent, x + 7, y + 8, 18, 34, 12, 9)
	Arte.rect(parent, x + 10, y + 4, 12, 6, 12, 9)
	Arte.rect(parent, x + 11, y + 14, 10, 2, 41, 10)
	Arte.rect(parent, x + 12, y + 28, 2, 2, 125, 10)
	Arte.rect(parent, x - 3, y + 40, 38, 2, 142, 10)
end

return Arte
