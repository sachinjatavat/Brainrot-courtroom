local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local CosmeticsCatalog = require(SharedFolder:WaitForChild("CosmeticsCatalog"))
local Progression = require(SharedFolder:WaitForChild("Progression"))

local DataService = {}
local storeInstance = nil
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

local profiles = {}
local saving = {}
local syncCallback = nil

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

	-- Unlocked items
	local unlockedSet = {}
	if type(data.Unlocked) == "table" then
		for _, id in pairs(data.Unlocked) do
			if type(id) == "string" then unlockedSet[id] = true end
		end
	end
	for _, id in ipairs(DEFAULT.Unlocked) do
		unlockedSet[id] = true
	end
	clean.Unlocked = {}
	for id in pairs(unlockedSet) do
		table.insert(clean.Unlocked, id)
	end

	-- Equipped slots
	clean.Equipped = copy(DEFAULT.Equipped)
	if type(data.Equipped) == "table" then
		for category, id in pairs(data.Equipped) do
			if type(category) == "string" and type(id) == "string" then
				clean.Equipped[category] = id
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

function DataService.Load(player)
	if not player or not player.Parent then return nil end
	local data
	local ds = getStore()
	local success, result
	if ds then
		success, result = pcall(function() return ds:GetAsync("Player_" .. player.UserId) end)
	else
		success, result = false, "DataStore unavailable"
	end
	if success and type(result) == "table" then
		data = sanitizeData(result)
	else
		data = sanitizeData({})
		if not success and ds then warn("[DataService] Load failed:", result) end
	end
	if not player.Parent then return nil end
	profiles[player] = data
	notifySync(player)
	return data
end

function DataService.Get(player)
	return profiles[player]
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

function DataService.EquipItem(player, category, itemId)
	local data = profiles[player]
	if not data then return false, "No profile" end

	if itemId ~= "none" then
		local owned = false
		for _, id in ipairs(data.Unlocked) do
			if id == itemId then owned = true; break end
		end
		if not owned then return false, "Item not owned" end
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
		-- Unlock title cosmetic
		local alreadyHas = false
		for _, id in ipairs(data.Unlocked) do
			if id == "title_" .. ach.RewardTitle:lower():gsub("%s+", "_") then alreadyHas = true break end
		end
		if not alreadyHas then
			table.insert(data.Unlocked, "title_" .. ach.RewardTitle:lower():gsub("%s+", "_"))
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

function DataService.Save(player)
	local data = profiles[player]
	if not data or saving[player] then return false end
	local ds = getStore()
	if not ds then return false end
	saving[player] = true
	local success, errorMessage = pcall(function()
		ds:UpdateAsync("Player_" .. player.UserId, function()
			return copy(data)
		end)
	end)
	if not success then warn("[DataService] Save failed:", errorMessage) end
	saving[player] = nil
	return success
end

function DataService.Remove(player)
	DataService.Save(player)
	profiles[player] = nil
end

function DataService.Start()
	Players.PlayerAdded:Connect(function(player) DataService.Load(player) end)
	Players.PlayerRemoving:Connect(DataService.Remove)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(DataService.Load, player) end
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do DataService.Save(player) end
	end)
end

return DataService
