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
	{ Id = "gavel_gold_judge", Name = "Royal Golden Judge Gavel", Category = "Gavel", Price = 1500, Rarity = "Legendary", Color = Color3.fromRGB(255, 223, 0), Description = "The ultimate symbol of golden judicial supremacy." },
	{ Id = "gavel_cyber_overload", Name = "Neon Overclock Gavel", Category = "Gavel", Price = 900, Rarity = "Epic", Color = Color3.fromRGB(0, 255, 230), Description = "Crackles with synthetic digital voltage." },
	{ Id = "gavel_ohio_sigma", Name = "Sigma Ohio Scepter", Category = "Gavel", Price = 1400, Rarity = "Legendary", Color = Color3.fromRGB(255, 60, 60), Description = "Imbued with dangerous concentrated Ohio energy." },
	{ Id = "gavel_rizzler", Name = "The Rizzler Gavel", Category = "Gavel", Price = 2200, Rarity = "Legendary", Color = Color3.fromRGB(255, 120, 200), Description = "Rizzes up the entire jury with a single pound." },
	{ Id = "gavel_vip", Name = "Platinum VIP Gavel", Category = "Gavel", Price = 0, Rarity = "Legendary", Color = Color3.fromRGB(220, 230, 255), Description = "Exclusive to active VIP Club members.", VIPOnly = true },

	-- Briefcases & Law Tools
	{ Id = "case_leather", Name = "Worn Leather Briefcase", Category = "Briefcase", Price = 0, Rarity = "Common", Color = Color3.fromRGB(100, 60, 35), Description = "Stuffed with crumpled evidence." },
	{ Id = "case_silver", Name = "Executive Steel Case", Category = "Briefcase", Price = 350, Rarity = "Rare", Color = Color3.fromRGB(200, 205, 215), Description = "Sleek and professional defense gear." },
	{ Id = "case_holo", Name = "Holo-Evidence Tablet", Category = "Briefcase", Price = 800, Rarity = "Epic", Color = Color3.fromRGB(67, 196, 205), Description = "Projects 3D holographic exhibits." },
	{ Id = "case_gold", Name = "Billionaire Portfolio", Category = "Briefcase", Price = 1500, Rarity = "Legendary", Color = Color3.fromRGB(255, 205, 50), Description = "Guaranteed to impress the jury." },
	{ Id = "case_gold_judge", Name = "Golden Judge Dossier", Category = "Briefcase", Price = 1200, Rarity = "Legendary", Color = Color3.fromRGB(240, 200, 80), Description = "Gold-leaf documents that settle every trial in seconds." },
	{ Id = "case_cyber_matrix", Name = "Cyber Matrix Briefcase", Category = "Briefcase", Price = 750, Rarity = "Epic", Color = Color3.fromRGB(30, 200, 255), Description = "Encrypted cyber-drive packed with decrypted secrets." },
	{ Id = "case_skibidi", Name = "Grimace Ohio Case", Category = "Briefcase", Price = 900, Rarity = "Epic", Color = Color3.fromRGB(150, 40, 200), Description = "Contains suspicious Ohio documents and shakes on its own." },
	{ Id = "case_mewing", Name = "Mewing Streak Case", Category = "Briefcase", Price = 1400, Rarity = "Epic", Color = Color3.fromRGB(220, 180, 140), Description = "Sharper than any lawyer's jawline." },

	-- Auras
	{ Id = "aura_sparkle", Name = "Brainrot Sparkles", Category = "Aura", Price = 250, Rarity = "Common", Color = Color3.fromRGB(255, 240, 120), Description = "Golden glitter flutters around you." },
	{ Id = "aura_smoke", Name = "Smoke of Suspicion", Category = "Aura", Price = 500, Rarity = "Rare", Color = Color3.fromRGB(120, 100, 140), Description = "Mysterious courtroom mist follows your steps." },
	{ Id = "aura_halo", Name = "Innocent Angel Halo", Category = "Aura", Price = 950, Rarity = "Epic", Color = Color3.fromRGB(255, 255, 255), Description = "Clearly incapable of any crime." },
	{ Id = "aura_thunder", Name = "Thunder of Judgment", Category = "Aura", Price = 1800, Rarity = "Legendary", Color = Color3.fromRGB(120, 220, 255), Description = "Crackling electric aura of pure authority." },
	{ Id = "aura_gold_judge", Name = "Golden Radiance", Category = "Aura", Price = 1600, Rarity = "Legendary", Color = Color3.fromRGB(255, 230, 100), Description = "A glorious golden halo radiating immense authority." },
	{ Id = "aura_cyber_glitch", Name = "Digital Glitch Aura", Category = "Aura", Price = 1100, Rarity = "Epic", Color = Color3.fromRGB(180, 0, 255), Description = "Reality glitches and shifts around your avatar." },
	{ Id = "aura_ohio_fog", Name = "Thick Ohio Smog", Category = "Aura", Price = 1050, Rarity = "Epic", Color = Color3.fromRGB(80, 160, 70), Description = "An ominous fog that follows the worst Ohio suspects." },
	{ Id = "aura_brainrot_god", Name = "Aura of Infinite Gyatt", Category = "Aura", Price = 2500, Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 0), Description = "Transcendent brainrot energy of cosmic proportions." },
	{ Id = "aura_vip", Name = "Diamond VIP Halo", Category = "Aura", Price = 0, Rarity = "Legendary", Color = Color3.fromRGB(190, 240, 255), Description = "A sparkling diamond VIP crown floating overhead.", VIPOnly = true },

	-- Titles
	{ Id = "title_rookie", Name = "Rookie Juror", Category = "Title", Price = 0, Rarity = "Common", Color = Color3.fromRGB(200, 200, 200), Description = "Just learning what an objection is." },
	{ Id = "title_attorney", Name = "Sigma Attorney", Category = "Title", Price = 300, Rarity = "Rare", Color = Color3.fromRGB(72, 224, 214), Description = "Never drops an argument." },
	{ Id = "title_detector", Name = "Cap Detector", Category = "Title", Price = 600, Rarity = "Epic", Color = Color3.fromRGB(255, 105, 180), Description = "Catches every single lie on the stand." },
	{ Id = "title_chief", Name = "Supreme Justice", Category = "Title", Price = 1200, Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 60), Description = "Your gavel rules the multiverse." },
	{ Id = "title_ohio", Name = "Ohio Menace", Category = "Title", Price = 1500, Rarity = "Legendary", Color = Color3.fromRGB(255, 75, 75), Description = "Wanted in forty-eight states." },
	{ Id = "title_gold_judge", Name = "Grand Golden Magistrate", Category = "Title", Price = 1000, Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 0), Description = "Anointed sovereign of the highest courtroom." },
	{ Id = "title_netrunner", Name = "Neo Netrunner", Category = "Title", Price = 650, Rarity = "Epic", Color = Color3.fromRGB(0, 240, 255), Description = "Jacking straight into the courthouse mainframe." },
	{ Id = "title_ohio_final_boss", Name = "Ohio Final Boss", Category = "Title", Price = 1350, Rarity = "Legendary", Color = Color3.fromRGB(255, 50, 50), Description = "The ultimate nightmare of prosecutors everywhere." },
	{ Id = "title_gyatt_lord", Name = "Supreme Rizz Lord", Category = "Title", Price = 2000, Rarity = "Legendary", Color = Color3.fromRGB(255, 100, 200), Description = "Unrivaled charisma inside and outside the courtroom." },
	{ Id = "title_vip", Name = "VIP Elite Justice", Category = "Title", Price = 0, Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 0), Description = "Prestigious member of the Courtroom VIP Society.", VIPOnly = true },

	-- Courtroom Themes
	{ Id = "theme_classic", Name = "Classic Mahogany", Category = "Theme", Price = 0, Rarity = "Common", Color = Color3.fromRGB(141, 82, 50), Description = "Traditional polished wood and warm lighting." },
	{ Id = "theme_cyber", Name = "Neo-Tokyo Cyberpunk", Category = "Theme", Price = 1000, Rarity = "Epic", Color = Color3.fromRGB(0, 240, 255), Description = "Futuristic neon strips and holographic panels." },
	{ Id = "theme_dungeon", Name = "Ohio Dungeon", Category = "Theme", Price = 1250, Rarity = "Epic", Color = Color3.fromRGB(65, 135, 70), Description = "Mossy stone walls and eerie green lanterns." },
	{ Id = "theme_luxury", Name = "Royal Golden Palace", Category = "Theme", Price = 2500, Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 0), Description = "White marble, pure gold trims, and red carpet." },
}

CosmeticsCatalog.Collections = {
	GoldenJudge = {
		Id = "GoldenJudge",
		Name = "Golden Judge Collection",
		Description = "Gleaming judicial power fit for the highest legal authority.",
		Items = { "gavel_gold_judge", "case_gold_judge", "aura_gold_judge", "title_gold_judge" },
	},
	Cyberpunk = {
		Id = "Cyberpunk",
		Name = "Cyberpunk Collection",
		Description = "High-tech neon accessories from the digital courtroom.",
		Items = { "gavel_cyber_overload", "case_cyber_matrix", "aura_cyber_glitch", "title_netrunner", "theme_cyber" },
	},
	Ohio = {
		Id = "Ohio",
		Name = "Ohio Collection",
		Description = "Uncanny items originating from deep within the Buckeye State.",
		Items = { "gavel_ohio_sigma", "case_skibidi", "aura_ohio_fog", "title_ohio_final_boss", "theme_dungeon" },
	},
	LegendaryBrainrot = {
		Id = "LegendaryBrainrot",
		Name = "Legendary Brainrot Collection",
		Description = "Maximum rizz, mewing streaks, and courtroom dominance.",
		Items = { "gavel_rizzler", "case_mewing", "aura_brainrot_god", "title_gyatt_lord" },
	},
	VIPExclusive = {
		Id = "VIPExclusive",
		Name = "VIP Elite Society Collection",
		Description = "Exclusive cosmetics granted automatically to active VIP Club members.",
		Items = { "gavel_vip", "aura_vip", "title_vip" },
	},
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
		if item.Category == category and item.Price == 0 and not item.VIPOnly then
			return item.Id
		end
	end
	return nil
end

function CosmeticsCatalog.IsValid(id)
	return itemMap[id] ~= nil
end

function CosmeticsCatalog.GetCollection(collectionId)
	return CosmeticsCatalog.Collections[collectionId]
end

function CosmeticsCatalog.GetAllCollections()
	return CosmeticsCatalog.Collections
end

return CosmeticsCatalog
