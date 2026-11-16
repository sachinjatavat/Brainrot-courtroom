local NPCSystem = {}

NPCSystem.Personalities = {
	Calm = { Reaction = "observes carefully", Bias = 0.5 },
	Drama = { Reaction = "gasps dramatically over the objection", Bias = 0.7 },
	Skeptic = { Reaction = "crosses arms and demands hard proof", Bias = 0.3 },
	Excited = { Reaction = "takes enthusiastic notes", Bias = 0.6 },
}

NPCSystem.SpectatorNames = {
	"Auntie Karen from Ohio", "Sigma Observer", "Anonymous Juror in Disguise",
	"Law Student with Overdue Tuition", "Local Pigeon Enthusiast",
	"Conspiracy Theorist with Tinfoil Hat", "Bystander Who Wanted Free Air Conditioning",
}

function NPCSystem.CreateSecurity(index)
	return {
		Id = "SECURITY_" .. tostring(index),
		Name = "Officer " .. (index == 1 and "Flapjack" or "Ironclad"),
		Role = "Security",
		Personality = index % 2 == 0 and "Skeptic" or "Calm",
	}
end

function NPCSystem.CreateBotWitness(index, random)
	random = random or Random.new()
	local personalities = { "Calm", "Drama", "Skeptic", "Excited" }
	local personality = personalities[random:NextInteger(1, #personalities)]
	return {
		Id = "BOT_WITNESS_" .. tostring(index),
		Name = "AI Witness #" .. tostring(index),
		Personality = personality,
		Truthfulness = (personality == "Skeptic" and 0.75) or (personality == "Drama" and 0.60) or 0.90,
		Bot = true,
		Lines = {
			"I observed the incident from a safe distance of exactly 42 studs.",
			"My sensory data indicates unusual potassium activity.",
			"The suspect made a suspicious gesture before disappearing.",
			"I require further forensic substantiation.",
		},
	}
end

function NPCSystem.CreateBotLawyer(role, random)
	random = random or Random.new()
	local names = (role == "Prosecutor")
		and { "Miles Edgeworth Jr.", "Prosecutor Steel", "Sigma Attorney Payne" }
		or { "Phoenix Wright-Hand", "Public Defender Bob", "Legal Eagle Saul" }
	local name = names[random:NextInteger(1, #names)]

	local arguments = (role == "Prosecutor") and {
		"The exhibit clearly proves malicious intent and cosmic disregard for law!",
		"Witness testimony establishes a timeline that leaves zero room for doubt!",
		"Fingerprints found on the banana correlate 99.8% with the accused!",
		"The defendant's sudden panic is an undeniable confession of guilt!",
	} or {
		"The prosecution's timeline is riddled with glaring contradictions!",
		"Reasonable doubt is evident: the sock could belong to anyone with feet!",
		"My client was in a completely different dimension at the time of the heist!",
		"The witness statement violates basic laws of culinary physics!",
	}

	return {
		Id = "BOT_" .. role:upper(),
		Name = name,
		Role = role,
		Bot = true,
		Arguments = arguments,
	}
end

function NPCSystem.CreateSpectators(count, random)
	random = random or Random.new()
	local roster = {}
	for i = 1, count or 6 do
		local name = NPCSystem.SpectatorNames[((i - 1) % #NPCSystem.SpectatorNames) + 1]
		table.insert(roster, {
			Id = "SPECTATOR_" .. tostring(i),
			Name = name,
			SeatIndex = i,
		})
	end
	return roster
end

function NPCSystem.EvaluateBotVote(argumentScores, activeEvidence, random)
	random = random or Random.new()
	local pScore = argumentScores and argumentScores.Prosecutor or 0
	local dScore = argumentScores and argumentScores.Defense or 0

	-- Base probability: 50/50
	local guiltyChance = 0.50

	-- Modulate based on argument score difference
	local scoreDiff = pScore - dScore
	guiltyChance = math.clamp(guiltyChance + (scoreDiff * 0.05), 0.15, 0.85)

	-- If genuine evidence was presented, lean guilty
	if activeEvidence and activeEvidence.Reliable then
		guiltyChance = math.clamp(guiltyChance + 0.15, 0.15, 0.90)
	end

	return (random:NextNumber() < guiltyChance) and "GUILTY" or "NOT_GUILTY"
end

return NPCSystem
