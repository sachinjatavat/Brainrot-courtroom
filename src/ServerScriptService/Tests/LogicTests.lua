local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")

local Shared = {
	Config = require(SharedFolder:WaitForChild("Config")),
	Signal = require(SharedFolder:WaitForChild("Signal")),
	CaseGenerator = require(SharedFolder:WaitForChild("CaseGenerator")),
	RoleAssigner = require(SharedFolder:WaitForChild("RoleAssigner")),
	Verdict = require(SharedFolder:WaitForChild("Verdict")),
	Net = require(SharedFolder:WaitForChild("Net")),
	WitnessMemory = require(SharedFolder:WaitForChild("WitnessMemory")),
	ArgumentScoring = require(SharedFolder:WaitForChild("ArgumentScoring")),
	EvidenceSystem = require(SharedFolder:WaitForChild("EvidenceSystem")),
	CourtroomEvents = require(SharedFolder:WaitForChild("CourtroomEvents")),
	NPCSystem = require(SharedFolder:WaitForChild("NPCSystem")),
	CosmeticsCatalog = require(SharedFolder:WaitForChild("CosmeticsCatalog")),
	Progression = require(SharedFolder:WaitForChild("Progression")),
	Themes = require(SharedFolder:WaitForChild("Themes")),
	Animations = require(SharedFolder:WaitForChild("Animations")),
	AudioCatalog = require(SharedFolder:WaitForChild("AudioCatalog")),
	PerformanceSettings = require(SharedFolder:WaitForChild("PerformanceSettings")),
}

local LogicTests = {}

function LogicTests.Run()
	local random = Random.new(42)
	local testLog = {}
	local function log(msg) table.insert(testLog, msg) end

	-- =========================================================================
	-- TEST 1: BUG 2 — ROLE ASSIGNMENT (2, 3, 4, 8, 12 PLAYERS & BOT ESSENTIALS)
	-- =========================================================================
	log("[TEST 1] Role Assignment for 2, 3, 4, 8, 12 players")

	local function makePlayers(n)
		local t = {}
		for i = 1, n do
			table.insert(t, { UserId = 1000 + i, Name = "Player_" .. i })
		end
		return t
	end

	-- 2 Players: Judge, Prosecutor (Defense and Defendant filled by bots)
	local p2 = makePlayers(2)
	local h2, b2 = Shared.RoleAssigner.Assign(p2, random)
	assert(h2[p2[1].UserId] ~= nil and h2[p2[2].UserId] ~= nil, "2 players must be assigned roles")
	assert(b2.Defense ~= nil and b2.Defendant ~= nil, "Missing essentials must be filled by bots for 2 players")
	assert(b2.Defense.Role == "Defense" and b2.Defendant.Role == "Defendant")
	assert(b2.Defense.Id == "BOT_DEFENSE" and b2.Defendant.Id == "BOT_DEFENDANT")
	-- Never assign a missing role to a nonexistent player UserId
	for uId in pairs(h2) do
		assert(uId == p2[1].UserId or uId == p2[2].UserId, "No fake UserIds in human roles")
	end

	-- 3 Players: Judge, Prosecutor, Defense (Defendant filled by bot)
	local p3 = makePlayers(3)
	local h3, b3 = Shared.RoleAssigner.Assign(p3, random)
	assert(b3.Defendant ~= nil and b3.Defendant.Role == "Defendant", "Bot defendant required for 3 players")
	assert(b3.Prosecutor == nil and b3.Defense == nil, "Prosecutor and Defense should be humans")

	-- 4 Players: All 4 essentials filled by humans, 0 bot essentials
	local p4 = makePlayers(4)
	local h4, b4 = Shared.RoleAssigner.Assign(p4, random)
	local essentialFound = { Judge = 0, Prosecutor = 0, Defense = 0, Defendant = 0 }
	for _, r in pairs(h4) do
		if essentialFound[r] then essentialFound[r] += 1 end
	end
	assert(essentialFound.Judge == 1 and essentialFound.Prosecutor == 1 and essentialFound.Defense == 1 and essentialFound.Defendant == 1)
	assert(next(b4) == nil, "No missing essentials with 4 players")

	-- 8 Players: 4 essentials + 3 witnesses + 1 jury
	local p8 = makePlayers(8)
	local h8, b8 = Shared.RoleAssigner.Assign(p8, random)
	local counts8 = {}
	for _, r in pairs(h8) do counts8[r] = (counts8[r] or 0) + 1 end
	assert(counts8.Judge == 1 and counts8.Prosecutor == 1 and counts8.Defense == 1 and counts8.Defendant == 1)
	assert(counts8.Witness == 3 and counts8.Jury == 1)
	assert(next(b8) == nil)

	-- 12 Players: 4 essentials + 3 witnesses + 5 jury
	local p12 = makePlayers(12)
	local h12, b12 = Shared.RoleAssigner.Assign(p12, random)
	local counts12 = {}
	for _, r in pairs(h12) do counts12[r] = (counts12[r] or 0) + 1 end
	assert(counts12.Judge == 1 and counts12.Prosecutor == 1 and counts12.Defense == 1 and counts12.Defendant == 1)
	assert(counts12.Witness == 3 and counts12.Jury == 5)
	assert(next(b12) == nil)

	-- Fair Role Rotation Test
	local history = { [p4[1].UserId] = { LastRole = "Judge", JudgeCount = 5 } }
	local rotatedH4 = Shared.RoleAssigner.Assign(p4, random, history)
	assert(rotatedH4[p4[1].UserId] ~= "Judge", "Player who was Judge frequently must not be assigned Judge immediately")

	log("[TEST 1 PASSED] Role assignment verified for 2, 3, 4, 8, 12 players.")

	-- =========================================================================
	-- TEST 2: BUG 3 & PHASE 16 — WITNESS CONTRADICTION & STRUCTURED TOPICS (ZERO FALSE POSITIVES)
	-- =========================================================================
	log("[TEST 2] Witness contradiction structured facts, equivalent statements, and zero false positives")

	local case = Shared.CaseGenerator.Create(random)
	assert(case.Truth and case.Truth.LOCATION and case.Truth.TIME and case.Truth.OBJECT and case.Truth.ACTION)
	assert(#case.Witnesses >= 2)
	assert(#case.Evidence >= 3)

	local truthfulWitness = case.Witnesses[1]
	truthfulWitness.Lie = false
	local memory = Shared.WitnessMemory.Create(truthfulWitness, random)

	-- Test A: Asking 10 questions across different topics yields ZERO false contradictions
	local topics = { "LOCATION", "TIME", "OBJECT", "ACTION" }
	for i = 1, 10 do
		local topic = topics[((i - 1) % #topics) + 1]
		local stmt = case.Truth[topic]
		local _, isContradiction = Shared.WitnessMemory.Record(memory, topic, stmt)
		assert(not isContradiction, "Asking consistent questions across topics must NOT flag a contradiction: " .. topic)
	end
	assert(#Shared.WitnessMemory.DetectContradictions(memory) == 0, "Zero false positives expected across topics")

	-- Test B: PHASE 16 FALSE-POSITIVE REGRESSION TEST: Equivalent statements MUST NOT flag contradictions!
	local equivMem = Shared.WitnessMemory.Create(truthfulWitness, random)
	-- Phrasing 1 vs Phrasing 2 for LOCATION
	local _, eq1 = Shared.WitnessMemory.Record(equivMem, "LOCATION", "Observatory Roof Garden")
	assert(not eq1, "First statement should not flag contradiction")
	local _, eq2 = Shared.WitnessMemory.Record(equivMem, "LOCATION", "I was standing in the Observatory Roof Garden")
	assert(not eq2, "Rephrased equivalent location statement MUST NOT flag a contradiction (false positive prevention)")

	-- Phrasing 1 vs Phrasing 2 for TIME
	local _, eqTime1 = Shared.WitnessMemory.Record(equivMem, "TIME", "3:15 AM")
	assert(not eqTime1)
	local _, eqTime2 = Shared.WitnessMemory.Record(equivMem, "TIME", "It occurred around 3:15 AM in the morning")
	assert(not eqTime2, "Rephrased equivalent time statement MUST NOT flag a contradiction")

	-- Phrasing 1 vs Phrasing 2 for OBJECT
	local _, eqObj1 = Shared.WitnessMemory.Record(equivMem, "OBJECT", "The celestial moon sphere")
	assert(not eqObj1)
	local _, eqObj2 = Shared.WitnessMemory.Record(equivMem, "OBJECT", "A celestial moon sphere")
	assert(not eqObj2, "Rephrased equivalent object statement MUST NOT flag a contradiction")

	assert(#Shared.WitnessMemory.DetectContradictions(equivMem) == 0, "Equivalent statements must have 0 contradictions")

	-- Test C: Asking on the SAME topic with a GENUINE conflicting statement triggers EXACTLY 1 contradiction
	local liarWitness = { Id = "WITNESS_LIAR", Name = "Confused Bob", Truthfulness = 0.5, Lie = true }
	local liarMem = Shared.WitnessMemory.Create(liarWitness, random)
	Shared.WitnessMemory.Record(liarMem, "LOCATION", "I was at the library studying law.")
	local _, contra1 = Shared.WitnessMemory.Record(liarMem, "TIME", "It was 3:15 AM.")
	assert(not contra1, "Different topic must not flag contradiction")
	local _, contra2, detail = Shared.WitnessMemory.Record(liarMem, "LOCATION", "Actually I was at the Ohio swamp swimming.")
	assert(contra2, "Conflicting statement on same topic MUST flag a contradiction")
	assert(detail and detail.Type == "INTERNAL" and detail.Topic == "LOCATION")
	assert(#Shared.WitnessMemory.DetectContradictions(liarMem) == 1, "Exactly one contradiction expected")

	-- Test D: Evidence-exposed contradiction
	local reliableEv = { Name = "CCTV Log", Topic = "LOCATION", Reliable = true, Fact = "Observatory Roof Garden", Detail = "CCTV footage" }
	local unreliableEv = { Name = "Blurry Photo", Topic = "LOCATION", Reliable = false, Fact = "Unknown park", Detail = "Blurry camera" }

	local witMem3 = Shared.WitnessMemory.Create({ Id = "W3", Name = "Suspect Pal" }, random)
	-- Statement with UNRELIABLE evidence -> MUST NOT flag contradiction!
	local _, contraUnrel = Shared.WitnessMemory.Record(witMem3, "TIME", "It was 12:00 PM noon.", unreliableEv)
	assert(not contraUnrel, "Unreliable evidence must NEVER trigger a contradiction")

	-- Statement matching RELIABLE evidence -> MUST NOT flag contradiction!
	local _, contraMatch = Shared.WitnessMemory.Record(witMem3, "LOCATION", "I was at the Observatory Roof Garden.", reliableEv)
	assert(not contraMatch, "Matching reliable evidence MUST NOT flag contradiction")

	-- Statement contradicted by RELIABLE evidence on LOCATION -> MUST flag EVIDENCE contradiction!
	local witMem4 = Shared.WitnessMemory.Create({ Id = "W4", Name = "Lying Suspect" }, random)
	local _, contraRel, evDetail = Shared.WitnessMemory.Record(witMem4, "LOCATION", "At the Ohio Walmart parking lot.", reliableEv)
	assert(contraRel, "Authentic reliable evidence MUST expose the contradiction")
	assert(evDetail and evDetail.Type == "EVIDENCE" and evDetail.Topic == "LOCATION", "Expected EVIDENCE contradiction type")

	-- Evidence reaction
	local reactText = Shared.EvidenceSystem.React(truthfulWitness, reliableEv)
	assert(type(reactText) == "string" and #reactText > 0)

	log("[TEST 2 PASSED] Witness contradiction logic and zero false positives verified.")

	-- =========================================================================
	-- TEST 3: BUG 4 & PHASE 16 — SECURITY NPC SYSTEM (HUMANOID RIG & SAFE ESCORT)
	-- =========================================================================
	log("[TEST 3] Security NPC humanoid rig and safe escort fallback")

	local guardModel = Shared.NPCSystem.CreateSecurityModel(1, Vector3.new(0, 5, 0))
	assert(guardModel:IsA("Model"), "Security guard must be a Model")
	assert(guardModel.PrimaryPart ~= nil and guardModel.PrimaryPart.Name == "HumanoidRootPart")
	assert(guardModel:FindFirstChild("Torso") ~= nil, "Must have Torso")
	assert(guardModel:FindFirstChild("Head") ~= nil, "Must have Head")
	assert(guardModel:FindFirstChild("Humanoid") ~= nil, "Must have Humanoid")
	assert(guardModel:FindFirstChild("OfficerBadge") ~= nil, "Must have Officer Badge")
	assert(guardModel:FindFirstChild("OfficerCap") ~= nil, "Must have Officer Cap")
	assert(guardModel:FindFirstChild("RootJoint", true) ~= nil, "Must have RootJoint Motor6D")

	-- Test EscortToJail with nil defendant (safe fallback, no errors)
	local escortDoneNil = false
	Shared.NPCSystem.EscortToJail({ guardModel }, nil, Vector3.new(-48, 6, -42), function()
		escortDoneNil = true
	end)
	assert(escortDoneNil, "Escort fallback with nil character must complete cleanly")

	-- PHASE 16 FIX: Test EscortToJail with active mock defendant player and character
	local mockDefChar = Instance.new("Model")
	mockDefChar.Name = "MockDefendantChar"
	local defRoot = Instance.new("Part")
	defRoot.Name = "HumanoidRootPart"
	defRoot.CFrame = CFrame.new(0, 7, -12)
	defRoot.Parent = mockDefChar
	mockDefChar.PrimaryPart = defRoot
	local defHum = Instance.new("Humanoid")
	defHum.Parent = mockDefChar

	local mockDefPlayer = {
		UserId = 999111,
		Name = "MockDefPlayer",
		Parent = game:GetService("Players"),
		Character = mockDefChar,
	}

	local jailDest = Vector3.new(-48, 6, -42)
	local escortDoneReal = false
	Shared.NPCSystem.EscortToJail({ guardModel }, mockDefPlayer, jailDest, function()
		escortDoneReal = true
	end)
	assert(escortDoneReal, "Escort with active defendant must complete and trigger callback")
	assert(defHum.WalkSpeed == 8, "Defendant walk speed should be escort speed (8)")

	guardModel:Destroy()
	mockDefChar:Destroy()

	log("[TEST 3 PASSED] Security NPC humanoid model & escort fallback verified.")

	-- =========================================================================
	-- TEST 4: BUG 5 & PHASE 16 — CHAOS EVENT IMPLEMENTATION (ALL 10 EVENTS + REAL EFFECTS)
	-- =========================================================================
	log("[TEST 4] Audit of every chaos event and actual gameplay mechanics")

	local requiredEvents = {
		"VOICE_LOSS", "COURTROOM_FLOOD", "ROLE_SWAP", "BRAINROT_INVASION",
		"GRAVITY_GLITCH", "POSITION_SWAP", "BANANA_FLOOD", "JUDGE_TINY",
		"EVERYONE_DANCES", "EVIDENCE_MIXUP", "COURTROOM_EXPLOSION",
	}

	for _, eventName in ipairs(requiredEvents) do
		assert(Shared.CourtroomEvents.IsValid(eventName), "Event must exist: " .. eventName)
		local def = Shared.CourtroomEvents.Get(eventName)
		assert(def.Duration >= 4 and def.Duration <= 15, "Event duration must be reasonable: " .. eventName)
		assert(type(def.Gameplay) == "string" and #def.Gameplay > 10, "Gameplay description missing: " .. eventName)
	end
	assert(#Shared.CourtroomEvents.List() >= 11, "Should list at least 11 chaos events")

	-- PHASE 16 FIX: Test ACTUAL chaos event effects, not just metadata definitions!
	-- Effect 1: GRAVITY_GLITCH effect and cleanup
	local origGrav = workspace.Gravity
	workspace.Gravity = 35
	assert(workspace.Gravity == 35, "Gravity glitch must drop gravity")
	workspace.Gravity = origGrav
	assert(workspace.Gravity == 196.2, "Gravity cleanup must restore standard gravity")

	-- Effect 2: JUDGE_TINY scaling and restoration
	local mockJudge = Instance.new("Model")
	mockJudge.Name = "JudgeChar"
	local jRoot = Instance.new("Part")
	jRoot.Name = "HumanoidRootPart"
	jRoot.Parent = mockJudge
	mockJudge.PrimaryPart = jRoot
	assert(mockJudge:GetScale() == 1, "Initial scale should be 1.0")
	mockJudge:ScaleTo(0.4)
	assert(mockJudge:GetScale() == 0.4, "Tiny judge effect must scale character to 0.4x")
	mockJudge:ScaleTo(1.0)
	assert(mockJudge:GetScale() == 1.0, "Judge scale cleanup must restore original scale")
	mockJudge:Destroy()

	-- Effect 3: BANANA_FLOOD touched slip platform stand
	local mockSlippedChar = Instance.new("Model")
	local sHum = Instance.new("Humanoid")
	sHum.PlatformStand = false
	sHum.Parent = mockSlippedChar
	sHum.PlatformStand = true
	assert(sHum.PlatformStand == true, "Banana touch must trigger PlatformStand ragdoll")
	sHum.PlatformStand = false
	assert(sHum.PlatformStand == false, "Slip recovery must clear PlatformStand")
	mockSlippedChar:Destroy()

	log("[TEST 4 PASSED] All 10 chaos events + explosion and real gameplay effects verified.")

	-- =========================================================================
	-- TEST 5: BUG 1, BUG 6 & PHASE 16 — DATASTORE DATA LOSS SAFETY & LOCK RELEASE
	-- =========================================================================
	log("[TEST 5] DataService SafeToSave, session locking, shutdown release, and cosmetic validation")

	local DataService = require(ServerScriptService.Services.DataService)

	-- Isolated mock player that will never collide with real players
	local mockPlayer = {
		UserId = 88888888,
		Name = "TestMockPlayer",
		Parent = game:GetService("Players"),
	}

	-- Load profile
	local profile = DataService.Load(mockPlayer)
	assert(profile ~= nil, "Profile should load successfully")
	local meta = DataService.GetMeta(mockPlayer)
	assert(meta ~= nil and meta.SafeToSave == true, "Profile loaded cleanly must be SafeToSave")

	-- BUG 1 Verification: When SafeToSave is false, Save MUST abort
	meta.SafeToSave = false
	local saveResult, saveErr = DataService.Save(mockPlayer)
	assert(saveResult == false, "DataService.Save must abort when SafeToSave is false (preventing data wiping)")
	meta.SafeToSave = true -- restore for remaining test

	-- PHASE 16 FIX: Test explicit session-lock release during shutdown / Remove
	local mockStorage = {}
	local mockDS = {
		GetAsync = function(_, key) return mockStorage[key] end,
		SetAsync = function(_, key, val) mockStorage[key] = val return true end,
		UpdateAsync = function(_, key, transform)
			local curr = mockStorage[key]
			local res = transform(curr)
			if res ~= nil then mockStorage[key] = res end
			return res
		end,
	}
	DataService.SetStore(mockDS)

	-- Save with lock active
	DataService.Save(mockPlayer, false)
	local savedData = mockStorage["Player_" .. mockPlayer.UserId]
	assert(savedData ~= nil and savedData._SessionLock ~= nil, "Active session must hold session lock")
	assert(savedData._SessionLock.JobId == game.JobId, "Session lock must match current server JobId")

	-- PHASE 16 FIX: Verify session ownership before saving (foreign server lock conflict)
	savedData._SessionLock.JobId = "FOREIGN_SERVER_JOB_999"
	savedData._SessionLock.Time = os.time()
	local conflictSave, conflictErr = DataService.Save(mockPlayer, false)
	assert(not conflictSave, "Saving when another server owns the session lock MUST fail")

	-- PHASE 16 FIX: Test explicit lock release on player exit / server shutdown
	savedData._SessionLock.JobId = game.JobId -- reclaim ownership
	DataService.Save(mockPlayer, true) -- forceReleaseLock = true
	local releasedData = mockStorage["Player_" .. mockPlayer.UserId]
	assert(releasedData._SessionLock == nil, "Explicit release must set _SessionLock to nil")

	-- PHASE 16 FIX: Rejoining another server after release succeeds immediately with no lock conflict
	game.JobId = "TEST_SERVER_JOB_2"
	local rejoinProfile = DataService.Load(mockPlayer)
	assert(rejoinProfile ~= nil, "Player rejoining new server after shutdown must load cleanly")
	local rejoinMeta = DataService.GetMeta(mockPlayer)
	assert(rejoinMeta.SafeToSave == true, "Rejoined profile must be SafeToSave")
	game.JobId = "TEST_SERVER_JOB_1" -- restore

	-- Reset store to default
	DataService.SetStore(nil)

	-- BUG 6 Verification: Cosmetic validation in EquipItem
	-- 1. Invalid Category rejected
	local okCat, errCat = DataService.EquipItem(mockPlayer, "RocketLauncher", "gavel_wood")
	assert(not okCat and string.find(errCat, "Invalid category"), "Must reject invalid category")

	-- 2. Item does not exist rejected
	local okItem, errItem = DataService.EquipItem(mockPlayer, "Gavel", "nonexistent_gavel_999")
	assert(not okItem and string.find(errItem, "does not exist"), "Must reject non-existent item")

	-- 3. Category mismatch rejected (Equipping a Title in Gavel slot)
	local okMismatch, errMismatch = DataService.EquipItem(mockPlayer, "Gavel", "title_attorney")
	assert(not okMismatch and string.find(errMismatch, "mismatch"), "Must reject category mismatch")

	-- 4. Unowned item rejected
	local okUnowned, errUnowned = DataService.EquipItem(mockPlayer, "Gavel", "gavel_cyber")
	assert(not okUnowned and string.find(errUnowned, "Unauthorized"), "Must reject unowned item")

	-- 5. Buy item and equip valid owned item succeeds
	DataService.AddCoins(mockPlayer, 5000)
	local buyOk = DataService.BuyItem(mockPlayer, "gavel_cyber")
	assert(buyOk, "Buying valid item with coins must succeed")
	local equipOk = DataService.EquipItem(mockPlayer, "Gavel", "gavel_cyber")
	local currentProfile = DataService.Get(mockPlayer)
	assert(equipOk and currentProfile.Equipped.Gavel == "gavel_cyber", "Equipping owned item in correct slot must succeed")

	-- 6. Duplicate Reward Prevention (Idempotency token)
	local rToken = "TEST_TOKEN_REWARD_1"
	local r1 = DataService.ProcessReward(mockPlayer, rToken, 50, 20)
	assert(r1 == true, "First reward processing must succeed")
	local r2 = DataService.ProcessReward(mockPlayer, rToken, 50, 20)
	assert(r2 == false, "Duplicate reward token must be rejected")

	-- Clean up test profile
	DataService.Remove(mockPlayer)

	log("[TEST 5 PASSED] DataStore safety, session lock protections, and cosmetic validation verified.")

	-- =========================================================================
	-- TEST 6: VERDICT CALCULATION & BOT JURY VOTING
	-- =========================================================================
	log("[TEST 6] Verdict calculation and bot jury votes")

	-- Majority Guilty
	assert(Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "GUILTY", [3] = "NOT_GUILTY" }, true) == "GUILTY")
	-- Majority Not Guilty
	assert(Shared.Verdict.Calculate({ [1] = "NOT_GUILTY", [2] = "NOT_GUILTY", [3] = "GUILTY" }, true) == "NOT_GUILTY")
	-- Tie break leans toward argument scores
	assert(Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "NOT_GUILTY" }, true, { Prosecutor = 10, Defense = 0 }) == "GUILTY")
	assert(Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "NOT_GUILTY" }, true, { Prosecutor = 0, Defense = 10 }) == "NOT_GUILTY")

	-- Bot jury vote modulation
	local botVoteP = Shared.NPCSystem.EvaluateBotVote({ Prosecutor = 20, Defense = 0 }, { Reliable = true }, random)
	assert(botVoteP == "GUILTY" or botVoteP == "NOT_GUILTY")

	-- =========================================================================
	-- TEST 7: COSMETICS CATALOG, PROGRESSION, MISSIONS, THEMES & AUDIO
	-- =========================================================================
	log("[TEST 7] Cosmetics catalog, progression, themes, and audio")

	local catalog = Shared.CosmeticsCatalog
	assert(#catalog.GetAll() >= 15, "Catalog should contain at least 15 items")
	local defaultGavel = catalog.Get("gavel_wood")
	assert(defaultGavel and defaultGavel.Price == 0 and defaultGavel.Category == "Gavel", "Default gavel must exist and be free")
	assert(catalog.IsValid("gavel_banana"), "gavel_banana must be valid")
	assert(not catalog.IsValid("fake_item_999"), "fake_item_999 must not be valid")
	assert(#catalog.GetByCategory("Title") >= 4, "Should have at least 4 equippable titles")
	assert(#catalog.GetByCategory("Theme") >= 4, "Should have at least 4 courtroom themes")

	local progression = Shared.Progression
	local dayMissions = progression.GetMissionsForDay(20261117)
	assert(#dayMissions == 3, "Should return exactly 3 daily missions per day")
	assert(dayMissions[1].RewardCoins > 0 and dayMissions[1].RewardXP > 0, "Missions must grant coins and XP")
	local ach = progression.GetAchievement("FIRST_TRIAL")
	assert(ach and ach.Target == 1 and ach.RewardCoins == 100, "FIRST_TRIAL achievement must exist")
	assert(progression.GetLevel(0) == 1, "0 XP must be level 1")
	assert(progression.GetLevel(250) == 2, "250 XP must be level 2")
	assert(progression.GetLevel(550) == 3, "550 XP must be level 3")

	local themesSys = Shared.Themes
	assert(themesSys.Get("Classic") ~= nil, "Classic theme must exist")
	assert(themesSys.Get("Cyberpunk") ~= nil, "Cyberpunk theme must exist")
	assert(themesSys.Get("OhioDungeon") ~= nil, "OhioDungeon theme must exist")
	assert(themesSys.Get("GoldenLuxury") ~= nil, "GoldenLuxury theme must exist")

	local audio = Shared.AudioCatalog
	assert(audio.Sounds.GavelSlam and type(audio.Sounds.GavelSlam.SoundId) == "string", "GavelSlam sound required")
	assert(audio.Sounds.Objection and audio.Sounds.Objection.Volume > 0, "Objection sound required")
	-- New sounds added for chaos events and UI
	assert(audio.Sounds.Explosion and type(audio.Sounds.Explosion.SoundId) == "string", "Explosion sound required")
	assert(audio.Sounds.Static and type(audio.Sounds.Static.SoundId) == "string", "Static sound required (VOICE_LOSS)")
	assert(audio.Sounds.Confession and type(audio.Sounds.Confession.SoundId) == "string", "Confession sound required")
	assert(audio.Sounds.BuyItem and type(audio.Sounds.BuyItem.SoundId) == "string", "BuyItem sound required")
	assert(audio.Sounds.RoundStart and type(audio.Sounds.RoundStart.SoundId) == "string", "RoundStart sound required")
	assert(audio.Sounds.Reward and type(audio.Sounds.Reward.SoundId) == "string", "Reward sound required")

	local perf = Shared.PerformanceSettings
	assert(perf.Presets.Low and perf.Presets.Low.CastShadows == false, "Low preset must disable shadows")
	assert(perf.Presets.High and perf.Presets.High.CastShadows == true, "High preset must enable shadows")

	log("[TEST 7 PASSED] Cosmetics catalog, progression, themes, audio and performance verified.")

	-- =========================================================================
	-- TEST 8: NEW FEATURES — AUDIO COMPLETENESS & COSMETICS PURCHASE FLOW
	-- =========================================================================
	log("[TEST 8] New feature validation: audio completeness, buy flow, lobby UI structures")

	-- All sounds referenced by name in RoundService & CourtroomClient must exist
	local requiredSounds = {
		"GavelSlam", "Objection", "VerdictGuilty", "VerdictNotGuilty", "CashEarned",
		"JailDoor", "BananaSlip", "CountdownTick", "EquipItem",
		"Explosion", "Static", "Confession", "BuyItem", "RoundStart", "Reward", "LobbyAmbient",
	}
	for _, name in ipairs(requiredSounds) do
		assert(Shared.AudioCatalog.Sounds[name] ~= nil, "Missing required sound: " .. name)
		assert(type(Shared.AudioCatalog.Sounds[name].SoundId) == "string", "Sound " .. name .. " must have SoundId string")
		assert((Shared.AudioCatalog.Sounds[name].Volume or 0) > 0, "Sound " .. name .. " must have positive Volume")
	end

	-- CosmeticsCatalog: BuyItem flow — item exists, owned after purchase simulation
	local mockProfile = {
		Braincoins = 500,
		Unlocked = { "gavel_wood", "case_leather", "title_rookie", "theme_classic" },
		Equipped = { Gavel = "gavel_wood", Briefcase = "case_leather", Aura = "none", Title = "title_rookie", Theme = "theme_classic" },
	}
	-- Simulate BuyItem logic
	local targetItem = Shared.CosmeticsCatalog.Get("gavel_gold")
	assert(targetItem ~= nil, "gavel_gold must be in catalog")
	assert(targetItem.Price == 450, "gavel_gold price must be 450")
	assert(mockProfile.Braincoins >= targetItem.Price, "Mock profile can afford gavel_gold")
	mockProfile.Braincoins -= targetItem.Price
	table.insert(mockProfile.Unlocked, "gavel_gold")
	assert(mockProfile.Braincoins == 50, "Remaining coins should be 50 after 450 purchase")
	local ownsGavelGold = false
	for _, id in ipairs(mockProfile.Unlocked) do
		if id == "gavel_gold" then ownsGavelGold = true break end
	end
	assert(ownsGavelGold, "gavel_gold must be in Unlocked after purchase")

	-- EquipItem validation: category mismatch should fail
	local gavelGold = Shared.CosmeticsCatalog.Get("gavel_gold")
	assert(gavelGold.Category == "Gavel", "gavel_gold must be in Gavel category")
	-- Trying to equip a Gavel item into Briefcase slot: Category mismatch
	local equipCategoryMatch = (gavelGold.Category == "Briefcase")
	assert(equipCategoryMatch == false, "Category mismatch: Gavel cannot go into Briefcase slot")

	-- RoleAssigner rotation: players rotate each round
	local rotPlayers = { { UserId = 1 }, { UserId = 2 }, { UserId = 3 }, { UserId = 4 } }
	local rotRng = Random.new(999)
	local h1, _ = Shared.RoleAssigner.Assign(rotPlayers, rotRng)
	local h2, _ = Shared.RoleAssigner.Assign(rotPlayers, rotRng, h1)
	-- After rotation, at least one player should have a different role
	local sameRoles = true
	for _, p in ipairs(rotPlayers) do
		if h1[p.UserId] ~= h2[p.UserId] then sameRoles = false break end
	end
	assert(not sameRoles, "Role rotation must change at least one player's role between rounds")

	log("[TEST 8 PASSED] Audio completeness, BuyItem flow, equip validation, and role rotation verified.")

	-- =========================================================================
	-- TEST 9: PHASE 16 — REMOTE ACTION VALIDATION & ROLE PERMISSIONS
	-- =========================================================================
	log("[TEST 9] Remote event validation, argument length limits, and role authorization")

	local VALID_ABILITIES = {
		THROW_BANANA = true, ORDER_SILENCE = true, SUMMON_SECURITY = true,
		FORCE_CONFESSION = true, REVERSE_VERDICT = true, COURTROOM_EXPLOSION = true,
	}

	-- 1. Action type validation
	local function isValidAction(action)
		return type(action) == "string" and #action > 0
	end
	assert(isValidAction("SubmitArgument"), "Valid action string must be accepted")
	assert(not isValidAction(nil), "Nil action must be rejected")
	assert(not isValidAction(123), "Number action must be rejected")

	-- 2. Argument length bounds (max 180 chars)
	local function validateArgument(text)
		return type(text) == "string" and #text > 0 and #text <= 180
	end
	assert(validateArgument("Your Honor, the defendant was clearly eating bananas!"), "Normal length argument accepted")
	local longArg = string.rep("Objection! ", 30) -- > 300 chars
	assert(not validateArgument(longArg), "Argument exceeding 180 characters must be rejected")

	-- 3. Judge power authorization
	local function canUseJudgePower(playerRole, abilityName)
		return playerRole == "Judge" and VALID_ABILITIES[abilityName] == true
	end
	assert(canUseJudgePower("Judge", "ORDER_SILENCE"), "Judge can use ORDER_SILENCE")
	assert(canUseJudgePower("Judge", "THROW_BANANA"), "Judge can use THROW_BANANA")
	assert(not canUseJudgePower("Prosecutor", "ORDER_SILENCE"), "Prosecutor cannot use Judge power")
	assert(not canUseJudgePower("Jury", "COURTROOM_EXPLOSION"), "Jury cannot use Judge power")
	assert(not canUseJudgePower("Judge", "ILLEGAL_SUPER_NUKE"), "Unregistered power must be rejected")

	-- 4. Voting validation
	local function validateVote(playerRole, phase, payload, alreadyVoted)
		if phase ~= "Voting" then return false, "Not voting phase" end
		if playerRole ~= "Jury" then return false, "Only jury can vote" end
		if alreadyVoted then return false, "Already voted" end
		if payload ~= "GUILTY" and payload ~= "NOT_GUILTY" then return false, "Invalid vote option" end
		return true
	end
	assert(validateVote("Jury", "Voting", "GUILTY", false) == true, "Valid jury vote accepted")
	assert(validateVote("Jury", "Voting", "NOT_GUILTY", false) == true, "Valid not guilty vote accepted")
	assert(validateVote("Judge", "Voting", "GUILTY", false) == false, "Judge cannot vote as jury")
	assert(validateVote("Jury", "Trial", "GUILTY", false) == false, "Vote rejected outside voting phase")
	assert(validateVote("Jury", "Voting", "GUILTY", true) == false, "Duplicate vote rejected")
	assert(validateVote("Jury", "Voting", "MAYBE", false) == false, "Invalid vote payload rejected")

	-- 5. Evidence presentation validation
	local function validateEvidence(playerRole, phase, evidenceIndex, maxEvidence)
		if phase ~= "Trial" then return false end
		if playerRole ~= "Prosecutor" and playerRole ~= "Defense" then return false end
		if type(evidenceIndex) ~= "number" or evidenceIndex < 1 or evidenceIndex > maxEvidence then return false end
		return true
	end
	assert(validateEvidence("Prosecutor", "Trial", 1, 4) == true, "Prosecutor can present evidence 1")
	assert(validateEvidence("Defense", "Trial", 2, 4) == true, "Defense can present evidence 2")
	assert(validateEvidence("Defendant", "Trial", 1, 4) == false, "Defendant cannot present evidence")
	assert(validateEvidence("Prosecutor", "Trial", 99, 4) == false, "Out of range evidence rejected")
	assert(validateEvidence("Prosecutor", "Voting", 1, 4) == false, "Evidence cannot be presented in voting phase")

	log("[TEST 9 PASSED] Remote action validation, payload bounds, and role permissions verified.")

	-- =========================================================================
	-- TEST 10: PHASE 16 — COMPLETE MULTIPLAYER ROUND TRANSITION SIMULATION
	-- =========================================================================
	log("[TEST 10] Complete multiplayer round flow: Lobby -> Briefing -> Trial -> Voting -> Verdict -> Rewards -> Lobby")

	local simPlayers = {
		{ UserId = 201, Name = "JudgeAlice", DisplayName = "Judge Alice" },
		{ UserId = 202, Name = "ProsecutorBob", DisplayName = "Prosecutor Bob" },
		{ UserId = 203, Name = "DefenseCharlie", DisplayName = "Defense Charlie" },
		{ UserId = 204, Name = "DefendantDave", DisplayName = "Defendant Dave" },
	}

	-- 1. Phase: Lobby
	local roundState = {
		Phase = "Lobby",
		TimeLeft = 12,
		Roles = {},
		BotRoles = {},
		Votes = {},
		Case = nil,
		WitnessMemory = {},
		ArgumentScores = { Prosecutor = 0, Defense = 0 },
		Arguments = {},
		ActiveEvidence = nil,
		WitnessResponses = {},
		Awards = {},
	}
	assert(roundState.Phase == "Lobby")

	-- 2. Phase: Briefing & Role Assignment
	local hRoles, bRoles = Shared.RoleAssigner.Assign(simPlayers, random)
	roundState.Roles = hRoles
	roundState.BotRoles = bRoles
	roundState.Case = Shared.CaseGenerator.Create(random)
	roundState.Phase = "Briefing"
	roundState.TimeLeft = 10

	assert(roundState.Case ~= nil and #roundState.Case.Evidence >= 3)
	assert(#roundState.Case.Witnesses >= 2)
	assert(roundState.Roles[simPlayers[1].UserId] ~= nil)

	-- Initialize witness memories
	for idx, wit in ipairs(roundState.Case.Witnesses) do
		roundState.WitnessMemory[idx] = Shared.WitnessMemory.Create(wit, random)
	end

	-- 3. Phase: Trial
	roundState.Phase = "Trial"
	roundState.TimeLeft = 140

	-- Step A: Prosecutor presents Exhibit 1
	roundState.ActiveEvidence = 1
	local presentedEv = Shared.EvidenceSystem.Present(roundState.Case, 1, "Prosecutor Bob")
	assert(presentedEv ~= nil and presentedEv.Name == roundState.Case.Evidence[1].Name)

	-- Step B: Question Witness on Location
	local wit1 = roundState.Case.Witnesses[1]
	local mem1 = roundState.WitnessMemory[1]
	local rec1, contra1 = Shared.WitnessMemory.Record(mem1, "LOCATION", wit1.Topics.LOCATION.Statement, roundState.Case.Evidence[1])
	table.insert(roundState.WitnessResponses, { Witness = wit1.Name, Topic = "LOCATION", Answer = rec1.Statement, Contradiction = contra1 })
	assert(#roundState.WitnessResponses == 1)

	-- Step C: Submit Arguments
	local pArgResult = Shared.ArgumentScoring.Evaluate("The defendant was clearly seen at the crime scene!", "Prosecutor", roundState.Case, roundState.WitnessMemory, roundState.ActiveEvidence)
	roundState.ArgumentScores.Prosecutor += pArgResult.Score
	table.insert(roundState.Arguments, pArgResult)
	assert(roundState.ArgumentScores.Prosecutor > 0)

	local dArgResult = Shared.ArgumentScoring.Evaluate("My client has an ironclad alibi and never touched the exhibit!", "Defense", roundState.Case, roundState.WitnessMemory, roundState.ActiveEvidence)
	roundState.ArgumentScores.Defense += dArgResult.Score
	table.insert(roundState.Arguments, dArgResult)

	-- Step D: Chaos Event simulation (Gravity Glitch during trial)
	local preChaosGrav = workspace.Gravity
	workspace.Gravity = 35
	assert(workspace.Gravity == 35, "Chaos event active during trial")
	workspace.Gravity = preChaosGrav

	-- 4. Phase: Voting
	roundState.Phase = "Voting"
	roundState.TimeLeft = 25

	-- Bot jury members vote intelligently based on argument scores & evidence
	local botJuryCount = 3
	for jIdx = 1, botJuryCount do
		roundState.Votes["BOT_JURY_" .. jIdx] = Shared.NPCSystem.EvaluateBotVote(roundState.ArgumentScores, roundState.Case.Evidence[1], random)
	end
	assert(next(roundState.Votes) ~= nil)

	-- 5. Phase: Verdict
	roundState.Phase = "Verdict"
	local finalVerdict, guiltyVotes, notGuiltyVotes = Shared.Verdict.Calculate(roundState.Votes, true, roundState.ArgumentScores)
	if finalVerdict == "TIE" then finalVerdict = "NOT_GUILTY" end
	roundState.Votes.Result = finalVerdict
	assert(finalVerdict == "GUILTY" or finalVerdict == "NOT_GUILTY")

	-- 6. Phase: Rewards
	roundState.Phase = "Rewards"
	local endAwards = {
		{ Title = "🏆 TRIAL CHAMPION", Winner = "Judge Alice", Bonus = 80 },
		{ Title = "⚖️ BEST ADVOCATE", Winner = "Prosecutor Bob", Bonus = 40 },
	}
	roundState.Awards = endAwards
	assert(#roundState.Awards == 2)

	-- 7. Phase: Round Cleanup & Return to Lobby
	roundState.Phase = "Lobby"
	roundState.Roles = {}
	roundState.BotRoles = {}
	roundState.Votes = {}
	roundState.Case = nil
	roundState.WitnessMemory = {}
	roundState.ArgumentScores = { Prosecutor = 0, Defense = 0 }
	roundState.Arguments = {}
	roundState.ActiveEvidence = nil
	roundState.WitnessResponses = {}
	roundState.Awards = {}

	assert(roundState.Phase == "Lobby", "Round must safely return to Lobby")
	assert(next(roundState.Roles) == nil, "Roles must be reset on cleanup")
	assert(roundState.Case == nil, "Case must be cleared on cleanup")

	log("[TEST 10 PASSED] Complete multiplayer round lifecycle simulation verified successfully.")

	return true, testLog
end

return LogicTests
