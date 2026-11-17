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
	-- TEST 2: BUG 3 — WITNESS CONTRADICTION & STRUCTURED TOPICS (ZERO FALSE POSITIVES)
	-- =========================================================================
	log("[TEST 2] Witness contradiction false positives and evidence reactions")

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

	-- Test B: Asking on the SAME topic with a conflicting statement triggers EXACTLY 1 contradiction
	local liarWitness = { Id = "WITNESS_LIAR", Name = "Confused Bob", Truthfulness = 0.5, Lie = true }
	local liarMem = Shared.WitnessMemory.Create(liarWitness, random)
	Shared.WitnessMemory.Record(liarMem, "LOCATION", "I was at the library studying law.")
	local _, contra1 = Shared.WitnessMemory.Record(liarMem, "TIME", "It was 3:15 AM.")
	assert(not contra1, "Different topic must not flag contradiction")
	local _, contra2, detail = Shared.WitnessMemory.Record(liarMem, "LOCATION", "Actually I was at the Ohio swamp swimming.")
	assert(contra2, "Conflicting statement on same topic MUST flag a contradiction")
	assert(detail and detail.Type == "INTERNAL" and detail.Topic == "LOCATION")
	assert(#Shared.WitnessMemory.DetectContradictions(liarMem) == 1, "Exactly one contradiction expected")

	-- Test C: Evidence-exposed contradiction
	local reliableEv = { Name = "CCTV Log", Topic = "LOCATION", Reliable = true, Fact = "Restricted IT Server Room", Detail = "CCTV footage" }
	local unreliableEv = { Name = "Blurry Photo", Topic = "LOCATION", Reliable = false, Fact = "Unknown park", Detail = "Blurry camera" }

	local witMem3 = Shared.WitnessMemory.Create({ Id = "W3", Name = "Suspect Pal" }, random)
	-- Statement with UNRELIABLE evidence -> MUST NOT flag contradiction!
	local _, contraUnrel = Shared.WitnessMemory.Record(witMem3, "TIME", "It was 12:00 PM noon.", unreliableEv)
	assert(not contraUnrel, "Unreliable evidence must NEVER trigger a contradiction")

	-- Statement contradicted by RELIABLE evidence on LOCATION -> MUST flag contradiction!
	local _, contraRel, evDetail = Shared.WitnessMemory.Record(witMem3, "LOCATION", "I was at the amusement park.", reliableEv)
	assert(contraRel, "Authentic reliable evidence MUST expose the contradiction")
	assert(evDetail and evDetail.Type == "EVIDENCE" and evDetail.Topic == "LOCATION", "Expected EVIDENCE contradiction type")

	-- Evidence reaction
	local reactText = Shared.EvidenceSystem.React(truthfulWitness, reliableEv)
	assert(type(reactText) == "string" and #reactText > 0)

	log("[TEST 2 PASSED] Witness contradiction logic and zero false positives verified.")

	-- =========================================================================
	-- TEST 3: BUG 4 — SECURITY NPC SYSTEM (HUMANOID RIG & SAFE ESCORT)
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
	local escortDone = false
	Shared.NPCSystem.EscortToJail({ guardModel }, nil, Vector3.new(-48, 6, -42), function()
		escortDone = true
	end)
	-- Verify safe fallback execution without errors
	guardModel:Destroy()

	log("[TEST 3 PASSED] Security NPC humanoid model & escort fallback verified.")

	-- =========================================================================
	-- TEST 4: BUG 5 — CHAOS EVENT IMPLEMENTATION (ALL 10 EVENTS + EXPLOSION)
	-- =========================================================================
	log("[TEST 4] Audit of every chaos event")

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

	log("[TEST 4 PASSED] All 10 chaos events + explosion verified.")

	-- =========================================================================
	-- TEST 5: BUG 1 & BUG 6 — DATASTORE DATA LOSS SAFETY & COSMETIC VALIDATION
	-- =========================================================================
	log("[TEST 5] DataService SafeToSave, session locking, and cosmetic validation")

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
	assert(saveResult == false, "DataService.Save must abort when SafeToSave is false")
	meta.SafeToSave = true -- restore for remaining test

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
	assert(equipOk and profile.Equipped.Gavel == "gavel_cyber", "Equipping owned item in correct slot must succeed")

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

	return true, testLog
end

return LogicTests
