--[[
	MonetizationService.lua
	Brainrot Courtroom: The Final Verdict - Complete Server-Authoritative Monetization Engine

	Features:
	- MarketplaceService.ProcessReceipt: strictly idempotent receipt processing.
	- Game Pass ownership checking & permanent unlock caching.
	- VIP subscription status verification with server-side expiration enforcement.
	- Duplicate purchase protection via persistent receipt records.
	- Safe reward delivery with transactional DataStore saving before acknowledgement.
	- Private server support.
	- Monetization analytics (revenue tracking, popular items, failure rates).
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local MonetizationConfig = require(SharedFolder:WaitForChild("MonetizationConfig"))

local MonetizationService = {}

-- Analytics storage
local analytics = {
	TotalRobuxEarned = 0,
	PurchasesByProduct = {},
	PurchaseFailures = 0,
	TotalReceiptsProcessed = 0,
	GamePassesChecked = 0,
	VIPCheckouts = 0,
}

local dataServiceRef = nil
local remotesRef = nil
local isStarted = false

-- Fallback enum values if Enum is mocked or incomplete
local PurchaseDecision = {
	PurchaseGranted = (Enum and Enum.ProductPurchaseDecision and Enum.ProductPurchaseDecision.PurchaseGranted) or 0,
	NotProcessedYet = (Enum and Enum.ProductPurchaseDecision and Enum.ProductPurchaseDecision.NotProcessedYet) or 1,
}

-- ==================== INTERNAL HELPERS ====================

local function logAnalytics(productId, robuxAmount, success)
	if success then
		analytics.TotalRobuxEarned += (robuxAmount or 0)
		analytics.TotalReceiptsProcessed += 1
		local key = tostring(productId)
		analytics.PurchasesByProduct[key] = (analytics.PurchasesByProduct[key] or 0) + 1
	else
		analytics.PurchaseFailures += 1
	end
end

-- ==================== PROCESS RECEIPT (IDEMPOTENT & AUTHORITATIVE) ====================

function MonetizationService.ProcessReceipt(receiptInfo)
	if not receiptInfo or type(receiptInfo) ~= "table" then
		return PurchaseDecision.NotProcessedYet
	end

	local purchaseId = receiptInfo.PurchaseId
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local currencySpent = receiptInfo.CurrencySpent or 0

	if not purchaseId or not playerId or not productId then
		warn("[MonetizationService] ProcessReceipt rejected: missing mandatory fields in receiptInfo.")
		logAnalytics(productId, currencySpent, false)
		return PurchaseDecision.NotProcessedYet
	end

	-- 1. Locate player in server
	local player = Players:GetPlayerByUserId(playerId)
	if not player or not player.Parent then
		warn(string.format("[MonetizationService] Player %d not currently in this server. Postponing receipt %s.", playerId, tostring(purchaseId)))
		return PurchaseDecision.NotProcessedYet
	end

	if not dataServiceRef then
		warn("[MonetizationService] DataService reference missing during ProcessReceipt.")
		return PurchaseDecision.NotProcessedYet
	end

	-- 2. Verify player data is loaded and safe to save (prevent overwriting / race conditions)
	local meta = dataServiceRef.GetMeta(player)
	if not meta or not meta.SafeToSave then
		warn(string.format("[MonetizationService] Player %d profile is not safe to save. Postponing receipt %s.", playerId, tostring(purchaseId)))
		return PurchaseDecision.NotProcessedYet
	end

	-- 3. Idempotency Check: Was this receipt already successfully processed?
	if dataServiceRef.HasReceipt(player, purchaseId) then
		-- Already recorded and granted. Return PurchaseGranted immediately to prevent duplicate grant.
		return PurchaseDecision.PurchaseGranted
	end

	-- 4. Identify product definition
	local product = MonetizationConfig.GetProduct(productId)
	if not product then
		warn(string.format("[MonetizationService] Unknown product ID %s in receipt %s.", tostring(productId), tostring(purchaseId)))
		logAnalytics(productId, currencySpent, false)
		return PurchaseDecision.NotProcessedYet
	end

	-- 5. Safe Reward Delivery
	local deliverySuccess = false
	if product.RewardType == "Braincoins" then
		dataServiceRef.AddBraincoins(player, product.RewardAmount)
		deliverySuccess = true
	elseif product.RewardType == "Effect" then
		if remotesRef and remotesRef:FindFirstChild("CourtroomCosmeticEffect") then
			remotesRef.CourtroomCosmeticEffect:FireAllClients("SpecialEffect", player.UserId, product.EffectId)
		end
		deliverySuccess = true
	elseif product.RewardType == "Cosmetic" then
		dataServiceRef.UnlockCosmetic(player, product.CosmeticId)
		deliverySuccess = true
	else
		warn(string.format("[MonetizationService] Unhandled RewardType '%s' for product %s.", tostring(product.RewardType), product.Name))
	end

	if not deliverySuccess then
		logAnalytics(productId, currencySpent, false)
		return PurchaseDecision.NotProcessedYet
	end

	-- 6. Record receipt into persistent player data
	dataServiceRef.RecordReceipt(player, purchaseId, {
		ProductId = productId,
		ProductKey = product.Key,
		CurrencySpent = currencySpent,
		Timestamp = os.time(),
	})

	-- 7. Persist to DataStore immediately to ensure receipt survives server crashes
	local saveSuccess, saveErr = dataServiceRef.Save(player)
	if not saveSuccess then
		warn(string.format("[MonetizationService] Failed to save DataStore for receipt %s: %s. Returning NotProcessedYet for retry.", tostring(purchaseId), tostring(saveErr)))
		logAnalytics(productId, currencySpent, false)
		return PurchaseDecision.NotProcessedYet
	end

	-- 8. Log analytics & send client notifications
	logAnalytics(productId, currencySpent, true)

	if remotesRef then
		local notifRemote = remotesRef:FindFirstChild("CourtroomNotification")
		if notifRemote then
			notifRemote:FireClient(player, "PURCHASE SUCCESSFUL: " .. product.Name .. "!")
		end
		local soundRemote = remotesRef:FindFirstChild("CourtroomCosmeticEffect")
		if soundRemote then
			soundRemote:FireClient(player, "Sound", "CashEarned")
		end
	end

	return PurchaseDecision.PurchaseGranted
end

-- ==================== GAME PASS VERIFICATION ====================

function MonetizationService.CheckGamePassOwnership(player, passKeyOrId)
	if not player or not dataServiceRef then return false end
	local passDef = MonetizationConfig.GetGamePass(passKeyOrId)
	if not passDef then return false end

	-- Check session cache first
	if dataServiceRef.OwnsGamePass(player, passDef.Key) then
		return true
	end

	-- If valid registered Game Pass ID exists (> 0), query Roblox API
	if passDef.Id and passDef.Id > 0 then
		local success, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passDef.Id)
		end)
		analytics.GamePassesChecked += 1
		if success and owns then
			dataServiceRef.SetGamePassOwned(player, passDef.Key, true)
			-- Unlock permanent cosmetics bundled with this Game Pass
			if passDef.GrantedCosmetics then
				for _, itemId in ipairs(passDef.GrantedCosmetics) do
					dataServiceRef.UnlockCosmetic(player, itemId)
				end
			end
			return true
		end
	end

	return false
end

function MonetizationService.CheckAllGamePasses(player)
	if not player then return end
	for key in pairs(MonetizationConfig.GamePasses) do
		MonetizationService.CheckGamePassOwnership(player, key)
	end
end

-- ==================== VIP SUBSCRIPTION ====================

function MonetizationService.VerifyVIPStatus(player)
	if not player or not dataServiceRef then return false end

	-- 1. Check if user owns VIP_JUDGE Game Pass (permanent VIP)
	if MonetizationService.CheckGamePassOwnership(player, "VIP_JUDGE") then
		return true
	end

	-- 2. Check active subscription status in profile
	if dataServiceRef.IsVIP(player) then
		return true
	end

	return false
end

function MonetizationService.GrantVIPSubscription(player, durationSeconds)
	if not player or not dataServiceRef then return false end
	durationSeconds = durationSeconds or MonetizationConfig.VIPSubscription.DurationSeconds
	local expiresAt = os.time() + durationSeconds
	dataServiceRef.SetVIPStatus(player, true, expiresAt)
	analytics.VIPCheckouts += 1

	-- Unlock VIP cosmetics
	for _, itemId in ipairs(MonetizationConfig.VIPSubscription.GrantedCosmetics) do
		dataServiceRef.UnlockCosmetic(player, itemId)
	end

	if remotesRef and remotesRef:FindFirstChild("CourtroomNotification") then
		remotesRef.CourtroomNotification:FireClient(player, "WELCOME TO THE VIP COURTROOM CLUB!")
	end
	return true
end

-- ==================== PRIVATE SERVERS ====================

function MonetizationService.IsPrivateServer()
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

function MonetizationService.GetPrivateServerOwnerId()
	return game.PrivateServerOwnerId or 0
end

-- ==================== ANALYTICS ====================

function MonetizationService.GetAnalyticsSummary()
	local summary = {
		TotalRobuxEarned = analytics.TotalRobuxEarned,
		TotalReceiptsProcessed = analytics.TotalReceiptsProcessed,
		PurchaseFailures = analytics.PurchaseFailures,
		GamePassesChecked = analytics.GamePassesChecked,
		VIPCheckouts = analytics.VIPCheckouts,
		PopularProducts = {},
	}
	for id, count in pairs(analytics.PurchasesByProduct) do
		table.insert(summary.PopularProducts, { ProductId = id, Count = count })
	end
	table.sort(summary.PopularProducts, function(a, b) return a.Count > b.Count end)
	return summary
end

-- ==================== SERVICE START ====================

function MonetizationService.Start(remotes, dataService)
	if isStarted then return end
	isStarted = true
	remotesRef = remotes
	dataServiceRef = dataService

	-- Hook server receipt processor into MarketplaceService
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return MonetizationService.ProcessReceipt(receiptInfo)
	end

	-- Check game passes when players join
	if Players and Players.PlayerAdded and Players.PlayerAdded.Connect then
		Players.PlayerAdded:Connect(function(player)
			task.spawn(function()
				task.wait(1)
				if player and player.Parent then
					MonetizationService.CheckAllGamePasses(player)
				end
			end)
		end)
	end

	if Players and Players.GetPlayers then
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				MonetizationService.CheckAllGamePasses(player)
			end)
		end
	end
end

return MonetizationService
