local NPCSystem = {}

NPCSystem.Personalities = {
	Calm = { Reaction = "observes carefully" },
	Drama = { Reaction = "shouts over the objection" },
	Skeptic = { Reaction = "demands proof" },
}

function NPCSystem.CreateSecurity(index)
	return {
		Id = "SECURITY_" .. tostring(index),
		Name = "Security Bot " .. tostring(index),
		Role = "Security",
		Personality = index % 2 == 0 and "Skeptic" or "Calm",
	}
end

function NPCSystem.CreateBotWitness(index, random)
	local personalities = { "Calm", "Drama", "Skeptic" }
	local personality = personalities[random:NextInteger(1, #personalities)]
	return {
		Id = "BOT_WITNESS_" .. tostring(index),
		Name = "Bot Witness " .. tostring(index),
		Personality = personality,
		Truthfulness = personality == "Skeptic" and 0.75 or 1,
		Bot = true,
	}
end

return NPCSystem
