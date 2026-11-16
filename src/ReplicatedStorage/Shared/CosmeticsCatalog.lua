local CosmeticsCatalog = {}

CosmeticsCatalog.Categories = {
	GAVEL = "Gavel",
	BRIEFCASE = "Briefcase",
	AURA = "Aura",
	TITLE = "Title",
	THEME = "Theme",
}

CosmeticsCatalog.Rarities = {
	COMMON = { Name = "Common", Color = Color3.fromRGB(180, 180, 180) },
	RARE = { Name = "Rare", Color = Color3.fromRGB(72, 170, 255) },
	EPIC = { Name = "Epic", Color = Color3.fromRGB(185, 75, 255) },
	LEGENDARY = { Name = "Legendary", Color = Color3.fromRGB(255, 200, 45) },
}

local ITEMS = {
	-- Gavels
	{ Id = "gavel_wood", Name = "Classic Oak Gavel", Category = "Gavel", Price = 0, Rarity = "Common", Color = Color3.fromRGB(141, 82, 50), Description = "Standard wooden gavel for keeping order." },
	{ Id = "gavel_gold", Name = "Solid Gold Gavel", Category = "Gavel", Price = 450, Rarity = "Rare", Color = Color3.fromRGB(255, 215, 0), Description = "Crafted from pure Brainrot bullion." },
	{ Id = "gavel_cyber", Name = "Cyberpunk Gavel", Category = "Gavel", Price = 850, Rarity = "Epic", Color = Color3.fromRGB(0, 240, 255), Description = "Emits neon sparks on impact." },
	{ Id = "gavel_banana", Name = "Ohio Banana Gavel", Category = "Gavel", Price = 1200, Rarity = "Legendary", Color = Color3.fromRGB(255, 235, 50), Description = "Soft impact, maximum potassium." },
	{ Id = "gavel_diamond", Name = "Diamond Justice", Category = "Gavel", Price = 2000, Rarity = "Legendary", Color = Color3.fromRGB(185, 242, 255), Description = "Unbreakable judicial authority." },

	-- Briefcases & Law Tools
	{ Id = "case_leather", Name = "Worn Leather Briefcase", Category = "Briefcase", Price = 0, Rarity = "Common", Color = Color3.fromRGB(100, 60, 35), Description = "Stuffed with crumpled evidence." },
	{ Id = "case_silver", Name = "Executive Steel Case", Category = "Briefcase", Price = 350, Rarity = "Rare", Color = Color3.fromRGB(200, 205, 215), Description = "Sleek and professional defense gear." },
	{ Id = "case_holo", Name = "Holo-Evidence Tablet", Category = "Briefcase", Price = 800, Rarity = "Epic", Color = Color3.fromRGB(67, 196, 205), Description = "Projects 3D holographic exhibits." },
	{ Id = "case_gold", Name = "Billionaire Portfolio", Category = "Briefcase", Price = 1500, Rarity = "Legendary", Color = Color3.fromRGB(255, 205, 50), Description = "Guaranteed to impress the jury." },

	-- Auras
	{ Id = "aura_sparkle", Name = "Brainrot Sparkles", Category = "Aura", Price = 250, Rarity = "Common", Color = Color3.fromRGB(255, 240, 120), Description = "Golden glitter flutters around you." },
	{ Id = "aura_smoke", Name = "Smoke of Suspicion", Category = "Aura", Price = 500, Rarity = "Rare", Color = Color3.fromRGB(120, 100, 140), Description = "Mysterious courtroom mist follows your steps." },
	{ Id = "aura_halo", Name = "Innocent Angel Halo", Category = "Aura", Price = 950, Rarity = "Epic", Color = Color3.fromRGB(255, 255, 255), Description = "Clearly incapable of any crime." },
	{ Id = "aura_thunder", Name = "Thunder of Judgment", Category = "Aura", Price = 1800, Rarity = "Legendary", Color = Color3.fromRGB(120, 220, 255), Description = "Crackling electric aura of pure authority." },

	-- Titles
	{ Id = "title_rookie", Name = "Rookie Juror", Category = "Title", Price = 0, Rarity = "Common", Color = Color3.fromRGB(200, 200, 200), Description = "Just learning what an objection is." },
	{ Id = "title_attorney", Name = "Sigma Attorney", Category = "Title", Price = 300, Rarity = "Rare", Color = Color3.fromRGB(72, 224, 214), Description = "Never drops an argument." },
	{ Id = "title_detector", Name = "Cap Detector", Category = "Title", Price = 600, Rarity = "Epic", Color = Color3.fromRGB(255, 105, 180), Description = "Catches every single lie on the stand." },
	{ Id = "title_chief", Name = "Supreme Justice", Category = "Title", Price = 1200, Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 60), Description = "Your gavel rules the multiverse." },
	{ Id = "title_ohio", Name = "Ohio Menace", Category = "Title", Price = 1500, Rarity = "Legendary", Color = Color3.fromRGB(255, 75, 75), Description = "Wanted in forty-eight states." },

	-- Courtroom Themes
	{ Id = "theme_classic", Name = "Classic Mahogany", Category = "Theme", Price = 0, Rarity = "Common", Color = Color3.fromRGB(141, 82, 50), Description = "Traditional polished wood and warm lighting." },
	{ Id = "theme_cyber", Name = "Neo-Tokyo Cyberpunk", Category = "Theme", Price = 1000, Rarity = "Epic", Color = Color3.fromRGB(0, 240, 255), Description = "Futuristic neon strips and holographic panels." },
	{ Id = "theme_dungeon", Name = "Ohio Dungeon", Category = "Theme", Price = 1250, Rarity = "Epic", Color = Color3.fromRGB(65, 135, 70), Description = "Mossy stone walls and eerie green lanterns." },
	{ Id = "theme_luxury", Name = "Royal Golden Palace", Category = "Theme", Price = 2500, Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 0), Description = "White marble, pure gold trims, and red carpet." },
}

local itemMap = {}
for _, item in ipairs(ITEMS) do
	itemMap[item.Id] = item
end

function CosmeticsCatalog.Get(id)
	return itemMap[id]
end

function CosmeticsCatalog.GetAll()
	return ITEMS
end

function CosmeticsCatalog.GetByCategory(category)
	local result = {}
	for _, item in ipairs(ITEMS) do
		if item.Category == category then
			table.insert(result, item)
		end
	end
	return result
end

function CosmeticsCatalog.GetDefault(category)
	for _, item in ipairs(ITEMS) do
		if item.Category == category and item.Price == 0 then
			return item.Id
		end
	end
	return nil
end

function CosmeticsCatalog.IsValid(id)
	return itemMap[id] ~= nil
end

return CosmeticsCatalog
