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
	local random = Random.new(7)
	local fakePlayers = {}
	for index = 1, 8 do
		table.insert(fakePlayers, { UserId = index })
	end

	-- Phase 1-3 Tests
	local roles = Shared.RoleAssigner.Assign(fakePlayers, random)
	local counts = {}
	for _, role in pairs(roles) do counts[role] = (counts[role] or 0) + 1 end
	assert(counts.Judge == 1 and counts.Prosecutor == 1 and counts.Defense == 1 and counts.Defendant == 1)
	assert(counts.Witness == 2 and counts.Jury == 2)
	local case = Shared.CaseGenerator.Create(random)
	assert(#case.Evidence >= 3 and #case.Evidence <= 5)
	assert(#case.Witnesses == 2 and #case.Witnesses[1].Lines > 0 and #case.Witnesses[2].Lines > 0)
	local reliableCount = 0
	for _, item in ipairs(case.Evidence) do
		assert(type(item.Name) == "string" and type(item.Detail) == "string")
		if item.Reliable then reliableCount += 1 end
	end
	assert(reliableCount >= 1)
	local result = Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "NOT_GUILTY", [3] = "GUILTY" }, true)
	assert(result == "GUILTY")

	-- Phase 5 Memory & Scoring Tests
	local memory = Shared.WitnessMemory.Create({ Id = "TEST", Name = "Test Witness", Lie = true }, random)
	Shared.WitnessMemory.Record(memory, "Where were you?", "At the banana stand")
	local _, contradiction = Shared.WitnessMemory.Record(memory, "Where were you?", "In the evidence room")
	assert(contradiction and #Shared.WitnessMemory.DetectContradictions(memory) == 1)
	local inspected = Shared.EvidenceSystem.Inspect(case, 1)
	assert(inspected and inspected.Name == case.Evidence[1].Name and inspected.Misleading == (not case.Evidence[1].Reliable))
	local presented = Shared.EvidenceSystem.Present(case, 1, "Lawyer")
	assert(presented.Presented and presented.Presenter == "Lawyer")
	local genuineIndex
	for index, item in ipairs(case.Evidence) do
		if item.Reliable then genuineIndex = index; break end
	end
	local argument = Shared.ArgumentScoring.Evaluate("Evidence " .. tostring(genuineIndex) .. " proves the motive and the testimony is consistent.", "Prosecutor", case, { memory }, genuineIndex)
	assert(argument.Score > 0 and #argument.Reasons > 0)
	local defense = Shared.ArgumentScoring.Evaluate("The contradiction creates reasonable doubt.", "Defense", case, { memory }, genuineIndex)
	assert(defense.Score > 0)
	assert(Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "NOT_GUILTY" }, true, { Prosecutor = 5, Defense = 0 }) == "GUILTY")
	assert(Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "NOT_GUILTY" }, true, { Prosecutor = 0, Defense = 5 }) == "NOT_GUILTY")
	assert(Shared.CourtroomEvents.IsValid("EVIDENCE_MIXUP") and Shared.CourtroomEvents.Get("EVIDENCE_MIXUP").Duration > 0)
	assert(Shared.NPCSystem.CreateSecurity(1).Role == "Security")
	assert(Shared.NPCSystem.CreateBotWitness(1, random).Bot == true)
	local tie = Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "NOT_GUILTY" }, true)
	assert(tie == "TIE")
	local ignored = Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "INVALID" }, true)
	assert(ignored == "GUILTY")

	-- ==================== PHASE 6 TESTS ====================

	-- 1. Cosmetics Catalog Tests
	local catalog = Shared.CosmeticsCatalog
	assert(#catalog.GetAll() >= 15, "Catalog should contain at least 15 items")
	local defaultGavel = catalog.Get("gavel_wood")
	assert(defaultGavel and defaultGavel.Price == 0 and defaultGavel.Category == "Gavel")
	local cyberGavel = catalog.Get("gavel_cyber")
	assert(cyberGavel and cyberGavel.Price == 850 and cyberGavel.Rarity == "Epic")
	assert(catalog.IsValid("gavel_banana"))
	assert(not catalog.IsValid("fake_item_999"))
	local titles = catalog.GetByCategory("Title")
	assert(#titles >= 4, "Should have at least 4 equippable titles")
	local themes = catalog.GetByCategory("Theme")
	assert(#themes >= 4, "Should have at least 4 courtroom themes")

	-- 2. Progression & Daily Missions Tests
	local progression = Shared.Progression
	local dayMissions = progression.GetMissionsForDay(20261117)
	assert(#dayMissions == 3, "Should return exactly 3 daily missions per day")
	assert(dayMissions[1].RewardCoins > 0 and dayMissions[1].RewardXP > 0)
	local ach = progression.GetAchievement("FIRST_TRIAL")
	assert(ach and ach.Target == 1 and ach.RewardCoins == 100)
	assert(progression.GetLevel(0) == 1)
	assert(progression.GetLevel(250) == 2)
	assert(progression.GetLevel(550) == 3)
	assert(progression.GetNextLevelXP(2) == 500)

	-- 3. Themes System Tests
	local themesSys = Shared.Themes
	local classic = themesSys.Get("Classic")
	assert(classic and classic.FloorMaterial == Enum.Material.WoodPlanks)
	local cyberpunk = themesSys.Get("Cyberpunk")
	assert(cyberpunk and cyberpunk.FloorMaterial == Enum.Material.Metal and cyberpunk.Lighting)
	local dungeon = themesSys.Get("OhioDungeon")
	assert(dungeon and dungeon.FloorMaterial == Enum.Material.Cobblestone)
	local luxury = themesSys.Get("GoldenLuxury")
	assert(luxury and luxury.FloorMaterial == Enum.Material.Marble)
	assert(#themesSys.List() >= 4)

	-- 4. Audio Catalog Tests
	local audio = Shared.AudioCatalog
	assert(audio.Sounds.GavelSlam and type(audio.Sounds.GavelSlam.SoundId) == "string")
	assert(audio.Sounds.Objection and audio.Sounds.Objection.Volume > 0)
	assert(audio.Sounds.VerdictGuilty and audio.Sounds.VerdictNotGuilty)

	-- 5. Performance Settings Tests
	local perf = Shared.PerformanceSettings
	assert(perf.Presets.Low and perf.Presets.Low.CastShadows == false)
	assert(perf.Presets.High and perf.Presets.High.CastShadows == true)

	-- 6. DataService Integration Tests
	local DataService = require(ServerScriptService.Services.DataService)
	local testPlayer = {
		UserId = 99999,
		Parent = game:GetService("Players"),
	}
	local profile = DataService.Load(testPlayer)
	assert(profile and profile.Braincoins >= 0 and profile.Level == 1)

	-- Test AddCoins & AddXP
	DataService.AddCoins(testPlayer, 1000)
	assert(profile.Braincoins >= 1000)
	DataService.AddXP(testPlayer, 300)
	assert(profile.Level >= 2)

	-- Test BuyItem
	local buySuccess, buyItem = DataService.BuyItem(testPlayer, "title_attorney")
	assert(buySuccess and buyItem.Id == "title_attorney")
	local buyFailAlready = DataService.BuyItem(testPlayer, "title_attorney")
	assert(not buyFailAlready, "Should fail when already owned")

	-- Test EquipItem
	local equipSuccess = DataService.EquipItem(testPlayer, "Title", "title_attorney")
	assert(equipSuccess and profile.Equipped.Title == "title_attorney")
	local equipFail = DataService.EquipItem(testPlayer, "Title", "unowned_item_id")
	assert(not equipFail, "Should fail when item is not owned")

	-- Test RecordProgress & Mission Claiming
	local currentDay = math.floor(os.time() / 86400)
	local activeMission = Shared.Progression.GetMissionsForDay(currentDay)[1]
	DataService.RecordProgress(testPlayer, activeMission.Id, activeMission.Target + 1)
	local missionClaimSuccess, claimedM = DataService.ClaimDailyMission(testPlayer, activeMission.Id)
	assert(missionClaimSuccess and claimedM.Id == activeMission.Id)
	local doubleClaim = DataService.ClaimDailyMission(testPlayer, activeMission.Id)
	assert(not doubleClaim, "Cannot claim mission twice on same day")

	-- Test Achievement Claiming
	DataService.RecordProgress(testPlayer, "FIRST_TRIAL", 1)
	local achClaimSuccess, claimedAch = DataService.ClaimAchievement(testPlayer, "FIRST_TRIAL")
	assert(achClaimSuccess and claimedAch.Id == "FIRST_TRIAL")

	-- Clean up test profile
	DataService.Remove(testPlayer)

	return true
end

return LogicTests
