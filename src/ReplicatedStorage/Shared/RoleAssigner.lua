local RoleAssigner = {}

function RoleAssigner.Assign(players, random, history)
	random = random or Random.new()
	history = history or {}

	local shuffled = table.clone(players)
	for i = #shuffled, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	-- Fair rotation sort: prioritize players who have NOT held high-impact roles (Judge, Prosecutor, Defense) recently
	table.sort(shuffled, function(a, b)
		local hA = history[a.UserId]
		local hB = history[b.UserId]
		local lastA = hA and hA.LastRole or ""
		local lastB = hB and hB.LastRole or ""
		local judgeCountA = (hA and hA.JudgeCount or 0)
		local judgeCountB = (hB and hB.JudgeCount or 0)

		if lastA == "Judge" and lastB ~= "Judge" then
			return false
		elseif lastB == "Judge" and lastA ~= "Judge" then
			return true
		end
		return judgeCountA < judgeCountB
	end)

	local roles = {}
	local roleSlots = { "Judge", "Prosecutor", "Defense", "Defendant", "Witness", "Witness", "Witness" }
	for index, player in ipairs(shuffled) do
		if player and player.UserId then
			local assignedRole = roleSlots[index] or "Jury"
			roles[player.UserId] = assignedRole
		end
	end

	return roles
end

return RoleAssigner
