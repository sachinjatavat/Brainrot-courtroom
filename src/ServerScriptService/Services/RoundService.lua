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
local activeEffects = {}
local VALID_ABILITIES = {
	THROW_BANANA = true, ORDER_SILENCE = true, SUMMON_SECURITY = true,
	FORCE_CONFESSION = true, REVERSE_VERDICT = true,
}

local ROLE_POSITIONS = {
	Judge = CFrame.new(0, 12, 31), Prosecutor = CFrame.new(-32, 8, 14),
	Defense = CFrame.new(32, 8, 14), Defendant = CFrame.new(0, 8, 10),
	Witness = CFrame.new(0, 8, -5), Jury = CFrame.new(0, 6, -29), Jail = CFrame.new(-48, 5, -35),
}

local function broadcast()
	remotes.State:FireAllClients({
		Phase = state.Phase, TimeLeft = state.TimeLeft, Roles = state.Roles,
		Case = state.Case, Votes = state.Votes, Chaos = state.Chaos,
		BotJuryCount = state.BotJuryCount, Silenced = state.Silenced,
		ConfessionRequired = state.ConfessionRequired, Confession = state.Confession,
	})
end

local function teleport(player, role)
	local position = ROLE_POSITIONS[role]
	if not position then return end
	local character = player.Character
	if character then
		character:PivotTo(position)
	elseif player.Parent then
		player.CharacterAdded:Once(function(newCharacter)
			if state.Roles[player.UserId] == role and newCharacter.Parent then newCharacter:PivotTo(position) end
		end)
	end
end

local function teleportAll()
	for userId, role in pairs(state.Roles) do
		local player = Players:GetPlayerByUserId(userId)
		if player then teleport(player, role) end
	end
end

local function clearEffect(name)
	local effect = activeEffects[name]
	if not effect then return end
	if effect.Cleanup then pcall(effect.Cleanup) end
	activeEffects[name] = nil
	if state.Chaos == name then state.Chaos = nil; broadcast() end
end

local function spawnBananas()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "ActiveBananas_" .. tostring(math.floor(os.clock() * 1000)), workspace
	for _ = 1, 18 do
		local banana = Instance.new("Part")
		banana.Name, banana.Shape, banana.Size = "ChaosBanana", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5)
		banana.Color, banana.Material = Color3.fromRGB(255, 210, 40), Enum.Material.Neon
		banana.Position = Vector3.new(random:NextNumber(-45, 45), random:NextNumber(18, 30), random:NextNumber(-30, 35))
		banana.CanCollide, banana.Parent = true, folder
	end
	return function() if folder.Parent then folder:Destroy() end end
end

local function applyChaos(name)
	if name == "BANANA_FLOOD" then
		activeEffects[name] = { Cleanup = spawnBananas() }
	elseif name == "GRAVITY_GLITCH" then
		local originalGravity = workspace.Gravity
		workspace.Gravity = math.max(20, originalGravity * 0.35)
		activeEffects[name] = { Cleanup = function() workspace.Gravity = originalGravity end }
	elseif name == "JUDGE_TINY" then
		local judge
		for userId, role in pairs(state.Roles) do if role == "Judge" then judge = Players:GetPlayerByUserId(userId) end end
		local character = judge and judge.Character
		local originalScale = character and character:GetScale()
		if character and originalScale then character:ScaleTo(originalScale * 0.5) end
		activeEffects[name] = { Cleanup = function() if character and character.Parent and originalScale then character:ScaleTo(originalScale) end end }
	elseif name == "POSITION_SWAP" then
		local players = Players:GetPlayers()
		local first, second = players[1] and players[1].Character, players[2] and players[2].Character
		local firstCFrame, secondCFrame = first and first:GetPivot(), second and second:GetPivot()
		if firstCFrame and secondCFrame then first:PivotTo(secondCFrame); second:PivotTo(firstCFrame) end
		activeEffects[name] = { Cleanup = function() if first and first.Parent and secondCFrame then first:PivotTo(firstCFrame) end; if second and second.Parent and firstCFrame then second:PivotTo(secondCFrame) end end }
	else
		activeEffects[name] = { Cleanup = function() end }
	end
	state.Chaos = name
	broadcast()
	remotes.Notification:FireAllClients("CHAOS EVENT: " .. name:gsub("_", " "))
	task.delay(7, function() clearEffect(name) end)
end

local function waitPhase(phase, seconds)
	state.Phase, state.TimeLeft = phase, seconds
	for remaining = seconds, 0, -1 do
		state.TimeLeft = remaining
		broadcast()
		task.wait(1)
	end
end

local function cleanupRound()
	for name in pairs(activeEffects) do clearEffect(name) end
	state.Roles, state.Votes, state.Case = {}, {}, nil
	state.ActiveEvidence, state.Chaos, state.Silenced, state.ReverseVerdict = nil, nil, false, false
	state.ConfessionRequired = false
	broadcast()
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
	applyChaos(events[random:NextInteger(1, #events)])
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
	teleportAll()
	waitPhase("Briefing", Config.Round.BriefingSeconds)
	if #eligiblePlayers() < Config.MinPlayers then cleanupRound(); return end
	state.Phase, state.TimeLeft = "Trial", Config.Round.TrialSeconds
	broadcast()
	task.spawn(chaosLoop)
	for _ = Config.Round.TrialSeconds, 1, -1 do
		if #eligiblePlayers() < Config.MinPlayers then cleanupRound(); return end
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
	if state.ReverseVerdict then verdict = verdict == "GUILTY" and "NOT_GUILTY" or "GUILTY" end
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
	cleanupRound()
end

local function canUseAbility(player, name)
	if not VALID_ABILITIES[name] or state.Roles[player.UserId] ~= "Judge" or state.Phase ~= "Trial" then return false end
	cooldowns[player.UserId] = cooldowns[player.UserId] or {}
	local now = os.clock()
	if (cooldowns[player.UserId][name] or 0) > now then return false end
	cooldowns[player.UserId][name] = now + 20
	return true
end

local function validEvidence(payload)
	return type(payload) == "number" and state.Case and state.Case.Evidence[payload] ~= nil
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
		elseif action == "Vote" and state.Phase == "Voting" and state.Roles[player.UserId] == "Jury" and not state.Votes[player.UserId] and (payload == "GUILTY" or payload == "NOT_GUILTY") then
			state.Votes[player.UserId] = payload
			broadcast()
		elseif action == "PresentEvidence" and (state.Roles[player.UserId] == "Prosecutor" or state.Roles[player.UserId] == "Defense") and state.Phase == "Trial" and validEvidence(payload) then
			state.ActiveEvidence = payload
			remotes.Notification:FireAllClients(player.DisplayName .. " presents evidence: " .. state.Case.Evidence[payload].Name)
			broadcast()
		elseif action == "QuestionWitness" and not state.Silenced and (state.Roles[player.UserId] == "Prosecutor" or state.Roles[player.UserId] == "Defense") and state.Phase == "Trial" then
			local witness = state.Case.Witnesses[(tonumber(payload) or 1) % #state.Case.Witnesses + 1]
			remotes.Notification:FireAllClients(witness.Name .. " answers: " .. witness.Lines[random:NextInteger(1, #witness.Lines)])
		elseif action == "SubmitArgument" and not state.Silenced and (state.Roles[player.UserId] == "Prosecutor" or state.Roles[player.UserId] == "Defense") and state.Phase == "Trial" and type(payload) == "string" and #payload <= 180 then
			remotes.Notification:FireAllClients(player.DisplayName .. " submits an argument.")
		elseif action == "Accuse" and state.Roles[player.UserId] == "Prosecutor" and state.Phase == "Trial" then
			remotes.Notification:FireAllClients("The prosecutor accuses the defendant!")
		elseif action == "DefendantStatement" and state.Roles[player.UserId] == "Defendant" and state.Phase == "Trial" then
			remotes.Notification:FireAllClients("The defendant gives a statement.")
		elseif action == "JudgePower" and canUseAbility(player, tostring(payload)) then
			local name = tostring(payload)
			if name == "THROW_BANANA" then local cleanup = spawnBananas(); task.delay(3, cleanup)
			elseif name == "ORDER_SILENCE" then state.Silenced = true; task.delay(5, function() state.Silenced = false; broadcast() end)
			elseif name == "SUMMON_SECURITY" then
				for userId, role in pairs(state.Roles) do if role == "Defendant" then local defendant = Players:GetPlayerByUserId(userId); if defendant then teleport(defendant, "Jail") end end end
				remotes.Notification:FireAllClients("Security escorts the defendant to jail!")
			elseif name == "FORCE_CONFESSION" then state.ConfessionRequired = true; remotes.Notification:FireAllClients("The defendant must choose: confess or deny!")
			elseif name == "REVERSE_VERDICT" then state.ReverseVerdict = true end
			remotes.Notification:FireAllClients("JUDGE POWER: " .. name:gsub("_", " ")); broadcast()
		elseif action == "DefendantResponse" and state.Roles[player.UserId] == "Defendant" and state.Phase == "Trial" and state.ConfessionRequired and (payload == "CONFESS" or payload == "DENY") then
			state.Confession = payload
			remotes.Notification:FireAllClients("The defendant chooses to " .. payload:lower() .. ".")
			broadcast()
		elseif action == "JudgeControl" and state.Roles[player.UserId] == "Judge" and state.Phase == "Trial" and (payload == "START_ARGUMENTS" or payload == "END_ARGUMENTS") then
			state.ArgumentOpen = payload == "START_ARGUMENTS"
			remotes.Notification:FireAllClients(payload == "START_ARGUMENTS" and "The judge opens arguments." or "The judge closes arguments.")
			broadcast()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
		state.Roles[player.UserId], state.Votes[player.UserId] = nil, nil
		if state.Phase == "Voting" then broadcast() end
	end)
	task.spawn(function()
		while true do runRound() end
	end)
end

return RoundService
