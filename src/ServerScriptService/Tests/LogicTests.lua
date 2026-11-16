local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)

local LogicTests = {}

function LogicTests.Run()
	local random = Random.new(7)
	local fakePlayers = {}
	for index = 1, 8 do
		table.insert(fakePlayers, { UserId = index })
	end
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
	return true
end

return LogicTests
