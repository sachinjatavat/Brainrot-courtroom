local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")

local Config = require(SharedFolder:WaitForChild("Config"))
local CaseGenerator = require(SharedFolder:WaitForChild("CaseGenerator"))
local RoleAssigner = require(SharedFolder:WaitForChild("RoleAssigner"))
local Verdict = require(SharedFolder:WaitForChild("Verdict"))
local WitnessMemory = require(SharedFolder:WaitForChild("WitnessMemory"))
local ArgumentScoring = require(SharedFolder:WaitForChild("ArgumentScoring"))
local EvidenceSystem = require(SharedFolder:WaitForChild("EvidenceSystem"))
local CourtroomEvents = require(SharedFolder:WaitForChild("CourtroomEvents"))
local NPCSystem = require(SharedFolder:WaitForChild("NPCSystem"))
local Animations = require(SharedFolder:WaitForChild("Animations"))
local Themes = require(SharedFolder:WaitForChild("Themes"))
local CosmeticsCatalog = require(SharedFolder:WaitForChild("CosmeticsCatalog"))
local Progression = require(SharedFolder:WaitForChild("Progression"))

local CosmeticsService = require(ServerScriptService.Services.CosmeticsService)
local MapBuilder = require(ServerScriptService.Services.MapBuilder)

local RoundService = {}
local random = Random.new()
local state = {
	Phase = "Lobby", TimeLeft = 0, Roles = {}, Votes = {},
	Case = nil, Chaos = nil, Arguments = {}, ArgumentScores = { Prosecutor = 0, Defense = 0 },
	NPCs = {}, ActiveTheme = "Classic", Awards = {},
}
local remotes
local cooldowns = {}
local emoteCooldowns = {}
local roleHistory = {}
local activityTracker = { AbilitiesUsed = {}, LongestArg = { Player = nil, Length = 0 } }
local DataService
local activeEffects = {}

local VALID_ABILITIES = {
	THROW_BANANA = true, ORDER_SILENCE = true, SUMMON_SECURITY = true,
	FORCE_CONFESSION = true, REVERSE_VERDICT = true, COURTROOM_EXPLOSION = true,
}

local ROLE_POSITIONS = {
	Judge = CFrame.new(0, 15, 36),
	Prosecutor = CFrame.new(-34, 7, 12),
	Defense = CFrame.new(34, 7, 12),
	Defendant = CFrame.new(0, 7, -12),
	Witness = CFrame.new(0, 8, 5),
	Jury = CFrame.new(-44, 7, -22),
	Spectator = CFrame.new(0, 5, -45),
	Jail = CFrame.new(-48, 6, -42),
}

local function broadcast()
	remotes.State:FireAllClients({
		Phase = state.Phase, TimeLeft = state.TimeLeft, Roles = state.Roles,
		Case = state.Case, Votes = state.Votes, Chaos = state.Chaos,
		BotJuryCount = state.BotJuryCount, Silenced = state.Silenced,
		ConfessionRequired = state.ConfessionRequired, Confession = state.Confession,
		EvidenceInspection = state.EvidenceInspection, WitnessResponses = state.WitnessResponses,
		ArgumentScores = state.ArgumentScores, NPCs = state.NPCs,
		ActiveTheme = state.ActiveTheme, Awards = state.Awards,
	})
end

local function teleport(player, role)
	local position = ROLE_POSITIONS[role] or ROLE_POSITIONS.Spectator
	local character = player.Character
	if character then
		character:PivotTo(position)
		CosmeticsService.Apply(player, role, DataService.Get(player))
	elseif player.Parent then
		player.CharacterAdded:Once(function(newCharacter)
			if (state.Roles[player.UserId] == role or role == "Spectator") and newCharacter.Parent then
				newCharacter:PivotTo(position)
				CosmeticsService.Apply(player, role, DataService.Get(player))
			end
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
	for _ = 1, 24 do
		local banana = Instance.new("Part")
		banana.Name, banana.Shape, banana.Size = "ChaosBanana", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5)
		banana.Color, banana.Material = Color3.fromRGB(255, 215, 40), Enum.Material.Neon
		banana.Position = Vector3.new(random:NextNumber(-45, 45), random:NextNumber(22, 34), random:NextNumber(-30, 35))
		banana.CanCollide, banana.Parent = true, folder
	end
	return function() if folder.Parent then folder:Destroy() end end
end

local function spawnFloodWater()
	local water = Instance.new("Part")
	water.Name = "CourtroomFloodWater"
	water.Size = Vector3.new(130, 4, 110)
	water.Position = Vector3.new(0, 2, 0)
	water.Anchored = true
	water.CanCollide = false
	water.Color = Color3.fromRGB(0, 160, 255)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.4
	water.Parent = workspace
	return function() if water.Parent then water:Destroy() end end
end

local function spawnBrainrotInvasion()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotInvasion"
	folder.Parent = workspace
	for i = 1, 10 do
		local orb = Instance.new("Part")
		orb.Name = "MemeOrb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(3, 3, 3)
		orb.Color = Color3.fromHSV(i / 10, 0.9, 1)
		orb.Material = Enum.Material.Neon
		orb.Position = Vector3.new(random:NextNumber(-35, 35), 6, random:NextNumber(-20, 20))
		orb.Velocity = Vector3.new(random:NextNumber(-30, 30), 15, random:NextNumber(-30, 30))
		orb.CanCollide = true
		orb.Parent = folder
	end
	return function() if folder.Parent then folder:Destroy() end end
end

local function applyChaos(name)
	if not CourtroomEvents.IsValid(name) then return end
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
	elseif name == "EVIDENCE_MIXUP" then
		local previous = state.ActiveEvidence
		state.ActiveEvidence = random:NextInteger(1, #state.Case.Evidence)
		activeEffects[name] = { Cleanup = function() state.ActiveEvidence = previous end }
	elseif name == "COURTROOM_FLOOD" then
		activeEffects[name] = { Cleanup = spawnFloodWater() }
	elseif name == "BRAINROT_INVASION" then
		activeEffects[name] = { Cleanup = spawnBrainrotInvasion() }
	elseif name == "ROLE_SWAP" then
		local pId, dId
		for uId, role in pairs(state.Roles) do
			if role == "Prosecutor" then pId = uId end
			if role == "Defense" then dId = uId end
		end
		if pId and dId then
			state.Roles[pId], state.Roles[dId] = "Defense", "Prosecutor"
			local pP, dP = Players:GetPlayerByUserId(pId), Players:GetPlayerByUserId(dId)
			if pP then teleport(pP, "Defense") end
			if dP then teleport(dP, "Prosecutor") end
		end
		activeEffects[name] = { Cleanup = function()
			if pId and dId then
				state.Roles[pId], state.Roles[dId] = "Prosecutor", "Defense"
				local pP, dP = Players:GetPlayerByUserId(pId), Players:GetPlayerByUserId(dId)
				if pP then teleport(pP, "Prosecutor") end
				if dP then teleport(dP, "Defense") end
			end
		end }
	elseif name == "EVERYONE_DANCES" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then Animations.Play(p.Character, "DANCE", 6) end
		end
		activeEffects[name] = { Cleanup = function() end }
	else
		activeEffects[name] = { Cleanup = function() end }
	end

	state.Chaos = name
	broadcast()
	remotes.Notification:FireAllClients("⚡ CHAOS EVENT: " .. name:gsub("_", " ") .. " ⚡")
	task.delay(CourtroomEvents.Get(name).Duration, function() clearEffect(name) end)
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
	state.ActiveEvidence, state.EvidenceInspection, state.WitnessResponses, state.Chaos = nil, nil, {}, nil
	state.WitnessMemory, state.Arguments, state.ArgumentScores, state.NPCs = {}, {}, { Prosecutor = 0, Defense = 0 }, {}
	state.ConfessionRequired, state.Silenced, state.ReverseVerdict = false, false, false
	state.Awards = {}

	local securityFolder = workspace:FindFirstChild("CourtroomSecurity")
	if securityFolder then securityFolder:Destroy() end
	local confettiFolder = workspace:FindFirstChild("VictoryConfetti")
	if confettiFolder then confettiFolder:Destroy() end
	local spectatorFolder = workspace:FindFirstChild("CourtroomSpectatorNPCs")
	if spectatorFolder then spectatorFolder:Destroy() end

	-- Return players to lobby and restore spectator styling
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			char:PivotTo(CFrame.new(0, 5, 125))
			CosmeticsService.Clear(char)
			CosmeticsService.Apply(player, "Spectator", DataService.Get(player))
		end
	end

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
	local events = {
		"GRAVITY_GLITCH", "BANANA_FLOOD", "EVERYONE_DANCES",
		"JUDGE_TINY", "POSITION_SWAP", "VOICE_LOSS",
		"EVIDENCE_MIXUP", "COURTROOM_FLOOD", "ROLE_SWAP", "BRAINROT_INVASION",
	}
	applyChaos(events[random:NextInteger(1, #events)])
end

local function createSecurityNPCs()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "CourtroomSecurity", workspace
	local roster = {}
	for index = 1, 2 do
		local npc = NPCSystem.CreateSecurity(index)
		local model = Instance.new("Model")
		model.Name = npc.Name
		local root = Instance.new("Part")
		root.Name, root.Size, root.Anchored, root.Position = "HumanoidRootPart", Vector3.new(2, 4, 2), true, Vector3.new(-42 + index * 5, 3, -28)
		root.Color, root.Parent = Color3.fromRGB(45, 50, 70), model
		model.PrimaryPart, model.Parent = root, folder
		npc.Instance = model
		table.insert(roster, npc)
	end
	state.NPCs = roster
	return function() if folder.Parent then folder:Destroy() end end
end

local function spawnSpectatorNPCs()
	local folder = Instance.new("Folder")
	folder.Name = "CourtroomSpectatorNPCs"
	folder.Parent = workspace
	local specs = NPCSystem.CreateSpectators(6, random)
	for i, spec in ipairs(specs) do
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = Vector3.new(2, 3, 2)
		part.Anchored = true
		part.Position = Vector3.new(-20 + (i * 7), 4, -40)
		part.Color = Color3.fromHSV(i / 6, 0.6, 0.8)
		part.Parent = folder
	end
	return function() if folder.Parent then folder:Destroy() end end
end

local function triggerSpectatorReaction(reactionText)
	local folder = workspace:FindFirstChild("CourtroomSpectatorNPCs")
	if not folder then return end
	for _, part in ipairs(folder:GetChildren()) do
		local bg = Instance.new("BillboardGui")
		bg.Size = UDim2.fromScale(4, 1.5)
		bg.StudsOffset = Vector3.new(0, 2.5, 0)
		bg.Adornee = part
		bg.Parent = part
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextColor3 = Color3.fromRGB(255, 235, 100)
		lbl.TextScaled = true
		lbl.Text = reactionText
		lbl.Parent = bg
		task.delay(2.5, function() bg:Destroy() end)
	end
end

local function triggerDramaticVerdict(verdict, defendantPlayer)
	remotes.CosmeticEffect:FireAllClients("Verdict", verdict, defendantPlayer and defendantPlayer.UserId)

	if verdict == "GUILTY" then
		triggerSpectatorReaction("GASPS! GUILTY!")
		if defendantPlayer and defendantPlayer.Character then
			Animations.Play(defendantPlayer.Character, "CRY", 6)
			task.delay(3, function()
				if state.Phase == "Verdict" or state.Phase == "Rewards" then
					teleport(defendantPlayer, "Jail")
				end
			end)
		end
	else
		triggerSpectatorReaction("CHEERS! INNOCENT!")
		local confetti = Instance.new("Folder")
		confetti.Name = "VictoryConfetti"
		confetti.Parent = workspace
		for i = 1, 28 do
			local p = Instance.new("Part")
			p.Size = Vector3.new(0.6, 0.6, 0.1)
			p.Color = Color3.fromHSV(i / 28, 0.9, 1)
			p.Position = Vector3.new(random:NextNumber(-18, 18), 20, random:NextNumber(-18, 18))
			p.CanCollide = false
			p.Anchored = false
			p.Parent = confetti
		end
		for userId, role in pairs(state.Roles) do
			if role == "Defense" or role == "Defendant" then
				local p = Players:GetPlayerByUserId(userId)
				if p and p.Character then
					Animations.Play(p.Character, "DANCE", 6)
				end
			end
		end
	end
end

local function computeEndAwards(verdict)
	local awards = {}

	-- 1. Best Lawyer Award
	local bestSide = (state.ArgumentScores.Prosecutor >= state.ArgumentScores.Defense) and "Prosecutor" or "Defense"
	for uId, role in pairs(state.Roles) do
		if role == bestSide then
			local p = Players:GetPlayerByUserId(uId)
			if p then
				table.insert(awards, { Title = "🏆 BEST LAWYER", Winner = p.DisplayName, Bonus = Config.Rewards.BestLawyer })
				reward(p, Config.Rewards.BestLawyer, 30)
			end
		end
	end

	-- 2. Most Chaotic Player Award
	local mostChaoticId, maxAbilities = nil, 0
	for uId, count in pairs(activityTracker.AbilitiesUsed) do
		if count > maxAbilities then
			mostChaoticId, maxAbilities = uId, count
		end
	end
	if mostChaoticId then
		local p = Players:GetPlayerByUserId(mostChaoticId)
		if p then
			table.insert(awards, { Title = "⚡ MOST CHAOTIC", Winner = p.DisplayName, Bonus = Config.Rewards.MostChaotic })
			reward(p, Config.Rewards.MostChaotic, 25)
		end
	end

	-- 3. Longest Argument Award
	if activityTracker.LongestArg.Player then
		table.insert(awards, { Title = "📜 SILVER TONGUE", Winner = activityTracker.LongestArg.Player.DisplayName, Bonus = Config.Rewards.LongestArgument })
		reward(activityTracker.LongestArg.Player, Config.Rewards.LongestArgument, 20)
	end

	state.Awards = awards
end

local function runRound()
	local players = eligiblePlayers()
	if #players < Config.MinPlayers then
		waitPhase("Lobby", 3)
		return
	end

	-- Fair Role Assignment with history
	state.Roles = RoleAssigner.Assign(players, random, roleHistory)
	state.Case = CaseGenerator.Create(random)

	-- Update role history
	for uId, role in pairs(state.Roles) do
		roleHistory[uId] = roleHistory[uId] or { RoleCount = {} }
		roleHistory[uId].LastRole = role
		if role == "Judge" then
			roleHistory[uId].JudgeCount = (roleHistory[uId].JudgeCount or 0) + 1
		end
	end

	-- Activity tracker reset
	activityTracker = { AbilitiesUsed = {}, LongestArg = { Player = nil, Length = 0 } }

	-- Determine Judge's theme
	local judgeTheme = "Classic"
	for userId, role in pairs(state.Roles) do
		if role == "Judge" then
			local judgePlayer = Players:GetPlayerByUserId(userId)
			local profile = judgePlayer and DataService.Get(judgePlayer)
			if profile and profile.Equipped and profile.Equipped.Theme then
				local cleaned = profile.Equipped.Theme:gsub("theme_", "")
				judgeTheme = cleaned:sub(1, 1):upper() .. cleaned:sub(2)
			end
		end
	end
	state.ActiveTheme = judgeTheme
	MapBuilder.ApplyTheme(judgeTheme)

	-- Bot fill for small servers
	if #players < Config.TargetPlayers then
		local bot = NPCSystem.CreateBotWitness(1, random)
		table.insert(state.Case.Witnesses, bot)
	end

	-- Witness memory creation
	state.WitnessMemory = {}
	for index, witness in ipairs(state.Case.Witnesses) do
		state.WitnessMemory[index] = WitnessMemory.Create(witness, random)
	end

	state.Arguments, state.ArgumentScores, state.WitnessResponses = {}, { Prosecutor = 0, Defense = 0 }, {}
	local cleanupSecurity = createSecurityNPCs()
	local cleanupSpectators = spawnSpectatorNPCs()

	state.Votes = {}
	state.BotJuryCount = math.max(0, Config.TargetPlayers - #players)

	teleportAll()
	waitPhase("Briefing", Config.Round.BriefingSeconds)
	if #eligiblePlayers() < Config.MinPlayers then cleanupRound(); return end

	state.Phase, state.TimeLeft = "Trial", Config.Round.TrialSeconds
	broadcast()
	task.spawn(chaosLoop)

	-- Record trial participation
	for _, p in ipairs(players) do
		DataService.RecordProgress(p, "PLAY_TRIALS", 1)
		DataService.RecordProgress(p, "FIRST_TRIAL", 1)
	end

	-- If low player count, bot lawyer auto-submits an argument
	local hasProsecutor = false
	for _, r in pairs(state.Roles) do if r == "Prosecutor" then hasProsecutor = true end end
	if not hasProsecutor then
		task.delay(15, function()
			if state.Phase == "Trial" then
				local botP = NPCSystem.CreateBotLawyer("Prosecutor", random)
				local argText = botP.Arguments[random:NextInteger(1, #botP.Arguments)]
				state.ArgumentScores.Prosecutor += 2
				remotes.Notification:FireAllClients(botP.Name .. " submits argument: " .. argText)
				broadcast()
			end
		end)
	end

	for _ = Config.Round.TrialSeconds, 1, -1 do
		if #eligiblePlayers() < Config.MinPlayers then cleanupRound(); return end
		state.TimeLeft = state.TimeLeft - 1
		broadcast()
		task.wait(1)
	end

	waitPhase("Voting", Config.Round.VotingSeconds)

	-- Intelligent Bot Jury voting based on arguments and evidence
	local activeEvObj = state.ActiveEvidence and state.Case.Evidence[state.ActiveEvidence]
	for index = 1, state.BotJuryCount do
		state.Votes["BOT_JURY_" .. index] = NPCSystem.EvaluateBotVote(state.ArgumentScores, activeEvObj, random)
	end

	local verdict, guilty, notGuilty = Verdict.Calculate(state.Votes, true, state.ArgumentScores)
	if verdict == "TIE" then verdict = "NOT_GUILTY" end
	if state.ReverseVerdict then verdict = verdict == "GUILTY" and "NOT_GUILTY" or "GUILTY" end
	state.Votes.Result, state.Votes.Guilty, state.Votes.NotGuilty = verdict, guilty, notGuilty

	local defendantPlayer
	for userId, role in pairs(state.Roles) do
		if role == "Defendant" then defendantPlayer = Players:GetPlayerByUserId(userId) end
	end
	triggerDramaticVerdict(verdict, defendantPlayer)

	-- Compute end awards
	computeEndAwards(verdict)

	waitPhase("Verdict", Config.Round.VerdictSeconds)

	-- Distribute rewards
	for playerUserId, role in pairs(state.Roles) do
		local instance = Players:GetPlayerByUserId(playerUserId)
		if instance then
			reward(instance, Config.Rewards.Participation, 25)
			if verdict == "GUILTY" and role == "Prosecutor" then
				reward(instance, Config.Rewards.Conviction, 50)
				DataService.RecordProgress(instance, "WIN_VERDICT", 1)
				DataService.RecordProgress(instance, "WIN_5_TRIALS", 1)
			end
			if verdict == "NOT_GUILTY" and role == "Defense" then
				reward(instance, Config.Rewards.Defender, 50)
				DataService.RecordProgress(instance, "WIN_VERDICT", 1)
				DataService.RecordProgress(instance, "WIN_5_TRIALS", 1)
			end
			if role == "Defendant" and verdict == "NOT_GUILTY" then
				reward(instance, Config.Rewards.Winner, 50)
				DataService.RecordProgress(instance, "WIN_VERDICT", 1)
			end
			if role == "Judge" then
				DataService.RecordProgress(instance, "ORDER_KEEPER", 1)
			end
		end
	end

	waitPhase("Rewards", Config.Round.RewardsSeconds)
	cleanupSecurity()
	cleanupSpectators()
	cleanupRound()
end

local function canUseAbility(player, name)
	if not VALID_ABILITIES[name] or state.Roles[player.UserId] ~= "Judge" or state.Phase ~= "Trial" then return false end
	cooldowns[player.UserId] = cooldowns[player.UserId] or {}
	local now = os.clock()
	if (cooldowns[player.UserId][name] or 0) > now then return false end
	cooldowns[player.UserId][name] = now + 18
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
		PlayerData = remoteFolder:WaitForChild("CourtroomPlayerData"),
		CosmeticEffect = remoteFolder:WaitForChild("CourtroomCosmeticEffect"),
	}
	DataService = dataService

	DataService.SetSyncCallback(function(player, profile)
		if remotes.PlayerData and player.Parent then
			remotes.PlayerData:FireClient(player, profile)
		end
	end)

	-- Handle late joining
	Players.PlayerAdded:Connect(function(player)
		task.wait(1)
		if state.Phase ~= "Lobby" and not state.Roles[player.UserId] then
			state.Roles[player.UserId] = "Spectator"
			teleport(player, "Spectator")
			remotes.Notification:FireClient(player, "Welcome! You are spectating the active trial.")
			broadcast()
		end
	end)

	remotes.Action.OnServerEvent:Connect(function(player, action, payload)
		-- Shop & Inventory actions
		if action == "BuyItem" and type(payload) == "string" then
			local success, result = DataService.BuyItem(player, payload)
			if success then
				remotes.Notification:FireClient(player, "PURCHASED: " .. result.Name .. " for " .. result.Price .. " Braincoins!")
				remotes.CosmeticEffect:FireClient(player, "Sound", "CashEarned")
			else
				remotes.Notification:FireClient(player, "PURCHASE FAILED: " .. tostring(result))
			end
		elseif action == "EquipItem" and type(payload) == "table" and type(payload.Category) == "string" and type(payload.ItemId) == "string" then
			local success = DataService.EquipItem(player, payload.Category, payload.ItemId)
			if success then
				remotes.Notification:FireClient(player, "EQUIPPED: " .. payload.ItemId)
				remotes.CosmeticEffect:FireClient(player, "Sound", "EquipItem")
				local role = state.Roles[player.UserId] or "Spectator"
				CosmeticsService.Apply(player, role, DataService.Get(player))
			end
		elseif action == "ClaimDailyMission" and type(payload) == "string" then
			local success, m = DataService.ClaimDailyMission(player, payload)
			if success then
				remotes.Notification:FireClient(player, "MISSION CLAIMED: +" .. m.RewardCoins .. " Coins, +" .. m.RewardXP .. " XP!")
				remotes.CosmeticEffect:FireClient(player, "Sound", "CashEarned")
			end
		elseif action == "ClaimAchievement" and type(payload) == "string" then
			local success, a = DataService.ClaimAchievement(player, payload)
			if success then
				remotes.Notification:FireClient(player, "ACHIEVEMENT UNLOCKED: " .. a.Title .. "! (+" .. a.RewardCoins .. " Coins)")
				remotes.CosmeticEffect:FireClient(player, "Sound", "CashEarned")
			end
		elseif action == "PlayEmote" and type(payload) == "string" then
			local now = os.clock()
			if (emoteCooldowns[player.UserId] or 0) > now then return end
			emoteCooldowns[player.UserId] = now + 2.5
			local validEmotes = { OBJECTION = true, GAVEL_SLAM = true, CRY = true, LAUGH = true, DANCE = true, FACEPALM = true }
			if validEmotes[payload] and player.Character then
				Animations.Play(player.Character, payload, 2.5)
				remotes.CosmeticEffect:FireAllClients("Emote", player.UserId, payload)
				activityTracker.AbilitiesUsed[player.UserId] = (activityTracker.AbilitiesUsed[player.UserId] or 0) + 1
				if payload == "OBJECTION" then
					remotes.CosmeticEffect:FireAllClients("Sound", "Objection")
					triggerSpectatorReaction("OBJECTION?!")
				elseif payload == "GAVEL_SLAM" then
					remotes.CosmeticEffect:FireAllClients("Sound", "GavelSlam")
					triggerSpectatorReaction("ORDER!")
				end
			end
		elseif action == "SelectTheme" and state.Roles[player.UserId] == "Judge" and type(payload) == "string" then
			if Themes.Get(payload) then
				state.ActiveTheme = payload
				MapBuilder.ApplyTheme(payload)
				remotes.Notification:FireAllClients("The Judge selected courtroom theme: " .. payload)
				broadcast()
			end
		elseif action == "ClaimDaily" then
			if DataService.ClaimDaily(player) then
				remotes.Notification:FireClient(player, "DAILY REWARD: +150 BRAINCOINS")
				remotes.CosmeticEffect:FireClient(player, "Sound", "CashEarned")
			end
		elseif action == "Vote" and state.Phase == "Voting" and state.Roles[player.UserId] == "Jury" and not state.Votes[player.UserId] and (payload == "GUILTY" or payload == "NOT_GUILTY") then
			state.Votes[player.UserId] = payload
			DataService.RecordProgress(player, "CAST_VOTES", 1)
			broadcast()
		elseif action == "PresentEvidence" and (state.Roles[player.UserId] == "Prosecutor" or state.Roles[player.UserId] == "Defense") and state.Phase == "Trial" and validEvidence(payload) then
			state.ActiveEvidence = payload
			state.EvidenceInspection = EvidenceSystem.Present(state.Case, payload, player.DisplayName)
			DataService.RecordProgress(player, "PRESENT_EVIDENCE", 1)
			activityTracker.AbilitiesUsed[player.UserId] = (activityTracker.AbilitiesUsed[player.UserId] or 0) + 1
			remotes.Notification:FireAllClients(player.DisplayName .. " presents evidence: " .. state.Case.Evidence[payload].Name)
			if player.Character then Animations.Play(player.Character, "OBJECTION", 2) end
			triggerSpectatorReaction("Gasp! Evidence!")
			broadcast()
		elseif action == "InspectEvidence" and state.Phase == "Trial" and validEvidence(payload) then
			state.EvidenceInspection = EvidenceSystem.Inspect(state.Case, payload)
			remotes.Notification:FireClient(player, state.EvidenceInspection.Name .. ": " .. state.EvidenceInspection.Detail)
			broadcast()
		elseif action == "QuestionWitness" and not state.Silenced and (state.Roles[player.UserId] == "Prosecutor" or state.Roles[player.UserId] == "Defense") and state.Phase == "Trial" then
			local witnessIndex = math.clamp(tonumber(payload) or 1, 1, #state.Case.Witnesses)
			local witness = state.Case.Witnesses[witnessIndex]
			local memory = state.WitnessMemory[witnessIndex]
			local answer = witness.Lines[random:NextInteger(1, #witness.Lines)]
			local _, contradiction = WitnessMemory.Record(memory, "general testimony", answer, state.ActiveEvidence)
			table.insert(state.WitnessResponses, { Witness = witness.Name, Answer = answer, Contradiction = contradiction })
			if contradiction then
				DataService.RecordProgress(player, "CONTRADICTION_HUNTER", 1)
				remotes.CosmeticEffect:FireAllClients("Sound", "Objection")
				triggerSpectatorReaction("CONTRADICTION!!")
			end
			remotes.Notification:FireAllClients(witness.Name .. " answers: " .. answer .. (contradiction and " [CONTRADICTION DETECTED]" or ""))
			broadcast()
		elseif action == "WitnessReact" and state.Phase == "Trial" and validEvidence(payload) then
			local witness = state.Case.Witnesses[1]
			remotes.Notification:FireAllClients(EvidenceSystem.React(witness, EvidenceSystem.Inspect(state.Case, payload)))
		elseif action == "SubmitArgument" and not state.Silenced and (state.Roles[player.UserId] == "Prosecutor" or state.Roles[player.UserId] == "Defense") and state.Phase == "Trial" and type(payload) == "string" and #payload <= 180 then
			local side = state.Roles[player.UserId]
			local result = ArgumentScoring.Evaluate(payload, side, state.Case, state.WitnessMemory, state.ActiveEvidence)
			table.insert(state.Arguments, result)
			state.ArgumentScores[side] += result.Score
			DataService.RecordProgress(player, "SUBMIT_ARGUMENTS", 1)
			activityTracker.AbilitiesUsed[player.UserId] = (activityTracker.AbilitiesUsed[player.UserId] or 0) + 1

			if #payload > activityTracker.LongestArg.Length then
				activityTracker.LongestArg = { Player = player, Length = #payload }
			end

			if player.Character then Animations.Play(player.Character, "OBJECTION", 2.2) end
			remotes.Notification:FireAllClients(player.DisplayName .. " submits an argument (score " .. tostring(result.Score) .. ").")
			broadcast()
		elseif action == "Accuse" and state.Roles[player.UserId] == "Prosecutor" and state.Phase == "Trial" then
			if player.Character then Animations.Play(player.Character, "OBJECTION", 2.5) end
			triggerSpectatorReaction("SHOCKING ACCUSATION!")
			remotes.Notification:FireAllClients("The prosecutor points dramatically: ACCUSATION FILED!")
		elseif action == "DefendantStatement" and state.Roles[player.UserId] == "Defendant" and state.Phase == "Trial" then
			remotes.Notification:FireAllClients("The defendant gives a statement.")
		elseif action == "JudgePower" and canUseAbility(player, tostring(payload)) then
			local name = tostring(payload)
			DataService.RecordProgress(player, "JUDGE_POWERS", 1)
			activityTracker.AbilitiesUsed[player.UserId] = (activityTracker.AbilitiesUsed[player.UserId] or 0) + 1
			if player.Character then Animations.Play(player.Character, "GAVEL_SLAM", 2) end

			if name == "THROW_BANANA" then
				local cleanup = spawnBananas()
				task.delay(4, cleanup)
			elseif name == "ORDER_SILENCE" then
				state.Silenced = true
				triggerSpectatorReaction("Silence in court!")
				task.delay(6, function() state.Silenced = false; broadcast() end)
			elseif name == "SUMMON_SECURITY" then
				for userId, role in pairs(state.Roles) do
					if role == "Defendant" then
						local defendant = Players:GetPlayerByUserId(userId)
						if defendant then teleport(defendant, "Jail") end
					end
				end
				triggerSpectatorReaction("Security, detain them!")
				remotes.Notification:FireAllClients("Security escorts the defendant to jail!")
			elseif name == "FORCE_CONFESSION" then
				state.ConfessionRequired = true
				remotes.Notification:FireAllClients("The defendant must choose: confess or deny!")
			elseif name == "REVERSE_VERDICT" then
				state.ReverseVerdict = true
			elseif name == "COURTROOM_EXPLOSION" then
				remotes.CosmeticEffect:FireAllClients("Sound", "VerdictGuilty")
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Character then Animations.Play(p.Character, "CRY", 3) end
				end
				remotes.Notification:FireAllClients("💥 EXPLOSION IN THE COURTROOM! ORDER HAS VANISHED!")
			end
			remotes.Notification:FireAllClients("JUDGE POWER: " .. name:gsub("_", " "))
			broadcast()
		elseif action == "DefendantResponse" and state.Roles[player.UserId] == "Defendant" and state.Phase == "Trial" and state.ConfessionRequired and (payload == "CONFESS" or payload == "DENY") then
			state.Confession = payload
			if payload == "CONFESS" and player.Character then
				Animations.Play(player.Character, "CRY", 3)
				triggerSpectatorReaction("A FULL CONFESSION?!")
			end
			remotes.Notification:FireAllClients("The defendant chooses to " .. payload:lower() .. ".")
			broadcast()
		elseif action == "JudgeControl" and state.Roles[player.UserId] == "Judge" and state.Phase == "Trial" and (payload == "START_ARGUMENTS" or payload == "END_ARGUMENTS") then
			state.ArgumentOpen = payload == "START_ARGUMENTS"
			if player.Character then Animations.Play(player.Character, "GAVEL_SLAM", 2) end
			remotes.Notification:FireAllClients(payload == "START_ARGUMENTS" and "The judge opens arguments." or "The judge closes arguments.")
			broadcast()
		end
	end)

	-- Disconnect handling
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
		emoteCooldowns[player.UserId] = nil
		local role = state.Roles[player.UserId]
		state.Roles[player.UserId], state.Votes[player.UserId] = nil, nil

		-- If Judge disconnects during Trial, promote highest ranking available juror
		if role == "Judge" and state.Phase == "Trial" then
			for uId, r in pairs(state.Roles) do
				if r == "Jury" then
					state.Roles[uId] = "Judge"
					local actingJudge = Players:GetPlayerByUserId(uId)
					if actingJudge then
						teleport(actingJudge, "Judge")
						remotes.Notification:FireAllClients(actingJudge.DisplayName .. " has been sworn in as Acting Judge!")
					end
					break
				end
			end
		end

		if state.Phase == "Voting" then broadcast() end
	end)

	task.spawn(function()
		while true do runRound() end
	end)
end

return RoundService
