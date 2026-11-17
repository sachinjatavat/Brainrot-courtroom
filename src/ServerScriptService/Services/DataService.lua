local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local CosmeticsCatalog = require(SharedFolder:WaitForChild("CosmeticsCatalog"))
local Progression = require(SharedFolder:WaitForChild("Progression"))

local DataService = {}
local storeInstance = nil
local isShuttingDown = false

local function getStore()
	if storeInstance then return storeInstance end
	local success, result = pcall(function()
		return DataStoreService:GetDataStore("BrainrotCourtroom_v1")
	end)
	if success then
		storeInstance = result
	else
		warn("[DataService] DataStore unavailable (offline/unpublished):", result)
	end
	return storeInstance
end

function DataService.SetStore(customStore)
	storeInstance = customStore
end

function DataService.IsShuttingDown()
	return isShuttingDown
end

-- Profiles in memory and their metadata
local profiles = {}
local profileMeta = {} -- [player] = { IsLoaded = bool, SafeToSave = bool, SessionLock = table, Retries = number }
local saving = {}
local syncCallback = nil

local VALID_CATEGORIES = {
	Gavel = true,
	Briefcase = true,
	Aura = true,
	Title = true,
	Theme = true,
}

local DEFAULT = {
	Braincoins = 150,
	XP = 0,
	Level = 1,
	Wins = 0,
	TrialsPlayed = 0,
	Unlocked = { "gavel_wood", "case_leather", "title_rookie", "theme_classic" },
	Equipped = {
		Gavel = "gavel_wood",
		Briefcase = "case_leather",
		Aura = "none",
		Title = "title_rookie",
		Theme = "theme_classic",
	},
	DailyMissions = {
		Day = 0,
		Progress = {},
		Claimed = {},
	},
	Achievements = {
		Progress = {},
		Claimed = {},
	},
	ProcessedRewards = {}, -- Idempotency set to prevent duplicate reward processing
	ProcessedReceipts = {}, -- [purchaseId] = details map to guarantee idempotent ProcessReceipt
	PurchaseHistory = {}, -- Array of persistent purchase logs
	VIPSubscription = {
		Active = false,
		Expiration = 0,
		LastMonthlyBonus = 0,
	},
	OwnedGamePasses = {}, -- [passKey] = true
	LastDaily = 0,
}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

local function sanitizeData(data)
	if type(data) ~= "table" then data = {} end
	local clean = copy(DEFAULT)

	clean.Braincoins = math.max(0, tonumber(data.Braincoins) or DEFAULT.Braincoins)
	clean.XP = math.max(0, tonumber(data.XP) or DEFAULT.XP)
	clean.Level = Progression.GetLevel(clean.XP)
	clean.Wins = math.max(0, tonumber(data.Wins) or 0)
	clean.TrialsPlayed = math.max(0, tonumber(data.TrialsPlayed) or 0)
	clean.LastDaily = tonumber(data.LastDaily) or 0

	-- Unlocked items validation
	local unlockedSet = {}
	if type(data.Unlocked) == "table" then
		for _, id in pairs(data.Unlocked) do
			if type(id) == "string" and CosmeticsCatalog.IsValid(id) then
				unlockedSet[id] = true
			end
		end
	end
	for _, id in ipairs(DEFAULT.Unlocked) do
		unlockedSet[id] = true
	end
	clean.Unlocked = {}
	for id in pairs(unlockedSet) do
		table.insert(clean.Unlocked, id)
	end

	-- Equipped slots validation (ensure category matching)
	clean.Equipped = copy(DEFAULT.Equipped)
	if type(data.Equipped) == "table" then
		for category, id in pairs(data.Equipped) do
			if VALID_CATEGORIES[category] and type(id) == "string" then
				if id == "none" then
					clean.Equipped[category] = "none"
				else
					local item = CosmeticsCatalog.Get(id)
					if item and item.Category == category and unlockedSet[id] then
						clean.Equipped[category] = id
					end
				end
			end
		end
	end

	-- Daily Missions
	local currentDay = math.floor(os.time() / 86400)
	clean.DailyMissions = { Day = currentDay, Progress = {}, Claimed = {} }
	if type(data.DailyMissions) == "table" and data.DailyMissions.Day == currentDay then
		if type(data.DailyMissions.Progress) == "table" then
			clean.DailyMissions.Progress = copy(data.DailyMissions.Progress)
		end
		if type(data.DailyMissions.Claimed) == "table" then
			clean.DailyMissions.Claimed = copy(data.DailyMissions.Claimed)
		end
	end

	-- Achievements
	clean.Achievements = { Progress = {}, Claimed = {} }
	if type(data.Achievements) == "table" then
		if type(data.Achievements.Progress) == "table" then
			clean.Achievements.Progress = copy(data.Achievements.Progress)
		end
		if type(data.Achievements.Claimed) == "table" then
			clean.Achievements.Claimed = copy(data.Achievements.Claimed)
		end
	end

	-- Processed Rewards
	clean.ProcessedRewards = {}
	if type(data.ProcessedRewards) == "table" then
		for token, val in pairs(data.ProcessedRewards) do
			if val == true then clean.ProcessedRewards[token] = true end
		end
	end

	-- Processed Receipts (MarketplaceService Idempotency)
	clean.ProcessedReceipts = {}
	if type(data.ProcessedReceipts) == "table" then
		for pId, entry in pairs(data.ProcessedReceipts) do
			clean.ProcessedReceipts[tostring(pId)] = entry
		end
	end

	-- Purchase History
	clean.PurchaseHistory = {}
	if type(data.PurchaseHistory) == "table" then
		for _, entry in ipairs(data.PurchaseHistory) do
			if type(entry) == "table" then
				table.insert(clean.PurchaseHistory, copy(entry))
			end
		end
	end

	-- VIP Subscription
	clean.VIPSubscription = { Active = false, Expiration = 0, LastMonthlyBonus = 0 }
	if type(data.VIPSubscription) == "table" then
		clean.VIPSubscription.Active = data.VIPSubscription.Active == true
		clean.VIPSubscription.Expiration = tonumber(data.VIPSubscription.Expiration) or 0
		clean.VIPSubscription.LastMonthlyBonus = tonumber(data.VIPSubscription.LastMonthlyBonus) or 0
	end

	-- Owned GamePasses
	clean.OwnedGamePasses = {}
	if type(data.OwnedGamePasses) == "table" then
		for passKey, owned in pairs(data.OwnedGamePasses) do
			if owned == true then
				clean.OwnedGamePasses[tostring(passKey)] = true
			end
		end
	end

	return clean
end

function DataService.SetSyncCallback(cb)
	syncCallback = cb
end

local function notifySync(player)
	if syncCallback and player and profiles[player] then
		syncCallback(player, copy(profiles[player]))
	end
end

-- Helper: Exponential backoff retry
local function retryWithBackoff(fn, maxRetries, baseDelay)
	maxRetries = maxRetries or 3
	baseDelay = baseDelay or 0.5
	local lastErr
	for attempt = 1, maxRetries do
		local success, result = pcall(fn)
		if success then
			return true, result
		end
		lastErr = result
		if attempt < maxRetries then
			task.wait(baseDelay * (2 ^ (attempt - 1)))
		end
	end
	return false, lastErr
end

function DataService.Load(player)
	if not player or not player.Parent then return nil end

	local meta = {
		IsLoaded = false,
		SafeToSave = false,
		SessionLock = nil,
		Retries = 0,
	}
	profileMeta[player] = meta

	local ds = getStore()
	local data = nil

	if not ds then
		-- Offline / Mock mode (e.g. unpublished Studio or offline testing)
		data = sanitizeData({})
		meta.IsLoaded = true
		meta.SafeToSave = true
		profiles[player] = data
		notifySync(player)
		return data
	end

	-- Online mode with retry and session locking
	local lockAcquired = false
	local loadSuccess, loadResult = retryWithBackoff(function()
		return ds:UpdateAsync("Player_" .. player.UserId, function(existing)
			local now = os.time()
			if existing and type(existing) == "table" and existing._SessionLock then
				local lock = existing._SessionLock
				-- Check if locked by another server (lease duration: 15 minutes = 900s)
				if lock.JobId and lock.JobId ~= game.JobId and (now - (lock.Time or 0)) < 900 then
					return nil -- Signal active lock conflict
				end
			end

			-- Safe to acquire lock
			local profileData = existing or sanitizeData({})
			profileData._SessionLock = {
				JobId = game.JobId,
				Time = now,
			}
			lockAcquired = true
			return profileData
		end)
	end, 3, 1)

	if loadSuccess and lockAcquired and type(loadResult) == "table" then
		data = sanitizeData(loadResult)
		meta.IsLoaded = true
		meta.SafeToSave = true
		meta.SessionLock = loadResult._SessionLock
	elseif loadSuccess and not lockAcquired then
		-- Profile is actively locked by another server
		warn("[DataService] Player " .. player.UserId .. " profile is locked by another server session.")
		meta.IsLoaded = false
		meta.SafeToSave = false -- NEVER overwrite!
		if player.Parent then
			player:Kick("Your profile is currently open in another session. Please wait a minute and rejoin.")
		end
		return nil
	else
		-- Network / DataStore failure: DO NOT OVERWRITE!
		warn("[DataService] Load failed for Player " .. player.UserId .. " after retries:", loadResult)
		meta.IsLoaded = false
		meta.SafeToSave = false -- NEVER save a failed load to prevent data wiping!
		data = sanitizeData({}) -- Guest fallback
	end

	if not player.Parent then return nil end
	profiles[player] = data
	notifySync(player)
	return data
end

function DataService.Get(player)
	return profiles[player]
end

function DataService.GetMeta(player)
	return profileMeta[player]
end

function DataService.AddCoins(player, amount)
	local data = profiles[player]
	if data and amount then
		data.Braincoins = math.max(0, data.Braincoins + amount)
		notifySync(player)
	end
end

function DataService.AddXP(player, amount)
	local data = profiles[player]
	if data and amount then
		data.XP += amount
		data.Level = Progression.GetLevel(data.XP)
		notifySync(player)
	end
end

function DataService.BuyItem(player, itemId)
	local data = profiles[player]
	if not data then return false, "No profile" end
	local item = CosmeticsCatalog.Get(itemId)
	if not item then return false, "Invalid item" end

	-- Check if already unlocked
	for _, id in ipairs(data.Unlocked) do
		if id == itemId then return false, "Already owned" end
	end

	if item.VIPOnly and not DataService.IsVIP(player) then
		return false, "Item is exclusive to VIP members"
	end

	if data.Braincoins < item.Price then
		return false, "Insufficient Braincoins"
	end

	data.Braincoins -= item.Price
	table.insert(data.Unlocked, itemId)

	-- Check achievement DRIP_CHECK (unlock 3 cosmetics)
	DataService.RecordProgress(player, "DRIP_CHECK", 1)

	notifySync(player)
	return true, item
end

-- BUG 6 FIX: Strict category, existence, and ownership validation
function DataService.EquipItem(player, category, itemId)
	local data = profiles[player]
	if not data then return false, "No profile" end

	-- 1. Validate Category
	if not VALID_CATEGORIES[category] then
		return false, "Invalid category: " .. tostring(category)
	end

	-- 2. Handle Unequip ("none")
	if itemId == "none" then
		data.Equipped[category] = "none"
		notifySync(player)
		return true
	end

	-- 3. Validate Item Existence
	local item = CosmeticsCatalog.Get(itemId)
	if not item then
		return false, "Item does not exist: " .. tostring(itemId)
	end

	-- 4. Validate Category Match
	if item.Category ~= category then
		return false, string.format("Category mismatch: item %s is %s, not %s", itemId, item.Category, category)
	end

	-- 5. Validate Ownership
	local owned = false
	for _, id in ipairs(data.Unlocked) do
		if id == itemId then owned = true break end
	end
	if not owned then
		return false, "Unauthorized item: not owned by player"
	end

	data.Equipped[category] = itemId
	notifySync(player)
	return true
end

function DataService.RecordProgress(player, metric, amount)
	local data = profiles[player]
	if not data then return end
	amount = amount or 1

	-- Update daily mission progress if metric matches
	local currentDay = math.floor(os.time() / 86400)
	if data.DailyMissions.Day ~= currentDay then
		data.DailyMissions = { Day = currentDay, Progress = {}, Claimed = {} }
	end

	local missions = Progression.GetMissionsForDay(currentDay)
	for _, m in ipairs(missions) do
		if m.Id == metric then
			data.DailyMissions.Progress[metric] = (data.DailyMissions.Progress[metric] or 0) + amount
		end
	end

	-- Update achievement progress
	local ach = Progression.GetAchievement(metric)
	if ach then
		data.Achievements.Progress[metric] = (data.Achievements.Progress[metric] or 0) + amount
	end

	notifySync(player)
end

function DataService.ClaimDailyMission(player, missionId)
	local data = profiles[player]
	if not data then return false, "No profile" end
	local mission = Progression.GetMission(missionId)
	if not mission then return false, "Invalid mission" end

	if data.DailyMissions.Claimed[missionId] then
		return false, "Already claimed"
	end

	local progress = data.DailyMissions.Progress[missionId] or 0
	if progress < mission.Target then
		return false, "Target not reached"
	end

	data.DailyMissions.Claimed[missionId] = true
	DataService.AddCoins(player, mission.RewardCoins)
	DataService.AddXP(player, mission.RewardXP)
	notifySync(player)
	return true, mission
end

function DataService.ClaimAchievement(player, achId)
	local data = profiles[player]
	if not data then return false, "No profile" end
	local ach = Progression.GetAchievement(achId)
	if not ach then return false, "Invalid achievement" end

	if data.Achievements.Claimed[achId] then
		return false, "Already claimed"
	end

	local progress = data.Achievements.Progress[achId] or 0
	if progress < ach.Target then
		return false, "Target not reached"
	end

	data.Achievements.Claimed[achId] = true
	DataService.AddCoins(player, ach.RewardCoins)
	DataService.AddXP(player, ach.RewardXP)

	if ach.RewardTitle then
		local titleId = "title_" .. ach.RewardTitle:lower():gsub("%s+", "_")
		local alreadyHas = false
		for _, id in ipairs(data.Unlocked) do
			if id == titleId then alreadyHas = true break end
		end
		if not alreadyHas and CosmeticsCatalog.IsValid(titleId) then
			table.insert(data.Unlocked, titleId)
		end
	end

	notifySync(player)
	return true, ach
end

function DataService.ClaimDaily(player)
	local data = profiles[player]
	if not data then return false end
	local today = math.floor(os.time() / 86400)
	if data.LastDaily == today then return false end
	data.LastDaily = today
	DataService.AddCoins(player, 150)
	DataService.AddXP(player, 50)
	notifySync(player)
	return true
end

-- BUG 1 FIX: Duplicate reward prevention via idempotency token
function DataService.ProcessReward(player, rewardToken, coins, xp)
	local data = profiles[player]
	if not data then return false, "No profile" end
	if not rewardToken or type(rewardToken) ~= "string" then return false, "Invalid token" end

	if data.ProcessedRewards[rewardToken] then
		return false, "Duplicate reward prevented: already processed"
	end

	data.ProcessedRewards[rewardToken] = true
	if coins and coins > 0 then DataService.AddCoins(player, coins) end
	if xp and xp > 0 then DataService.AddXP(player, xp) end
	return true
end

-- ==================== PHASE 18: MONETIZATION & RECEIPT PROCESSING ====================

function DataService.AddBraincoins(player, amount)
	DataService.AddCoins(player, amount)
end

function DataService.UnlockCosmetic(player, itemId)
	local data = profiles[player]
	if not data then return false, "No profile" end
	if not CosmeticsCatalog.IsValid(itemId) then return false, "Invalid item" end
	for _, id in ipairs(data.Unlocked) do
		if id == itemId then return true, "Already unlocked" end
	end
	table.insert(data.Unlocked, itemId)
	notifySync(player)
	return true, "Unlocked"
end

function DataService.HasReceipt(player, purchaseId)
	local data = profiles[player]
	if not data then return false end
	return data.ProcessedReceipts[tostring(purchaseId)] ~= nil
end

function DataService.RecordReceipt(player, purchaseId, details)
	local data = profiles[player]
	if not data then return false end
	local key = tostring(purchaseId)
	local record = details or { Timestamp = os.time() }
	data.ProcessedReceipts[key] = record
	table.insert(data.PurchaseHistory, {
		PurchaseId = key,
		ProductId = record.ProductId,
		CurrencySpent = record.CurrencySpent,
		Timestamp = record.Timestamp or os.time(),
	})
	notifySync(player)
	return true
end

function DataService.GetPurchaseHistory(player)
	local data = profiles[player]
	if not data then return {} end
	return copy(data.PurchaseHistory)
end

function DataService.SetVIPStatus(player, active, expirationTimestamp)
	local data = profiles[player]
	if not data then return end
	data.VIPSubscription.Active = (active == true)
	data.VIPSubscription.Expiration = tonumber(expirationTimestamp) or 0
	if active then
		DataService.UnlockCosmetic(player, "title_vip")
		DataService.UnlockCosmetic(player, "aura_vip")
		DataService.UnlockCosmetic(player, "gavel_vip")
	end
	notifySync(player)
end

function DataService.IsVIP(player)
	local data = profiles[player]
	if not data then return false end
	if data.OwnedGamePasses and data.OwnedGamePasses["VIP_JUDGE"] == true then
		return true
	end
	if data.VIPSubscription and data.VIPSubscription.Active == true then
		if data.VIPSubscription.Expiration == 0 or os.time() <= data.VIPSubscription.Expiration then
			return true
		else
			-- Expired! Server-side enforcement revokes active status
			data.VIPSubscription.Active = false
			notifySync(player)
			return false
		end
	end
	return false
end

function DataService.SetGamePassOwned(player, passKey, owned)
	local data = profiles[player]
	if not data then return end
	data.OwnedGamePasses[passKey] = (owned == true)
	notifySync(player)
end

function DataService.OwnsGamePass(player, passKey)
	local data = profiles[player]
	if not data then return false end
	return data.OwnedGamePasses and data.OwnedGamePasses[passKey] == true
end

function DataService.ClaimMonthlyVIPBonus(player)
	local data = profiles[player]
	if not data then return false, "No profile" end
	if not DataService.IsVIP(player) then return false, "Not VIP" end
	local now = os.time()
	local lastBonus = data.VIPSubscription.LastMonthlyBonus or 0
	if now - lastBonus < (30 * 24 * 3600) then
		return false, "Monthly bonus already claimed for this period"
	end
	data.VIPSubscription.LastMonthlyBonus = now
	DataService.AddBraincoins(player, 2500)
	notifySync(player)
	return true, 2500
end

-- BUG 1 & PHASE 16 FIX: Save safety check, retry backoff, ownership verification, and explicit session lock release
function DataService.Save(player, forceReleaseLock)
	local data = profiles[player]
	local meta = profileMeta[player]

	if not data or saving[player] then return false, "Busy or no data" end

	-- CRITICAL: Abort if profile was not safely loaded! (Prevents data loss)
	if not meta or not meta.SafeToSave then
		warn("[DataService] Save aborted for Player " .. tostring(player and player.UserId) .. ": profile was not safely loaded (preventing data wiping).")
		return false, "Unsafe to save"
	end

	local ds = getStore()
	if not ds then return true end -- Mock mode passes

	saving[player] = true
	local releaseLock = (forceReleaseLock == true) or isShuttingDown or (player.Parent == nil)

	local success, err = retryWithBackoff(function()
		return ds:UpdateAsync("Player_" .. player.UserId, function(current)
			-- Verify session lock ownership before writing
			if current and type(current) == "table" and current._SessionLock then
				local lock = current._SessionLock
				if lock.JobId and lock.JobId ~= game.JobId then
					local now = os.time()
					if (now - (lock.Time or 0)) < 900 then
						error("Session lock conflict: another server (" .. tostring(lock.JobId) .. ") holds the active lock")
					end
				end
			end

			local toSave = copy(data)
			-- Explicitly release session lock when player leaves, during shutdown, or on force release
			if releaseLock then
				toSave._SessionLock = nil
			else
				toSave._SessionLock = {
					JobId = game.JobId,
					Time = os.time(),
				}
			end
			return toSave
		end)
	end, 3, 1)

	saving[player] = nil
	if not success then
		warn("[DataService] Save failed for Player " .. player.UserId .. ":", err)
	end
	return success
end

function DataService.Remove(player)
	DataService.Save(player, true) -- Explicitly release session lock on exit
	profiles[player] = nil
	profileMeta[player] = nil
end

function DataService.Start()
	Players.PlayerAdded:Connect(function(player) DataService.Load(player) end)
	Players.PlayerRemoving:Connect(DataService.Remove)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(DataService.Load, player) end

	-- PHASE 16 FIX: Safe shutdown handling with explicit session lock release
	game:BindToClose(function()
		isShuttingDown = true
		local activePlayers = Players:GetPlayers()
		if #activePlayers == 0 then return end

		local completed = 0
		for _, player in ipairs(activePlayers) do
			task.spawn(function()
				DataService.Save(player, true) -- Explicitly release session lock
				completed += 1
			end)
		end

		local startTime = os.clock()
		while completed < #activePlayers and (os.clock() - startTime) < 25 do
			task.wait(0.2)
		end
	end)
end

return DataService
