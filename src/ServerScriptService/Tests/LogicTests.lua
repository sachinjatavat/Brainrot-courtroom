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
	local result = Shared.Verdict.Calculate({ [1] = "GUILTY", [2] = "NOT_GUILTY", [3] = "GUILTY" }, true)
	assert(result == "GUILTY")
	return true
end

return LogicTests
