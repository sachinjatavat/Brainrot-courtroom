local RoleAssigner = {}

local ESSENTIAL_ROLES = { "Judge", "Prosecutor", "Defense", "Defendant" }

local BOT_DEFAULTS = {
	Judge = { Id = "BOT_JUDGE", Name = "Honorable Robo-Judge", Role = "Judge" },
	Prosecutor = { Id = "BOT_PROSECUTOR", Name = "Prosecutor Glitch-Bot", Role = "Prosecutor" },
	Defense = { Id = "BOT_DEFENSE", Name = "Attorney Robo-Brain", Role = "Defense" },
	Defendant = { Id = "BOT_DEFENDANT", Name = "Suspect Skibidi", Role = "Defendant" },
}

RoleAssigner.ESSENTIAL_ROLES = ESSENTIAL_ROLES
RoleAssigner.BOT_DEFAULTS = BOT_DEFAULTS

function RoleAssigner.Assign(players, random, history)
	random = random or Random.new()
	history = history or {}

	local shuffled = table.clone(players)
	for i = #shuffled, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	-- Fair rotation sort: prioritize players who have NOT held high-impact roles recently
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

	local humanRoles = {}
	local roleSlots = { "Judge", "Prosecutor", "Defense", "Defendant", "Witness", "Witness", "Witness" }
	local assignedEssential = {}

	for index, player in ipairs(shuffled) do
		if player and player.UserId then
			local assignedRole = roleSlots[index] or "Jury"
			humanRoles[player.UserId] = assignedRole
			assignedEssential[assignedRole] = true
		end
	end

	-- BUG 2 FIX: Ensure all 4 essential roles exist in every trial (2-12 players).
	-- Never assign a missing role to a nonexistent player. Fill missing roles with functional bots.
	local botRoles = {}
	for _, essential in ipairs(ESSENTIAL_ROLES) do
		if not assignedEssential[essential] then
			botRoles[essential] = table.clone(BOT_DEFAULTS[essential])
		end
	end

	return humanRoles, botRoles
end

return RoleAssigner
