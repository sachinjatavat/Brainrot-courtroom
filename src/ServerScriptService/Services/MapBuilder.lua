local MapBuilder = {}
local Workspace = game:GetService("Workspace")

local function part(parent, name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name, item.Size, item.Position = name, size, position
	item.Anchored, item.Material, item.Color = true, material or Enum.Material.SmoothPlastic, color
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
	for i = 1, 12 do
		local angle = i * math.pi / 6
		local decoration = part(map, "BrainrotDecoration", Vector3.new(3, 3, 3), Vector3.new(math.cos(angle) * 55, 5, math.sin(angle) * 35), c.accent, Enum.Material.Neon)
		decoration.Shape = Enum.PartType.Ball
	end
	return map
end

return MapBuilder
