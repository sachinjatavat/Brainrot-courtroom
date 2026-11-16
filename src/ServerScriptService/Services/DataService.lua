local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataService = {}
local store = DataStoreService:GetDataStore("BrainrotCourtroom_v1")
local profiles = {}
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
	local data
	local success, result = pcall(function() return store:GetAsync("Player_" .. player.UserId) end)
	if success and type(result) == "table" then
		data = result
	else
		data = copy(DEFAULT)
		if not success then warn("[DataService] Load failed:", result) end
	end
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
end

function DataService.Save(player)
	local data = profiles[player]
	if not data then return false end
	local success, errorMessage = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function() return data end)
	end)
	if not success then warn("[DataService] Save failed:", errorMessage) end
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
