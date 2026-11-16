local MapBuilder = {}
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local function part(parent, name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name, item.Size, item.Position = name, size, position
	item.Anchored, item.Material, item.Color = true, material or Enum.Material.SmoothPlastic, color
	item.Parent = parent
	return item
end

local function spawn(parent, name, position)
	local item = Instance.new("SpawnLocation")
	item.Name, item.Size, item.Position = name, Vector3.new(6, 1, 6), position
	item.Transparency, item.CanCollide, item.Neutral = 1, false, true
	item.Parent = parent
	return item
end

function MapBuilder.Build()
	local map = Instance.new("Folder")
	map.Name = "BrainrotCourtroomMap"
	map.Parent = Workspace
	local c = {
		floor = Color3.fromRGB(77, 52, 107), wood = Color3.fromRGB(141, 82, 50),
		cream = Color3.fromRGB(255, 227, 157), accent = Color3.fromRGB(255, 96, 182),
	}
	part(map, "CourtroomFloor", Vector3.new(130, 2, 100), Vector3.new(0, 0, 0), c.floor)
	part(map, "BackWall", Vector3.new(130, 35, 2), Vector3.new(0, 17, 49), c.wood)
	part(map, "JudgePlatform", Vector3.new(28, 4, 14), Vector3.new(0, 4, 31), c.wood)
	part(map, "JudgeBench", Vector3.new(22, 7, 3), Vector3.new(0, 9, 25), c.cream)
	part(map, "ProsecutorDesk", Vector3.new(18, 4, 8), Vector3.new(-32, 3, 14), c.accent)
	part(map, "DefenseDesk", Vector3.new(18, 4, 8), Vector3.new(32, 3, 14), Color3.fromRGB(67, 196, 205))
	part(map, "DefendantStand", Vector3.new(12, 5, 8), Vector3.new(0, 3, 10), Color3.fromRGB(255, 193, 72))
	part(map, "WitnessStand", Vector3.new(14, 5, 8), Vector3.new(0, 3, -5), Color3.fromRGB(125, 214, 119))
	for row = 1, 2 do
		for column = -3, 3 do
			part(map, "JurySeat", Vector3.new(8, 3, 5), Vector3.new(column * 10, 2, -20 - (row * 9)), c.cream)
		end
	end
	part(map, "JailRoom", Vector3.new(25, 16, 2), Vector3.new(-48, 8, -35), c.wood)
	part(map, "EvidenceRoom", Vector3.new(25, 16, 2), Vector3.new(48, 8, -35), c.wood)
	part(map, "SecretLab", Vector3.new(20, 2, 20), Vector3.new(0, -6, -45), Color3.fromRGB(38, 31, 56), Enum.Material.Neon)
	part(map, "LobbyFloor", Vector3.new(80, 1, 35), Vector3.new(0, 0, 75), Color3.fromRGB(45, 99, 110), Enum.Material.WoodPlanks)
	part(map, "LobbyStage", Vector3.new(30, 2, 12), Vector3.new(0, 2, 68), c.cream)
	spawn(map, "LobbySpawn", Vector3.new(0, 5, 75))
	spawn(map, "CourtroomSpawn", Vector3.new(0, 5, 0))
	for role, position in pairs({ Judge = Vector3.new(0, 12, 31), Prosecutor = Vector3.new(-32, 8, 14), Defense = Vector3.new(32, 8, 14), Defendant = Vector3.new(0, 8, 10), Witness = Vector3.new(0, 8, -5), Jury = Vector3.new(0, 6, -29) }) do
		spawn(map, role .. "Spawn", position)
	end
	local jailDoor = part(map, "JailDoor", Vector3.new(2, 12, 22), Vector3.new(-35, 8, -35), c.accent, Enum.Material.Metal)
	local closed = jailDoor.CFrame
	local open = closed * CFrame.new(0, 0, -18)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText, prompt.HoldDuration = "Open / Close", "Jail Door", 0.3
	prompt.Parent = jailDoor
	local isOpen = false
	prompt.Triggered:Connect(function()
		isOpen = not isOpen
		TweenService:Create(jailDoor, TweenInfo.new(0.5), { CFrame = isOpen and open or closed }):Play()
	end)
	for index = 1, 4 do
		local evidence = part(map, "EvidenceDisplay_" .. index, Vector3.new(5, 2, 5), Vector3.new(39 + (index % 2) * 7, 3, -28 + math.floor(index / 2) * 8), c.cream, Enum.Material.Glass)
		local evidencePrompt = Instance.new("ProximityPrompt")
		evidencePrompt.ActionText, evidencePrompt.ObjectText = "Examine", "Evidence " .. index
		evidencePrompt.Parent = evidence
	end
	for i = 1, 12 do
		local angle = i * math.pi / 6
		local decoration = part(map, "BrainrotDecoration", Vector3.new(3, 3, 3), Vector3.new(math.cos(angle) * 55, 5, math.sin(angle) * 35), c.accent, Enum.Material.Neon)
		decoration.Shape = Enum.PartType.Ball
	end
	return map
end

return MapBuilder
