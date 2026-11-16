local Themes = {}

Themes.Catalog = {
	Classic = {
		Name = "Classic Mahogany",
		FloorColor = Color3.fromRGB(82, 54, 38),
		FloorMaterial = Enum.Material.WoodPlanks,
		WallColor = Color3.fromRGB(135, 95, 68),
		WallMaterial = Enum.Material.Wood,
		AccentColor = Color3.fromRGB(220, 185, 120),
		BenchColor = Color3.fromRGB(105, 65, 42),
		BenchMaterial = Enum.Material.WoodPlanks,
		DeskProsecutor = Color3.fromRGB(180, 50, 60),
		DeskDefense = Color3.fromRGB(50, 110, 180),
		Lighting = {
			Ambient = Color3.fromRGB(110, 95, 80),
			OutdoorAmbient = Color3.fromRGB(140, 125, 110),
			Brightness = 2,
			FogColor = Color3.fromRGB(150, 135, 120),
			FogEnd = 250,
			ClockTime = 14,
		},
	},
	Cyberpunk = {
		Name = "Neo-Tokyo Cyberpunk",
		FloorColor = Color3.fromRGB(25, 25, 35),
		FloorMaterial = Enum.Material.Metal,
		WallColor = Color3.fromRGB(35, 30, 50),
		WallMaterial = Enum.Material.DiamondPlate,
		AccentColor = Color3.fromRGB(0, 240, 255),
		BenchColor = Color3.fromRGB(45, 35, 65),
		BenchMaterial = Enum.Material.Neon,
		DeskProsecutor = Color3.fromRGB(255, 0, 128),
		DeskDefense = Color3.fromRGB(0, 240, 255),
		Lighting = {
			Ambient = Color3.fromRGB(50, 30, 80),
			OutdoorAmbient = Color3.fromRGB(40, 70, 100),
			Brightness = 1.5,
			FogColor = Color3.fromRGB(40, 20, 60),
			FogEnd = 220,
			ClockTime = 0,
		},
	},
	OhioDungeon = {
		Name = "Ohio Dungeon",
		FloorColor = Color3.fromRGB(45, 52, 45),
		FloorMaterial = Enum.Material.Cobblestone,
		WallColor = Color3.fromRGB(60, 68, 58),
		WallMaterial = Enum.Material.Slate,
		AccentColor = Color3.fromRGB(75, 200, 60),
		BenchColor = Color3.fromRGB(40, 48, 40),
		BenchMaterial = Enum.Material.Cobblestone,
		DeskProsecutor = Color3.fromRGB(100, 130, 40),
		DeskDefense = Color3.fromRGB(40, 120, 100),
		Lighting = {
			Ambient = Color3.fromRGB(40, 60, 40),
			OutdoorAmbient = Color3.fromRGB(30, 50, 35),
			Brightness = 1.2,
			FogColor = Color3.fromRGB(30, 50, 30),
			FogEnd = 180,
			ClockTime = 22,
		},
	},
	GoldenLuxury = {
		Name = "Royal Golden Palace",
		FloorColor = Color3.fromRGB(245, 245, 248),
		FloorMaterial = Enum.Material.Marble,
		WallColor = Color3.fromRGB(250, 245, 235),
		WallMaterial = Enum.Material.SmoothPlastic,
		AccentColor = Color3.fromRGB(255, 215, 0),
		BenchColor = Color3.fromRGB(255, 215, 0),
		BenchMaterial = Enum.Material.Marble,
		DeskProsecutor = Color3.fromRGB(160, 25, 45),
		DeskDefense = Color3.fromRGB(35, 75, 150),
		Lighting = {
			Ambient = Color3.fromRGB(140, 130, 110),
			OutdoorAmbient = Color3.fromRGB(180, 170, 140),
			Brightness = 2.5,
			FogColor = Color3.fromRGB(220, 210, 180),
			FogEnd = 300,
			ClockTime = 12,
		},
	},
}

function Themes.Get(id)
	return Themes.Catalog[id] or Themes.Catalog.Classic
end

function Themes.List()
	local list = {}
	for id, theme in pairs(Themes.Catalog) do
		table.insert(list, { Id = id, Name = theme.Name })
	end
	return list
end

return Themes
