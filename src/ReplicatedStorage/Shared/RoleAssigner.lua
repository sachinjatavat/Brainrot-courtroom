local RoleAssigner = {}

function RoleAssigner.Assign(players, random)
	local shuffled = table.clone(players)
	for i = #shuffled, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	local roles = {}
	local names = { "Judge", "Prosecutor", "Defense", "Defendant", "Witness", "Witness" }
	for index, player in ipairs(shuffled) do
		if player and player.UserId then
			roles[player.UserId] = names[index] or "Jury"
		end
	end
	return roles
end

return RoleAssigner
