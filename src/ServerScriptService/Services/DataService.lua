local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataService = {}
local store = DataStoreService:GetDataStore("BrainrotCourtroom_v1")
local profiles = {}
local saving = {}
local DEFAULT = {
	Braincoins = 0, XP = 0, Level = 1, Wins = 0, TrialsPlayed = 0,
	Unlocked = { "DefaultJudge", "DefaultLawyer" },
	Equipped = { Judge = "DefaultJudge", Lawyer = "DefaultLawyer" },
	LastDaily = 0,
}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

function DataService.Load(player)
	if not player or not player.Parent then return nil end
	local data
	local success, result = pcall(function() return store:GetAsync("Player_" .. player.UserId) end)
	if success and type(result) == "table" then
		data = copy(DEFAULT)
		for key, value in pairs(result) do data[key] = copy(value) end
		data.Unlocked = type(result.Unlocked) == "table" and copy(result.Unlocked) or copy(DEFAULT.Unlocked)
		data.Equipped = type(result.Equipped) == "table" and copy(result.Equipped) or copy(DEFAULT.Equipped)
	else
		data = copy(DEFAULT)
		if not success then warn("[DataService] Load failed:", result) end
	end
	if not player.Parent then return nil end
	profiles[player] = data
	return data
end

function DataService.Get(player)
	return profiles[player]
end

function DataService.AddCoins(player, amount)
	local data = profiles[player]
	if data then data.Braincoins = math.max(0, data.Braincoins + amount) end
end

function DataService.AddXP(player, amount)
	local data = profiles[player]
	if data then
		data.XP += amount
		data.Level = math.max(1, math.floor(data.XP / 250) + 1)
	end
end

function DataService.ClaimDaily(player)
	local data = profiles[player]
	if not data then return false end
	local today = math.floor(os.time() / 86400)
	if data.LastDaily == today then return false end
	data.LastDaily = today
	DataService.AddCoins(player, 150)
	DataService.AddXP(player, 50)
	return true
end

function DataService.Save(player)
	local data = profiles[player]
	if not data or saving[player] then return false end
	saving[player] = true
	local success, errorMessage = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function()
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
