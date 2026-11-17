--[[
	MonetizationConfig.lua
	Brainrot Courtroom: The Final Verdict - Complete Monetization Configuration

	HOW TO CONFIGURE ROBLOX MONETIZATION IN ROBLOX STUDIO / CREATOR DASHBOARD:
	1. Publish this place to your Roblox Universe (Game Settings -> Publish).
	2. Go to https://create.roblox.com/dashboard/creations -> select your Experience.
	3. Go to "Monetization" -> "Passes" to create each Game Pass:
	   - Set the name, description, and price in Robux as specified below.
	   - Copy each Pass ID and paste it into MonetizationConfig.GamePasses.<KEY>.Id.
	4. Go to "Monetization" -> "Developer Products" to create each consumable product:
	   - Create products for Braincoin bundles and sound/particle effects.
	   - Copy each Product ID and paste it into MonetizationConfig.DeveloperProducts.<KEY>.Id.
	5. Go to "Monetization" -> "Subscriptions" for VIP Club (if enabled for your account):
	   - Configure monthly price and paste the Subscription ID into VIPSubscription.SubscriptionId.
	6. Private Servers: Configure under "Monetization" -> "Private Servers" in Creator Dashboard.
]]

local MonetizationConfig = {}

-- Game Passes (Permanent purchases)
MonetizationConfig.GamePasses = {
	VIP_JUDGE = {
		Key = "VIP_JUDGE",
		Id = 0, -- Replace with actual Game Pass ID from Creator Dashboard
		PriceRobux = 149,
		Name = "VIP Judge",
		Description = "Permanent VIP status, priority role weighting, VIP golden gavel, and sovereign title.",
		Icon = "rbxassetid://0",
		GrantedCosmetics = { "gavel_gold_judge", "title_gold_judge" },
	},
	GOLDEN_GAVEL = {
		Key = "GOLDEN_GAVEL",
		Id = 0, -- Replace with actual Game Pass ID from Creator Dashboard
		PriceRobux = 79,
		Name = "Golden Gavel",
		Description = "Permanent unlock for the Solid Gold Gavel and Royal Golden Judge Gavel.",
		Icon = "rbxassetid://0",
		GrantedCosmetics = { "gavel_gold", "gavel_gold_judge" },
	},
	PREMIUM_EMOTES = {
		Key = "PREMIUM_EMOTES",
		Id = 0, -- Replace with actual Game Pass ID from Creator Dashboard
		PriceRobux = 99,
		Name = "Premium Emotes",
		Description = "Unlock all special courtroom celebration dances, dramatic reactions, and emotes.",
		Icon = "rbxassetid://0",
		GrantedEmotes = { "VIP_BOW", "CHAMPAGNE", "MIC_DROP" },
	},
	CYBERPUNK_COURTROOM = {
		Key = "CYBERPUNK_COURTROOM",
		Id = 0, -- Replace with actual Game Pass ID from Creator Dashboard
		PriceRobux = 199,
		Name = "Cyberpunk Courtroom",
		Description = "Permanently unlocks the Neo-Tokyo Cyberpunk theme, Neon Gavel, and Glitch Aura.",
		Icon = "rbxassetid://0",
		GrantedCosmetics = { "theme_cyber", "gavel_cyber_overload", "aura_cyber_glitch", "title_netrunner" },
	},
	VIP_NAMEPLATE = {
		Key = "VIP_NAMEPLATE",
		Id = 0, -- Replace with actual Game Pass ID from Creator Dashboard
		PriceRobux = 49,
		Name = "VIP Nameplate",
		Description = "Golden glowing VIP nameplate and overhead badge displayed across all courtrooms.",
		Icon = "rbxassetid://0",
		GrantedCosmetics = { "title_vip" },
	},
}

-- Developer Products (Consumable & repeat purchases handled via ProcessReceipt)
MonetizationConfig.DeveloperProducts = {
	COINS_500 = {
		Key = "COINS_500",
		Id = 0, -- Replace with Developer Product ID
		PriceRobux = 49,
		Name = "500 Braincoins",
		Description = "Instant bag of 500 Braincoins to spend in the cosmetic shop.",
		RewardType = "Braincoins",
		RewardAmount = 500,
	},
	COINS_1500 = {
		Key = "COINS_1500",
		Id = 0, -- Replace with Developer Product ID
		PriceRobux = 99,
		Name = "1,500 Braincoins",
		Description = "Sack of 1,500 Braincoins with 10% bonus value.",
		RewardType = "Braincoins",
		RewardAmount = 1500,
	},
	COINS_4000 = {
		Key = "COINS_4000",
		Id = 0, -- Replace with Developer Product ID
		PriceRobux = 199,
		Name = "4,000 Braincoins",
		Description = "Chest of 4,000 Braincoins for courtroom tycoons.",
		RewardType = "Braincoins",
		RewardAmount = 4000,
	},
	COINS_12000 = {
		Key = "COINS_12000",
		Id = 0, -- Replace with Developer Product ID
		PriceRobux = 499,
		Name = "12,000 Braincoins",
		Description = "Vault of 12,000 Braincoins - best value pack!",
		RewardType = "Braincoins",
		RewardAmount = 12000,
	},
	BANANA_EFFECT = {
		Key = "BANANA_EFFECT",
		Id = 0, -- Replace with Developer Product ID
		PriceRobux = 19,
		Name = "Banana Effect",
		Description = "Instant funny banana peel slip animation and sound effect.",
		RewardType = "Effect",
		EffectId = "BananaSlip",
	},
	FUNNY_GAVEL_EFFECT = {
		Key = "FUNNY_GAVEL_EFFECT",
		Id = 0, -- Replace with Developer Product ID
		PriceRobux = 29,
		Name = "Funny Gavel Effect",
		Description = "High-pitched squeaky gavel sound and celebratory confetti explosion.",
		RewardType = "Effect",
		EffectId = "SqueakyGavel",
	},
}

-- VIP Subscription details
MonetizationConfig.VIPSubscription = {
	SubscriptionId = "0", -- Replace with Creator Dashboard Subscription ID
	PriceRobuxMonthly = 199,
	Name = "VIP Courtroom Club",
	Description = "Monthly membership granting exclusive VIP cosmetics, nameplate, lounge access, and 2,500 monthly Braincoins.",
	MonthlyCoins = 2500,
	DurationSeconds = 30 * 24 * 3600, -- 30 days
	Perks = {
		"Golden [VIP] Overhead Nameplate",
		"Exclusive VIP Lounge in Lobby",
		"Diamond VIP Halo Aura & Platinum Gavel",
		"Special VIP Emotes (Bow, Champagne, Mic Drop)",
		"2,500 Free Braincoins every month",
	},
	GrantedCosmetics = { "title_vip", "aura_vip", "gavel_vip" },
	GrantedEmotes = { "VIP_BOW", "CHAMPAGNE", "MIC_DROP" },
}

-- Private Servers settings
MonetizationConfig.PrivateServers = {
	PriceRobux = 50, -- Recommended price in Robux (0 for free)
	Enabled = true,
	Features = {
		"Custom Courtroom Theme Selector",
		"Host Trial Controls & Fast Forward",
		"Role Practice & Testing Mode",
		"Private Trial Record Log",
	},
}

-- Helper lookups
local productById = {}
for _, prod in pairs(MonetizationConfig.DeveloperProducts) do
	if prod.Id and prod.Id > 0 then
		productById[prod.Id] = prod
	end
	productById[prod.Key] = prod
end

local passById = {}
for _, pass in pairs(MonetizationConfig.GamePasses) do
	if pass.Id and pass.Id > 0 then
		passById[pass.Id] = pass
	end
	passById[pass.Key] = pass
end

function MonetizationConfig.GetProduct(idOrKey)
	return productById[idOrKey]
end

function MonetizationConfig.GetGamePass(idOrKey)
	return passById[idOrKey]
end

function MonetizationConfig.RegisterTestIds(productMap, passMap)
	if productMap then
		for key, id in pairs(productMap) do
			if MonetizationConfig.DeveloperProducts[key] then
				MonetizationConfig.DeveloperProducts[key].Id = id
				productById[id] = MonetizationConfig.DeveloperProducts[key]
			end
		end
	end
	if passMap then
		for key, id in pairs(passMap) do
			if MonetizationConfig.GamePasses[key] then
				MonetizationConfig.GamePasses[key].Id = id
				passById[id] = MonetizationConfig.GamePasses[key]
			end
		end
	end
end

return MonetizationConfig
