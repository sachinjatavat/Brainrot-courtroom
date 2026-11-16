local MapBuilder = {}
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Themes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Themes"))

local function part(parent, name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.Material = material or Enum.Material.SmoothPlastic
	item.Color = color
	item.CastShadow = true
	item.Parent = parent
	return item
end

local function spawn(parent, name, position)
	local item = Instance.new("SpawnLocation")
	item.Name = name
	item.Size = Vector3.new(6, 1, 6)
	item.Position = position
	item.Transparency = 1
	item.CanCollide = false
	item.Neutral = true
	item.Parent = parent
	return item
end

local function light(parent, color, brightness, range)
	local pt = Instance.new("PointLight")
	pt.Color = color or Color3.fromRGB(255, 230, 180)
	pt.Brightness = brightness or 1.2
	pt.Range = range or 20
	pt.Shadows = true
	pt.Parent = parent
	return pt
end

function MapBuilder.SetupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 130, 120)
	Lighting.Ambient = Color3.fromRGB(90, 80, 75)

	local bloom = Lighting:FindFirstChild("CourtroomBloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "CourtroomBloom"
		bloom.Intensity = 0.5
		bloom.Size = 16
		bloom.Threshold = 0.8
		bloom.Parent = Lighting
	end

	local cc = Lighting:FindFirstChild("CourtroomColorCorrection")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "CourtroomColorCorrection"
		cc.Contrast = 0.08
		cc.Saturation = 0.15
		cc.TintColor = Color3.fromRGB(255, 250, 240)
		cc.Parent = Lighting
	end
end

function MapBuilder.Build()
	local existing = Workspace:FindFirstChild("BrainrotCourtroomMap")
	if existing then existing:Destroy() end

	local map = Instance.new("Folder")
	map.Name = "BrainrotCourtroomMap"
	map.Parent = Workspace

	MapBuilder.SetupLighting()

	local c = {
		floor = Color3.fromRGB(82, 54, 38),
		wood = Color3.fromRGB(115, 75, 48),
		darkWood = Color3.fromRGB(65, 40, 25),
		cream = Color3.fromRGB(255, 242, 205),
		gold = Color3.fromRGB(255, 215, 0),
		carpet = Color3.fromRGB(160, 30, 45),
		accent = Color3.fromRGB(255, 105, 180),
		marble = Color3.fromRGB(240, 240, 245),
	}

	-- ==================== COURTROOM CHAMBER ====================
	-- Floor & Center Runner
	part(map, "CourtroomFloor", Vector3.new(130, 2, 110), Vector3.new(0, 0, 0), c.floor, Enum.Material.WoodPlanks)
	part(map, "CenterCarpet", Vector3.new(14, 2.05, 90), Vector3.new(0, 0.05, 0), c.carpet, Enum.Material.Fabric)

	-- Walls
	part(map, "BackWall", Vector3.new(130, 40, 3), Vector3.new(0, 20, 55), c.wood, Enum.Material.Wood)
	part(map, "LeftWall", Vector3.new(3, 40, 110), Vector3.new(-65, 20, 0), c.wood, Enum.Material.Wood)
	part(map, "RightWall", Vector3.new(3, 40, 110), Vector3.new(65, 20, 0), c.wood, Enum.Material.Wood)
	part(map, "DividerWall", Vector3.new(130, 40, 3), Vector3.new(0, 20, -55), c.wood, Enum.Material.Wood)

	-- Wainscoting & Moldings
	part(map, "LeftWainscot", Vector3.new(3.2, 10, 110), Vector3.new(-64.5, 5, 0), c.darkWood, Enum.Material.WoodPlanks)
	part(map, "RightWainscot", Vector3.new(3.2, 10, 110), Vector3.new(64.5, 5, 0), c.darkWood, Enum.Material.WoodPlanks)
	part(map, "BackWainscot", Vector3.new(130, 10, 3.2), Vector3.new(0, 5, 54.5), c.darkWood, Enum.Material.WoodPlanks)

	-- Classical Fluted Columns along side walls
	for side = -1, 1, 2 do
		for z = -40, 40, 25 do
			local col = part(map, "Pillar", Vector3.new(5, 36, 5), Vector3.new(side * 62, 19, z), c.marble, Enum.Material.Marble)
			part(map, "PillarBase", Vector3.new(7, 3, 7), Vector3.new(side * 62, 2.5, z), c.gold, Enum.Material.Metal)
			part(map, "PillarCap", Vector3.new(7, 3, 7), Vector3.new(side * 62, 36.5, z), c.gold, Enum.Material.Metal)
			local pl = light(col, Color3.fromRGB(255, 235, 200), 0.8, 25)
			pl.Range = 22
		end
	end

	-- Ceiling Cross-Beams & Chandeliers
	for z = -35, 35, 35 do
		local beam = part(map, "CeilingBeam", Vector3.new(130, 3, 4), Vector3.new(0, 38, z), c.darkWood, Enum.Material.Wood)
		local chandelier = part(map, "Chandelier", Vector3.new(6, 2, 6), Vector3.new(0, 34, z), c.gold, Enum.Material.Metal)
		chandelier.Shape = Enum.PartType.Cylinder
		chandelier.Orientation = Vector3.new(0, 0, 90)
		light(chandelier, Color3.fromRGB(255, 240, 200), 1.8, 45)
	end

	-- ==================== JUDGE'S BENCH ====================
	part(map, "JudgePlatform", Vector3.new(36, 5, 18), Vector3.new(0, 4.5, 36), c.darkWood, Enum.Material.Wood)
	part(map, "JudgeStairs", Vector3.new(14, 2.5, 6), Vector3.new(0, 1.5, 25), c.darkWood, Enum.Material.WoodPlanks)
	local bench = part(map, "JudgeBench", Vector3.new(28, 8, 4), Vector3.new(0, 10, 30), c.wood, Enum.Material.WoodPlanks)
	part(map, "JudgeBenchTop", Vector3.new(30, 1, 5.5), Vector3.new(0, 14.5, 30), c.darkWood, Enum.Material.Wood)

	-- Court Seal on Back Wall
	local seal = part(map, "CourtSeal", Vector3.new(14, 14, 0.8), Vector3.new(0, 26, 53.2), c.gold, Enum.Material.Metal)
	seal.Shape = Enum.PartType.Cylinder
	seal.Orientation = Vector3.new(90, 0, 0)
	local sealText = Instance.new("SurfaceGui")
	sealText.Face = Enum.NormalId.Back
	sealText.Parent = seal
	local sealLabel = Instance.new("TextLabel")
	sealLabel.Size = UDim2.fromScale(1, 1)
	sealLabel.BackgroundTransparency = 1
	sealLabel.Font = Enum.Font.GothamBlack
	sealLabel.TextColor3 = Color3.fromRGB(40, 25, 10)
	sealLabel.TextScaled = true
	sealLabel.Text = "BRAINROT\nJUSTICE"
	sealLabel.Parent = sealText

	-- Interactive Gavel on Bench
	local gavelBlock = part(map, "GavelBlock", Vector3.new(2.5, 0.6, 2.5), Vector3.new(5, 15.2, 30), c.darkWood, Enum.Material.Wood)
	local gavelHead = part(map, "GavelHead", Vector3.new(1.8, 1, 1), Vector3.new(5, 16.2, 30), c.wood, Enum.Material.Wood)
	gavelHead.Shape = Enum.PartType.Cylinder
	gavelHead.Orientation = Vector3.new(0, 0, 90)
	local gavelHandle = part(map, "GavelHandle", Vector3.new(0.4, 0.4, 3), Vector3.new(5, 16.2, 28.5), c.gold, Enum.Material.Metal)

	local gavelPrompt = Instance.new("ProximityPrompt")
	gavelPrompt.ActionText = "Slam Gavel"
	gavelPrompt.ObjectText = "Judge's Gavel"
	gavelPrompt.HoldDuration = 0.2
	gavelPrompt.MaxActivationDistance = 14
	gavelPrompt.Parent = gavelHead

	local gavelDebounce = false
	gavelPrompt.Triggered:Connect(function(player)
		if gavelDebounce then return end
		gavelDebounce = true
		local slamSound = Instance.new("Sound")
		slamSound.SoundId = "rbxasset://sounds/action_falling.mp3"
		slamSound.PlaybackSpeed = 1.6
		slamSound.Volume = 1.5
		slamSound.Parent = gavelHead
		slamSound:Play()

		TweenService:Create(gavelHead, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Down), {
			Position = Vector3.new(5, 15.6, 30),
		}):Play()
		task.wait(0.1)
		TweenService:Create(gavelHead, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {
			Position = Vector3.new(5, 16.2, 30),
		}):Play()
		task.wait(0.6)
		gavelDebounce = false
	end)

	-- ==================== WITNESS STAND ====================
	part(map, "WitnessStand", Vector3.new(12, 6, 10), Vector3.new(0, 3, 5), c.wood, Enum.Material.Wood)
	part(map, "WitnessRailing", Vector3.new(13, 3, 1), Vector3.new(0, 7, 9.5), c.gold, Enum.Material.Metal)
	local mic = part(map, "WitnessMic", Vector3.new(0.4, 2.5, 0.4), Vector3.new(0, 7.5, 8.5), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	light(mic, Color3.fromRGB(255, 245, 220), 1.2, 14)

	-- ==================== DEFENDANT DOCK ====================
	part(map, "DefendantStand", Vector3.new(12, 4, 8), Vector3.new(0, 2, -12), Color3.fromRGB(200, 140, 50), Enum.Material.Wood)
	part(map, "DefendantRailing", Vector3.new(12.5, 3.5, 8.5), Vector3.new(0, 5, -12), c.darkWood, Enum.Material.WoodPlanks)

	-- ==================== LAWYER STATIONS ====================
	-- Prosecutor Desk (Left)
	part(map, "ProsecutorDesk", Vector3.new(22, 5, 9), Vector3.new(-34, 3.5, 12), Color3.fromRGB(180, 50, 60), Enum.Material.WoodPlanks)
	part(map, "ProsecutorTop", Vector3.new(24, 0.8, 10), Vector3.new(-34, 6.2, 12), c.darkWood, Enum.Material.Wood)
	local pLamp = part(map, "ProsecutorLamp", Vector3.new(1, 2, 1), Vector3.new(-40, 7.4, 14), c.gold, Enum.Material.Metal)
	light(pLamp, Color3.fromRGB(255, 220, 180), 1.0, 15)

	-- Defense Desk (Right)
	part(map, "DefenseDesk", Vector3.new(22, 5, 9), Vector3.new(34, 3.5, 12), Color3.fromRGB(50, 110, 180), Enum.Material.WoodPlanks)
	part(map, "DefenseTop", Vector3.new(24, 0.8, 10), Vector3.new(34, 6.2, 12), c.darkWood, Enum.Material.Wood)
	local dLamp = part(map, "DefenseLamp", Vector3.new(1, 2, 1), Vector3.new(40, 7.4, 14), c.gold, Enum.Material.Metal)
	light(dLamp, Color3.fromRGB(255, 220, 180), 1.0, 15)

	-- ==================== JURY BOX ====================
	part(map, "JuryPlatform1", Vector3.new(32, 2.5, 10), Vector3.new(-44, 2, -18), c.wood, Enum.Material.Wood)
	part(map, "JuryPlatform2", Vector3.new(32, 4.5, 10), Vector3.new(-44, 3, -29), c.wood, Enum.Material.Wood)
	part(map, "JuryRailing", Vector3.new(33, 4, 1), Vector3.new(-44, 5.5, -12.5), c.gold, Enum.Material.Metal)
	for col = -3, 3, 2 do
		part(map, "JurySeat1_" .. col, Vector3.new(4, 2.5, 4), Vector3.new(-44 + col * 4, 4, -18), c.cream, Enum.Material.Fabric)
		part(map, "JurySeat2_" .. col, Vector3.new(4, 2.5, 4), Vector3.new(-44 + col * 4, 6, -29), c.cream, Enum.Material.Fabric)
	end

	-- ==================== SPECTATOR GALLERY ====================
	part(map, "GalleryDivider", Vector3.new(80, 4, 1), Vector3.new(10, 3, -32), c.darkWood, Enum.Material.Wood)
	for row = 1, 3 do
		for col = -1, 2 do
			part(map, "Pew_" .. row .. "_" .. col, Vector3.new(16, 2.8, 3.5), Vector3.new(col * 19, 2.5, -34 - (row * 6)), c.wood, Enum.Material.WoodPlanks)
		end
	end

	-- ==================== EVIDENCE ROOM & PEDESTALS ====================
	part(map, "EvidenceRoom", Vector3.new(28, 18, 2), Vector3.new(48, 9, -42), c.wood, Enum.Material.Wood)
	for index = 1, 4 do
		local ex = 42 + (index % 2) * 10
		local ez = -36 + math.floor(index / 2) * 9
		local pedestal = part(map, "EvidenceDisplay_" .. index, Vector3.new(4, 3.5, 4), Vector3.new(ex, 2.8, ez), c.cream, Enum.Material.Glass)
		local glow = light(pedestal, Color3.fromRGB(72, 224, 214), 1.2, 10)
		glow.Range = 10
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Examine Exhibit " .. index
		prompt.ObjectText = "Evidence Pedestal"
		prompt.HoldDuration = 0.2
		prompt.Parent = pedestal
	end

	-- ==================== JAIL CELL ====================
	part(map, "JailRoom", Vector3.new(28, 18, 2), Vector3.new(-48, 9, -42), c.darkWood, Enum.Material.Metal)
	local jailDoor = part(map, "JailDoor", Vector3.new(2, 14, 18), Vector3.new(-34, 8, -42), Color3.fromRGB(60, 60, 60), Enum.Material.DiamondPlate)
	local closed = jailDoor.CFrame
	local open = closed * CFrame.new(0, 0, -14)
	local jailPrompt = Instance.new("ProximityPrompt")
	jailPrompt.ActionText = "Open / Close"
	jailPrompt.ObjectText = "Holding Cell"
	jailPrompt.HoldDuration = 0.3
	jailPrompt.Parent = jailDoor
	local isJailOpen = false
	jailPrompt.Triggered:Connect(function()
		isJailOpen = not isJailOpen
		TweenService:Create(jailDoor, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { CFrame = isJailOpen and open or closed }):Play()
	end)

	-- ==================== GRAND LOBBY ====================
	part(map, "LobbyFloor", Vector3.new(110, 2, 60), Vector3.new(0, 0, 95), Color3.fromRGB(40, 45, 60), Enum.Material.Marble)
	part(map, "LobbyWallBack", Vector3.new(110, 30, 2), Vector3.new(0, 15, 125), c.darkWood, Enum.Material.Wood)
	part(map, "LobbyWallLeft", Vector3.new(2, 30, 60), Vector3.new(-55, 15, 95), c.darkWood, Enum.Material.Wood)
	part(map, "LobbyWallRight", Vector3.new(2, 30, 60), Vector3.new(55, 15, 95), c.darkWood, Enum.Material.Wood)

	-- Archway dividing Lobby and Courtroom
	local archLeft = part(map, "ArchLeft", Vector3.new(4, 25, 4), Vector3.new(-16, 13, 65), c.gold, Enum.Material.Metal)
	local archRight = part(map, "ArchRight", Vector3.new(4, 25, 4), Vector3.new(16, 13, 65), c.gold, Enum.Material.Metal)
	local archTop = part(map, "ArchTop", Vector3.new(36, 4, 4), Vector3.new(0, 25, 65), c.gold, Enum.Material.Metal)
	light(archTop, Color3.fromRGB(255, 215, 0), 2.0, 30)

	-- Reception Desk
	local reception = part(map, "ReceptionDesk", Vector3.new(22, 5, 6), Vector3.new(0, 3.5, 115), c.wood, Enum.Material.WoodPlanks)
	part(map, "ReceptionCounter", Vector3.new(24, 0.8, 7), Vector3.new(0, 6.2, 115), c.marble, Enum.Material.Marble)

	-- Matchmaking Status Billboard
	local billboardPart = part(map, "MatchmakingBillboard", Vector3.new(28, 12, 1), Vector3.new(0, 18, 123.8), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "StatusBoard"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = billboardPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
	frame.BorderSizePixel = 0
	frame.Parent = surfaceGui

	local bTitle = Instance.new("TextLabel")
	bTitle.Size = UDim2.fromScale(1, 0.35)
	bTitle.BackgroundTransparency = 1
	bTitle.Font = Enum.Font.GothamBlack
	bTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	bTitle.TextScaled = true
	bTitle.Text = "⚖️ BRAINROT COURTROOM ⚖️"
	bTitle.Parent = frame

	local bStatus = Instance.new("TextLabel")
	bStatus.Position = UDim2.fromScale(0, 0.35)
	bStatus.Size = UDim2.fromScale(1, 0.35)
	bStatus.BackgroundTransparency = 1
	bStatus.Font = Enum.Font.GothamBold
	bStatus.TextColor3 = Color3.fromRGB(72, 224, 214)
	bStatus.TextScaled = true
	bStatus.Text = "MATCHMAKING IN PROGRESS..."
	bStatus.Parent = frame

	local bTip = Instance.new("TextLabel")
	bTip.Position = UDim2.fromScale(0, 0.7)
	bTip.Size = UDim2.fromScale(1, 0.28)
	bTip.BackgroundTransparency = 1
	bTip.Font = Enum.Font.Gotham
	bTip.TextColor3 = Color3.fromRGB(255, 240, 210)
	bTip.TextScaled = true
	bTip.Text = "💡 Tip: Objections can turn the jury's verdict!"
	bTip.Parent = frame

	-- Waiting Lounge: Sofas & Coffee Table
	part(map, "Sofa1", Vector3.new(16, 3, 5), Vector3.new(-32, 2.5, 95), Color3.fromRGB(150, 40, 50), Enum.Material.Fabric)
	part(map, "Sofa1_Back", Vector3.new(16, 5, 1.5), Vector3.new(-32, 4.5, 97), Color3.fromRGB(130, 35, 45), Enum.Material.Fabric)
	part(map, "CoffeeTable", Vector3.new(10, 2, 5), Vector3.new(-32, 2, 88), c.wood, Enum.Material.WoodPlanks)

	-- Interactive Water Cooler
	local cooler = part(map, "WaterCooler", Vector3.new(2.5, 5, 2.5), Vector3.new(-46, 3.5, 115), Color3.fromRGB(220, 230, 245), Enum.Material.Glass)
	local coolerPrompt = Instance.new("ProximityPrompt")
	coolerPrompt.ActionText = "Drink Cold Water"
	coolerPrompt.ObjectText = "Water Dispenser"
	coolerPrompt.HoldDuration = 0.3
	coolerPrompt.Parent = cooler
	coolerPrompt.Triggered:Connect(function(player)
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/action_swim.mp3"
		sound.PlaybackSpeed = 1.4
		sound.Volume = 0.8
		sound.Parent = cooler
		sound:Play()
	end)

	-- Top Lawyers Leaderboard Podium (3-tiered)
	local p1 = part(map, "Podium_1st", Vector3.new(6, 4.5, 6), Vector3.new(34, 3, 95), c.gold, Enum.Material.Metal)
	local p2 = part(map, "Podium_2nd", Vector3.new(5, 3.2, 5), Vector3.new(27, 2.4, 95), Color3.fromRGB(190, 195, 205), Enum.Material.Metal)
	local p3 = part(map, "Podium_3rd", Vector3.new(5, 2.2, 5), Vector3.new(41, 1.9, 95), Color3.fromRGB(180, 115, 60), Enum.Material.Metal)

	-- Interactive Practice Witness Dummy
	local dummy = part(map, "PracticeDummy", Vector3.new(3, 5, 2), Vector3.new(34, 4, 115), Color3.fromRGB(255, 180, 120), Enum.Material.Wood)
	local dummyHead = part(map, "PracticeDummyHead", Vector3.new(2, 2, 2), Vector3.new(34, 7.5, 115), Color3.fromRGB(255, 210, 77), Enum.Material.SmoothPlastic)
	dummyHead.Shape = Enum.PartType.Ball
	local dummyPrompt = Instance.new("ProximityPrompt")
	dummyPrompt.ActionText = "Cross-Examine Dummy"
	dummyPrompt.ObjectText = "Witness Practice Dummy"
	dummyPrompt.HoldDuration = 0.2
	dummyPrompt.Parent = dummyHead

	local dummyResponses = {
		"I swear on Skibidi that I was not at the crime scene!",
		"Your Honor, that is pure cap and you know it!",
		"I only plead the fifth rizz!",
		"The suspect did indeed look Ohio-certified!",
	}
	dummyPrompt.Triggered:Connect(function(player)
		local bGui = Instance.new("BillboardGui")
		bGui.Size = UDim2.fromScale(5, 2)
		bGui.StudsOffset = Vector3.new(0, 3, 0)
		bGui.AlwaysOnTop = true
		bGui.Adornee = dummyHead
		bGui.Parent = dummyHead

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 0.2
		lbl.BackgroundColor3 = Color3.fromRGB(28, 22, 43)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextColor3 = Color3.fromRGB(255, 220, 50)
		lbl.TextScaled = true
		lbl.Text = dummyResponses[math.random(1, #dummyResponses)]
		lbl.Parent = bGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = lbl

		task.delay(3, function()
			bGui:Destroy()
		end)
	end)

	-- ==================== SPAWNS ====================
	spawn(map, "LobbySpawn", Vector3.new(0, 4, 95))
	spawn(map, "CourtroomSpawn", Vector3.new(0, 4, 0))

	for role, position in pairs({
		Judge = Vector3.new(0, 15, 36),
		Prosecutor = Vector3.new(-34, 7, 12),
		Defense = Vector3.new(34, 7, 12),
		Defendant = Vector3.new(0, 7, -12),
		Witness = Vector3.new(0, 8, 5),
		Jury = Vector3.new(-44, 7, -22),
	}) do
		spawn(map, role .. "Spawn", position)
	end

	return map
end

function MapBuilder.ApplyTheme(themeName)
	local theme = Themes.Get(themeName)
	local map = Workspace:FindFirstChild("BrainrotCourtroomMap")
	if not map then return end

	local floor = map:FindFirstChild("CourtroomFloor")
	if floor then
		floor.Color = theme.FloorColor
		floor.Material = theme.FloorMaterial
	end

	for _, wallName in ipairs({ "BackWall", "LeftWall", "RightWall", "DividerWall" }) do
		local wall = map:FindFirstChild(wallName)
		if wall then
			wall.Color = theme.WallColor
			wall.Material = theme.WallMaterial
		end
	end

	local bench = map:FindFirstChild("JudgeBench")
	if bench then
		bench.Color = theme.BenchColor
		bench.Material = theme.BenchMaterial
	end

	local prosDesk = map:FindFirstChild("ProsecutorDesk")
	if prosDesk then prosDesk.Color = theme.DeskProsecutor end

	local defDesk = map:FindFirstChild("DefenseDesk")
	if defDesk then defDesk.Color = theme.DeskDefense end

	-- Apply Lighting
	if theme.Lighting then
		Lighting.Ambient = theme.Lighting.Ambient
		Lighting.OutdoorAmbient = theme.Lighting.OutdoorAmbient
		Lighting.Brightness = theme.Lighting.Brightness
		Lighting.FogColor = theme.Lighting.FogColor
		Lighting.FogEnd = theme.Lighting.FogEnd
		Lighting.ClockTime = theme.Lighting.ClockTime
	end
end

return MapBuilder
