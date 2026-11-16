local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Config, CaseGenerator, RoleAssigner, Verdict = Shared.Config, Shared.CaseGenerator, Shared.RoleAssigner, Shared.Verdict

local RoundService = {}
local random = Random.new()
local state = { Phase = "Lobby", TimeLeft = 0, Roles = {}, Votes = {}, Case = nil, Chaos = nil }
local remotes
local cooldowns = {}
local DataService

local function broadcast()
	remotes.State:FireAllClients({
		Phase = state.Phase, TimeLeft = state.TimeLeft, Roles = state.Roles,
		Case = state.Case, Votes = state.Votes, Chaos = state.Chaos,
		BotJuryCount = state.BotJuryCount,
	})
end

local function waitPhase(phase, seconds)
	state.Phase, state.TimeLeft = phase, seconds
	for remaining = seconds, 0, -1 do
		state.TimeLeft = remaining
		broadcast()
		task.wait(1)
	end
end

local function eligiblePlayers()
	return Players:GetPlayers()
end

local function reward(player, coins, xp)
	DataService.AddCoins(player, coins)
	DataService.AddXP(player, xp)
end

local function chaosLoop()
	local delay = random:NextInteger(Config.Round.ChaosMinimumSeconds, Config.Round.ChaosMaximumSeconds)
	task.wait(delay)
	if state.Phase ~= "Trial" then return end
	local events = { "GRAVITY_GLITCH", "BANANA_FLOOD", "EVERYONE_DANCES", "JUDGE_TINY", "POSITION_SWAP", "VOICE_LOSS" }
	state.Chaos = events[random:NextInteger(1, #events)]
	remotes.Notification:FireAllClients("CHAOS EVENT: " .. state.Chaos:gsub("_", " "))
	broadcast()
	task.wait(7)
	state.Chaos = nil
	broadcast()
end

local function runRound()
	local players = eligiblePlayers()
	if #players < Config.MinPlayers then
		waitPhase("Lobby", 3)
		return
	end
	state.Roles = RoleAssigner.Assign(players, random)
	state.Case = CaseGenerator.Create(random)
	state.Votes = {}
	state.BotJuryCount = math.max(0, Config.TargetPlayers - #players)
	waitPhase("Briefing", Config.Round.BriefingSeconds)
	state.Phase, state.TimeLeft = "Trial", Config.Round.TrialSeconds
	broadcast()
	task.spawn(chaosLoop)
	for _ = Config.Round.TrialSeconds, 1, -1 do
		if #eligiblePlayers() < Config.MinPlayers then break end
		state.TimeLeft = state.TimeLeft - 1
		broadcast()
		task.wait(1)
	end
	waitPhase("Voting", Config.Round.VotingSeconds)
	for index = 1, state.BotJuryCount do
		state.Votes["BOT_JURY_" .. index] = random:NextNumber() > 0.45 and "GUILTY" or "NOT_GUILTY"
	end
	local verdict, guilty, notGuilty = Verdict.Calculate(state.Votes, true)
	if verdict == "TIE" then verdict = "NOT_GUILTY" end
	state.Votes.Result, state.Votes.Guilty, state.Votes.NotGuilty = verdict, guilty, notGuilty
	waitPhase("Verdict", Config.Round.VerdictSeconds)
	for player, role in pairs(state.Roles) do
		local instance = Players:GetPlayerByUserId(player)
		if instance then
			reward(instance, Config.Rewards.Participation, 25)
			if verdict == "GUILTY" and role == "Prosecutor" then reward(instance, Config.Rewards.Conviction, 50) end
			if verdict == "NOT_GUILTY" and role == "Defense" then reward(instance, Config.Rewards.Defender, 50) end
			if role == "Defendant" and verdict == "NOT_GUILTY" then reward(instance, Config.Rewards.Winner, 50) end
		end
	end
	waitPhase("Rewards", 8)
end

function RoundService.Start(remoteFolder, dataService)
	remotes = {
		State = remoteFolder:WaitForChild("CourtroomState"),
		Action = remoteFolder:WaitForChild("CourtroomAction"),
		Notification = remoteFolder:WaitForChild("CourtroomNotification"),
	}
	DataService = dataService
	remotes.Action.OnServerEvent:Connect(function(player, action, payload)
		if action == "ClaimDaily" then
			if DataService.ClaimDaily(player) then
				remotes.Notification:FireClient(player, "DAILY REWARD: +150 BRAINCOINS")
			end
		elseif action == "Vote" and state.Phase == "Voting" and state.Roles[player.UserId] == "Jury" and (payload == "GUILTY" or payload == "NOT_GUILTY") then
			state.Votes[player.UserId] = payload
			broadcast()
		elseif action == "JudgePower" and state.Roles[player.UserId] == "Judge" and state.Phase == "Trial" then
			local name = tostring(payload)
			local now = os.clock()
			if cooldowns[name] and cooldowns[name] > now then return end
			cooldowns[name] = now + 20
			remotes.Notification:FireAllClients("JUDGE POWER: " .. name:gsub("_", " "))
			if name == "FORCE_CONFESSION" then remotes.Notification:FireAllClients("The courtroom demands a suspicious confession!") end
		end
	end)
	task.spawn(function()
		while true do runRound() end
	end)
end

return RoundService
