local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
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
	Phase = "Lobby", TimeLeft = 0, Roles = {}, BotRoles = {}, Votes = {},
	Case = nil, Chaos = nil, Arguments = {}, ArgumentScores = { Prosecutor = 0, Defense = 0 },
	NPCs = {}, ActiveTheme = "Classic", Awards = {},
}
local remotes
local cooldowns = {}
local emoteCooldowns = {}
local roleHistory = {}
local activityTracker = { AbilitiesUsed = {}, LongestArg = { Player = nil, Length = 0 } }
local DataService
local monetizationServiceRef = nil
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
	if not remotes or not remotes.State then return end
	remotes.State:FireAllClients({
		Phase = state.Phase, TimeLeft = state.TimeLeft, Roles = state.Roles,
		BotRoles = state.BotRoles, Case = state.Case, Votes = state.Votes, Chaos = state.Chaos,
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
		CosmeticsService.Apply(player, role, DataService and DataService.Get(player))
	elseif player.Parent then
		player.CharacterAdded:Once(function(newCharacter)
			if (state.Roles[player.UserId] == role or role == "Spectator") and newCharacter.Parent then
				newCharacter:PivotTo(position)
				CosmeticsService.Apply(player, role, DataService and DataService.Get(player))
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

-- BUG 5 FIX: Real Bananas Rain with Touched Slip Physics
local function spawnBananas()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "ChaosBananas_" .. tostring(math.floor(os.clock() * 1000)), workspace
	local connections = {}
	for _ = 1, 24 do
		local banana = Instance.new("Part")
		banana.Name = "ChaosBanana"
		banana.Shape = Enum.PartType.Ball
		banana.Size = Vector3.new(1.6, 1.6, 1.6)
		banana.Color = Color3.fromRGB(255, 220, 40)
		banana.Material = Enum.Material.Neon
		banana.Position = Vector3.new(random:NextNumber(-35, 35), random:NextNumber(22, 34), random:NextNumber(-25, 25))
		banana.CanCollide = true
		banana.Parent = folder

		local touchedConn
		touchedConn = banana.Touched:Connect(function(hit)
			local char = hit and hit.Parent
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and not hum.PlatformStand then
				hum.PlatformStand = true
				if char.PrimaryPart then
					char.PrimaryPart:ApplyImpulse(Vector3.new(random:NextNumber(-350, 350), 80, random:NextNumber(-350, 350)))
				end
				if remotes and remotes.CosmeticEffect then
					remotes.CosmeticEffect:FireAllClients("Sound", "BananaSlip")
				end
				task.delay(1.2, function()
					if hum and hum.Parent then
						hum.PlatformStand = false
					end
				end)
				banana:Destroy()
			end
		end)
		table.insert(connections, touchedConn)
	end
	return function()
		for _, conn in ipairs(connections) do
			pcall(function() conn:Disconnect() end)
		end
		if folder.Parent then folder:Destroy() end
	end
end

-- BUG 5 FIX: Real Courtroom Flood with Rising Water and Buoyancy
local function spawnFloodWater()
	local water = Instance.new("Part")
	water.Name = "CourtroomFloodWater"
	water.Size = Vector3.new(120, 8, 100)
	water.Position = Vector3.new(0, -3, 0)
	water.Anchored = true
	water.CanCollide = false
	water.Color = Color3.fromRGB(20, 160, 255)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.45
	water.Parent = workspace

	-- Smooth rise to Y = 3.5
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(water, tweenInfo, { Position = Vector3.new(0, 3.5, 0) }):Play()

	local conn = water.Touched:Connect(function(hit)
		local char = hit and hit.Parent
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and char.PrimaryPart and char.PrimaryPart.Position.Y < 4.5 then
			char.PrimaryPart.AssemblyLinearVelocity = Vector3.new(
				char.PrimaryPart.AssemblyLinearVelocity.X,
				math.max(char.PrimaryPart.AssemblyLinearVelocity.Y, 14),
				char.PrimaryPart.AssemblyLinearVelocity.Z
			)
		end
	end)

	return function()
		if conn then pcall(function() conn:Disconnect() end) end
		if water.Parent then
			local lowerTween = TweenService:Create(water, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {
				Position = Vector3.new(0, -4, 0),
				Transparency = 1,
			})
			lowerTween:Play()
			task.delay(1.0, function() if water.Parent then water:Destroy() end end)
		end
	end
end

-- BUG 5 FIX: Real Brainrot Meme Orbs with Elastic Impulse Physics
local function spawnBrainrotInvasion()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotInvasion"
	folder.Parent = workspace
	local connections = {}
	for i = 1, 10 do
		local orb = Instance.new("Part")
		orb.Name = "MemeOrb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(3, 3, 3)
		orb.Color = Color3.fromHSV(i / 10, 0.9, 1)
		orb.Material = Enum.Material.Neon
		orb.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.05, 0.95, 1, 1)
		orb.Position = Vector3.new(random:NextNumber(-30, 30), 8, random:NextNumber(-20, 20))
		orb.AssemblyLinearVelocity = Vector3.new(random:NextNumber(-35, 35), 20, random:NextNumber(-35, 35))
		orb.CanCollide = true
		orb.Parent = folder

		local conn = orb.Touched:Connect(function(hit)
			local char = hit and hit.Parent
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				local dir = (root.Position - orb.Position).Unit
				root:ApplyImpulse(dir * 1200 + Vector3.new(0, 350, 0))
			end
		end)
		table.insert(connections, conn)
	end
	return function()
		for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
		if folder.Parent then folder:Destroy() end
	end
end

-- BUG 5 FIX: Real Explosion with Non-Lethal Shockwave and Flying Paperwork
local function spawnExplosion()
	local pos = Vector3.new(0, 15, 34)
	local exp = Instance.new("Explosion")
	exp.Position = pos
	exp.BlastPressure = 0
	exp.BlastRadius = 15
	exp.DestroyJointsRadius = 0
	exp.Parent = workspace

	local folder = Instance.new("Folder")
	folder.Name = "ExplosionPaperwork"
	folder.Parent = workspace
	for _ = 1, 16 do
		local paper = Instance.new("Part")
		paper.Size = Vector3.new(1.2, 0.05, 1.6)
		paper.Color = Color3.fromRGB(250, 248, 240)
		paper.Material = Enum.Material.SmoothPlastic
		paper.Position = pos + Vector3.new(random:NextNumber(-3, 3), random:NextNumber(0, 3), random:NextNumber(-3, 3))
		paper.AssemblyLinearVelocity = Vector3.new(random:NextNumber(-30, 30), random:NextNumber(20, 40), random:NextNumber(-30, 30))
		paper.AssemblyAngularVelocity = Vector3.new(random:NextNumber(-10, 10), random:NextNumber(-10, 10), random:NextNumber(-10, 10))
		paper.CanCollide = false
		paper.Parent = folder
	end
	if remotes and remotes.CosmeticEffect then
		remotes.CosmeticEffect:FireAllClients("Sound", "Explosion")
	end
	return function()
		if folder.Parent then folder:Destroy() end
	end
end

-- BUG 5 FIX: Real, Fully Functional Chaos Event Implementations with Cleanup & Disconnect Handling
local function applyChaos(name)
	if not CourtroomEvents.IsValid(name) then return end

	if name == "VOICE_LOSS" then
		state.Silenced = true
		if remotes and remotes.CosmeticEffect then
			remotes.CosmeticEffect:FireAllClients("Sound", "Static")
		end
		activeEffects[name] = {
			Cleanup = function()
				state.Silenced = false
				broadcast()
			end,
		}
	elseif name == "COURTROOM_FLOOD" then
		activeEffects[name] = { Cleanup = spawnFloodWater() }
	elseif name == "BANANA_FLOOD" then
		activeEffects[name] = { Cleanup = spawnBananas() }
	elseif name == "BRAINROT_INVASION" then
		activeEffects[name] = { Cleanup = spawnBrainrotInvasion() }
	elseif name == "GRAVITY_GLITCH" then
		local originalGravity = workspace.Gravity
		workspace.Gravity = 35
		activeEffects[name] = {
			Cleanup = function()
				workspace.Gravity = originalGravity
			end,
		}
	elseif name == "JUDGE_TINY" then
		local judge
		for userId, role in pairs(state.Roles) do
			if role == "Judge" then judge = Players:GetPlayerByUserId(userId) end
		end
		local character = judge and judge.Character
		local originalScale = character and character:GetScale()
		if character and originalScale then
			character:ScaleTo(originalScale * 0.4)
		end
		activeEffects[name] = {
			Cleanup = function()
				if character and character.Parent and originalScale then
					pcall(function() character:ScaleTo(originalScale) end)
				end
			end,
		}
	elseif name == "POSITION_SWAP" then
		local eligible = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character and p.Character.PrimaryPart then
				table.insert(eligible, p)
			end
		end
		if #eligible >= 2 then
			local idx1 = random:NextInteger(1, #eligible)
			local p1 = table.remove(eligible, idx1)
			local p2 = eligible[random:NextInteger(1, #eligible)]
			local c1, c2 = p1.Character, p2.Character
			local cf1, cf2 = c1:GetPivot(), c2:GetPivot()
			c1:PivotTo(cf2)
			c2:PivotTo(cf1)
			activeEffects[name] = {
				Cleanup = function()
					if c1 and c1.Parent and cf1 then pcall(function() c1:PivotTo(cf1) end) end
					if c2 and c2.Parent and cf2 then pcall(function() c2:PivotTo(cf2) end) end
				end,
			}
		else
			activeEffects[name] = { Cleanup = function() end }
		end
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
			activeEffects[name] = {
				Cleanup = function()
					if state.Roles[pId] and state.Roles[dId] then
						state.Roles[pId], state.Roles[dId] = "Prosecutor", "Defense"
						local pP2, dP2 = Players:GetPlayerByUserId(pId), Players:GetPlayerByUserId(dId)
						if pP2 then teleport(pP2, "Prosecutor") end
						if dP2 then teleport(dP2, "Defense") end
						broadcast()
					end
				end,
			}
		else
			activeEffects[name] = { Cleanup = function() end }
		end
	elseif name == "EVERYONE_DANCES" then
		local originalSpeeds = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				Animations.Play(p.Character, "DANCE", CourtroomEvents.Get(name).Duration)
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					originalSpeeds[p] = hum.WalkSpeed
					hum.WalkSpeed = 4
				end
			end
		end
		activeEffects[name] = {
			Cleanup = function()
				for p, speed in pairs(originalSpeeds) do
					if p and p.Character then
						local hum = p.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum.WalkSpeed = speed end
					end
				end
			end,
		}
	elseif name == "EVIDENCE_MIXUP" then
		local prevActive = state.ActiveEvidence
		if state.Case and state.Case.Evidence and #state.Case.Evidence >= 2 then
			local evList = state.Case.Evidence
			for i = #evList, 2, -1 do
				local j = random:NextInteger(1, i)
				evList[i], evList[j] = evList[j], evList[i]
			end
			state.ActiveEvidence = 1
			state.EvidenceInspection = EvidenceSystem.Inspect(state.Case, 1)
		end
		activeEffects[name] = {
			Cleanup = function()
				state.ActiveEvidence = prevActive or 1
				if state.Case and state.Case.Evidence[state.ActiveEvidence] then
					state.EvidenceInspection = EvidenceSystem.Inspect(state.Case, state.ActiveEvidence)
				end
			end,
		}
	elseif name == "COURTROOM_EXPLOSION" then
		activeEffects[name] = { Cleanup = spawnExplosion() }
	else
		activeEffects[name] = { Cleanup = function() end }
	end

	state.Chaos = name
	broadcast()
	if remotes and remotes.Notification then
		remotes.Notification:FireAllClients("⚡ CHAOS EVENT: " .. name:gsub("_", " ") .. " ⚡")
	end
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
	state.Roles, state.BotRoles, state.Votes, state.Case = {}, {}, {}, nil
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
			CosmeticsService.Apply(player, "Spectator", DataService and DataService.Get(player))
		end
	end

	broadcast()
end

local function eligiblePlayers()
	return Players:GetPlayers()
end

local function reward(player, coins, xp)
	if DataService then
		DataService.AddCoins(player, coins)
		DataService.AddXP(player, xp)
	end
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

-- BUG 4 FIX: Security guards created as functional humanoid models
local function createSecurityNPCs()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "CourtroomSecurity", workspace
	local roster = {}
	for index = 1, 2 do
		local npc = NPCSystem.CreateSecurity(index)
		local spawnPos = Vector3.new(-38 + (index * 16), 3.5, -28)
		local model = NPCSystem.CreateSecurityModel(index, spawnPos)
		model.Parent = folder
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

-- BUG 4 FIX: Humanoid Security Guard Escort to jail with disconnect fallback
local function triggerDramaticVerdict(verdict, defendantPlayer)
	if remotes and remotes.CosmeticEffect then
		remotes.CosmeticEffect:FireAllClients("Verdict", verdict, defendantPlayer and defendantPlayer.UserId)
	end

	if verdict == "GUILTY" then
		triggerSpectatorReaction("GASPS! GUILTY!")
		if defendantPlayer and defendantPlayer.Character then
			Animations.Play(defendantPlayer.Character, "CRY", 6)
		end

		local guardModels = {}
		for _, npc in ipairs(state.NPCs) do
			if npc.Instance and npc.Instance:IsA("Model") then
				table.insert(guardModels, npc.Instance)
			end
		end

		NPCSystem.EscortToJail(guardModels, defendantPlayer, Vector3.new(-48, 6, -42), function()
			if defendantPlayer and (state.Phase == "Verdict" or state.Phase == "Rewards") then
				teleport(defendantPlayer, "Jail")
			end
		end)
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

	-- BUG 2 FIX: RoleAssigner returns humanRoles and botRoles (all 4 essential roles guaranteed)
	local humanRoles, botRoles = RoleAssigner.Assign(players, random, roleHistory)
	state.Roles = humanRoles
	state.BotRoles = botRoles
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
			local profile = judgePlayer and DataService and DataService.Get(judgePlayer)
			if profile and profile.Equipped and profile.Equipped.Theme then
				local cleaned = profile.Equipped.Theme:gsub("theme_", "")
				judgeTheme = cleaned:sub(1, 1):upper() .. cleaned:sub(2)
			end
		end
	end
	state.ActiveTheme = judgeTheme
	MapBuilder.ApplyTheme(judgeTheme)

	-- Witness memory creation (structured topics)
	state.WitnessMemory = {}
	for index, witness in ipairs(state.Case.Witnesses) do
		state.WitnessMemory[index] = WitnessMemory.Create(witness, random)
	end

	state.Arguments, state.ArgumentScores, state.WitnessResponses = {}, { Prosecutor = 0, Defense = 0 }, {}
	local cleanupSecurity = createSecurityNPCs()
	local cleanupSpectators = spawnSpectatorNPCs()

	state.Votes = {}
	state.BotJuryCount = math.max(3, Config.TargetPlayers - #players)

	teleportAll()
	waitPhase("Briefing", Config.Round.BriefingSeconds)
	if #eligiblePlayers() < Config.MinPlayers then cleanupRound(); return end

	state.Phase, state.TimeLeft = "Trial", Config.Round.TrialSeconds
	broadcast()
	task.spawn(chaosLoop)

	-- Record trial participation
	for _, p in ipairs(players) do
		if DataService then
			DataService.RecordProgress(p, "PLAY_TRIALS", 1)
			DataService.RecordProgress(p, "FIRST_TRIAL", 1)
		end
	end

	-- BUG 2 FIX: Autonomous Bot Behaviors for missing essential roles
	if state.BotRoles.Prosecutor then
		task.delay(12, function()
			if state.Phase == "Trial" then
				local botP = NPCSystem.CreateBotLawyer("Prosecutor", random)
				local argText = botP.Arguments[random:NextInteger(1, #botP.Arguments)]
				state.ArgumentScores.Prosecutor += 2
				if remotes and remotes.Notification then
					remotes.Notification:FireAllClients(botP.Name .. " submits argument: " .. argText)
				end
				broadcast()
			end
		end)
	end
	if state.BotRoles.Defense then
		task.delay(18, function()
			if state.Phase == "Trial" then
				local botD = NPCSystem.CreateBotLawyer("Defense", random)
				local argText = botD.Arguments[random:NextInteger(1, #botD.Arguments)]
				state.ArgumentScores.Defense += 2
				if remotes and remotes.Notification then
					remotes.Notification:FireAllClients(botD.Name .. " objects: " .. argText)
				end
				broadcast()
			end
		end)
	end
	if state.BotRoles.Defendant then
		task.delay(6, function()
			if state.Phase == "Trial" then
				local botDef = NPCSystem.CreateBotDefendant(random)
				local stmt = botDef.Statements[random:NextInteger(1, #botDef.Statements)]
				if remotes and remotes.Notification then
					remotes.Notification:FireAllClients(botDef.Name .. " pleas: \"" .. stmt .. "\"")
				end
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
		if instance and DataService then
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

function RoundService.Start(remoteFolder, dataService, monetizationService)
	remotes = {
		State = remoteFolder:WaitForChild("CourtroomState"),
		Action = remoteFolder:WaitForChild("CourtroomAction"),
		Notification = remoteFolder:WaitForChild("CourtroomNotification"),
		PlayerData = remoteFolder:WaitForChild("CourtroomPlayerData"),
		CosmeticEffect = remoteFolder:WaitForChild("CourtroomCosmeticEffect"),
	}
	DataService = dataService
	monetizationServiceRef = monetizationService

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
			broadcast()
		end
	end)

	-- Client Action Listener
	remotes.Action.OnServerEvent:Connect(function(player, action, payload)
		if type(action) ~= "string" then return end

		if action == "BuyItem" and type(payload) == "string" then
			local success, item = DataService.BuyItem(player, payload)
			if success then
				remotes.Notification:FireClient(player, "PURCHASED: " .. item.Name .. " for " .. item.Price .. " Braincoins!")
				remotes.CosmeticEffect:FireClient(player, "Sound", "CashEarned")
			else
				remotes.Notification:FireClient(player, "PURCHASE FAILED: " .. tostring(item))
			end
		elseif action == "EquipItem" and type(payload) == "table" and payload.Category and payload.ItemId then
			local success, err = DataService.EquipItem(player, payload.Category, payload.ItemId)
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
			local validEmotes = {
				OBJECTION = true, GAVEL_SLAM = true, CRY = true, LAUGH = true, DANCE = true, FACEPALM = true,
				VIP_BOW = true, CHAMPAGNE = true, MIC_DROP = true,
			}
			if validEmotes[payload] and player.Character then
				local isPremium = (payload == "VIP_BOW" or payload == "CHAMPAGNE" or payload == "MIC_DROP")
				if isPremium and monetizationServiceRef then
					local ownsPass = monetizationServiceRef.CheckGamePassOwnership(player, "PREMIUM_EMOTES")
					local isVip = DataService.IsVIP(player)
					if not ownsPass and not isVip then
						remotes.Notification:FireClient(player, "This emote requires VIP Club or Premium Emotes Game Pass!")
						return
					end
				end
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
		elseif action == "CheckGamePasses" then
			if monetizationServiceRef then
				monetizationServiceRef.CheckAllGamePasses(player)
			end
		elseif action == "ClaimVIPBonus" then
			local success, res = DataService.ClaimMonthlyVIPBonus(player)
			if success then
				remotes.Notification:FireClient(player, "VIP MONTHLY BONUS: +2,500 BRAINCOINS!")
				remotes.CosmeticEffect:FireClient(player, "Sound", "CashEarned")
			else
				remotes.Notification:FireClient(player, "VIP Bonus: " .. tostring(res))
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
		-- BUG 3 FIX: Structured witness questioning on topics with consistent stories and logical contradiction detection
		elseif action == "QuestionWitness" and not state.Silenced and (state.Roles[player.UserId] == "Prosecutor" or state.Roles[player.UserId] == "Defense") and state.Phase == "Trial" then
			local witnessIndex = 1
			local requestedTopic = nil
			if type(payload) == "table" then
				witnessIndex = math.clamp(tonumber(payload.WitnessIndex) or 1, 1, #state.Case.Witnesses)
				requestedTopic = payload.Topic
			else
				witnessIndex = math.clamp(tonumber(payload) or 1, 1, #state.Case.Witnesses)
			end

			local witness = state.Case.Witnesses[witnessIndex]
			local memory = state.WitnessMemory[witnessIndex]
			if not requestedTopic and witness.TopicList then
				local tIdx = ((memory.QuestionCount) % #witness.TopicList) + 1
				requestedTopic = witness.TopicList[tIdx]
			end
			requestedTopic = requestedTopic or "LOCATION"

			local topicData = witness.Topics and witness.Topics[requestedTopic]
			local questionText = topicData and topicData.Question or ("Inquiry regarding " .. requestedTopic)
			local answerText = topicData and topicData.Statement or (witness.Lines and witness.Lines[1] or "No comment.")

			local activeEvObj = state.ActiveEvidence and state.Case.Evidence[state.ActiveEvidence]
			local record, contradiction, detail = WitnessMemory.Record(memory, requestedTopic, answerText, activeEvObj)

			table.insert(state.WitnessResponses, {
				Witness = witness.Name,
				Topic = requestedTopic,
				Question = questionText,
				Answer = answerText,
				Contradiction = contradiction,
				Detail = detail,
			})

			local side = state.Roles[player.UserId]
			if contradiction then
				state.ArgumentScores[side] = (state.ArgumentScores[side] or 0) + 3
				DataService.RecordProgress(player, "CONTRADICTION_HUNTER", 1)
				remotes.CosmeticEffect:FireAllClients("Sound", "Objection")
				triggerSpectatorReaction("CONTRADICTION!!")
				remotes.Notification:FireAllClients(witness.Name .. " was caught in a contradiction on " .. requestedTopic .. "! [CONTRADICTION DETECTED]")
			else
				remotes.Notification:FireAllClients(witness.Name .. " on " .. requestedTopic .. ": \"" .. answerText .. "\"")
			end
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
				spawnExplosion()
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

	-- Disconnect handling: promote or fallback to bot roles
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
		emoteCooldowns[player.UserId] = nil
		local role = state.Roles[player.UserId]
		state.Roles[player.UserId], state.Votes[player.UserId] = nil, nil

		if state.Phase == "Trial" or state.Phase == "Briefing" then
			if role == "Judge" then
				local promoted = false
				for uId, r in pairs(state.Roles) do
					if r == "Jury" then
						state.Roles[uId] = "Judge"
						local actingJudge = Players:GetPlayerByUserId(uId)
						if actingJudge then
							teleport(actingJudge, "Judge")
							remotes.Notification:FireAllClients(actingJudge.DisplayName .. " has been sworn in as Acting Judge!")
						end
						promoted = true
						break
					end
				end
				if not promoted then
					state.BotRoles.Judge = { Id = "BOT_JUDGE", Name = "Honorable Robo-Judge", Role = "Judge" }
					remotes.Notification:FireAllClients("Robo-Judge has taken over the judicial bench!")
				end
			elseif role == "Prosecutor" then
				state.BotRoles.Prosecutor = { Id = "BOT_PROSECUTOR", Name = "Prosecutor Glitch-Bot", Role = "Prosecutor" }
				remotes.Notification:FireAllClients("Prosecutor disconnected: Glitch-Bot has taken over the prosecution!")
			elseif role == "Defense" then
				state.BotRoles.Defense = { Id = "BOT_DEFENSE", Name = "Attorney Robo-Brain", Role = "Defense" }
				remotes.Notification:FireAllClients("Defense disconnected: Robo-Brain has assumed defense duties!")
			elseif role == "Defendant" then
				state.BotRoles.Defendant = { Id = "BOT_DEFENDANT", Name = "Suspect Skibidi", Role = "Defendant" }
				remotes.Notification:FireAllClients("Defendant disconnected: Suspect Skibidi is tried in absentia!")
			end
		end

		if state.Phase == "Voting" then broadcast() end
	end)

	task.spawn(function()
		while true do runRound() end
	end)
end

return RoundService
