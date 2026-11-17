local WitnessMemory = {}

local STOP_WORDS = {
	["the"] = true, ["a"] = true, ["an"] = true, ["at"] = true, ["in"] = true,
	["on"] = true, ["it"] = true, ["was"] = true, ["i"] = true, ["saw"] = true,
	["observed"] = true, ["noticed"] = true, ["there"] = true, ["were"] = true,
	["my"] = true, ["of"] = true, ["to"] = true, ["with"] = true, ["from"] = true,
	["during"] = true, ["around"] = true, ["about"] = true, ["just"] = true,
	["clearly"] = true, ["actually"] = true, ["swore"] = true, ["think"] = true,
	["standing"] = true, ["located"] = true, ["happened"] = true, ["occurred"] = true,
}

local CANONICAL_ENTITIES = {
	LOCATION = {
		{ Tag = "OBSERVATORY", Keys = { "observatory", "roof garden" } },
		{ Tag = "CHAPEL", Keys = { "slumber", "chapel", "funeral" } },
		{ Tag = "PENTAGON", Keys = { "pentagon", "sub basement" } },
		{ Tag = "SERVER_CLOSET", Keys = { "server closet", "it closet", "router" } },
		{ Tag = "FOOD_COURT", Keys = { "cosmic food", "food court" } },
		{ Tag = "LIBRARY", Keys = { "historical library", "silence chamber" } },
		{ Tag = "BAKERY", Keys = { "artisan bakery", "underground garage" } },
		{ Tag = "WALMART", Keys = { "walmart", "parking lot" } },
		{ Tag = "SUBMARINE", Keys = { "submarine", "lake michigan" } },
		{ Tag = "IKEA", Keys = { "ikea", "wardrobe" } },
		{ Tag = "POTATO_ISLAND", Keys = { "potato island" } },
	},
	TIME = {
		{ Tag = "3_15_AM", Keys = { "3:15", "3 15" } },
		{ Tag = "1_45_PM", Keys = { "1:45", "1 45" } },
		{ Tag = "11_59_PM", Keys = { "11:59", "11 59", "midnight" } },
		{ Tag = "8_30_AM", Keys = { "8:30", "8 30" } },
		{ Tag = "5_00_PM", Keys = { "5:00", "5 00" } },
		{ Tag = "2_20_AM", Keys = { "2:20", "2 20" } },
		{ Tag = "4_10_AM", Keys = { "4:10", "4 10" } },
		{ Tag = "12_00_PM", Keys = { "12:00", "noon", "high noon" } },
		{ Tag = "7_45_PM", Keys = { "7:45", "dusk" } },
		{ Tag = "9_00_AM", Keys = { "9:00", "breakfast" } },
	},
	OBJECT = {
		{ Tag = "MOON_SPHERE", Keys = { "celestial moon", "moon sphere", "moon" } },
		{ Tag = "BANANAS", Keys = { "yellow bananas", "crate of bananas", "banana" } },
		{ Tag = "GOLD_TOILET", Keys = { "gold commode", "porcelain throne", "toilet" } },
		{ Tag = "WIFI_PASSWORDS", Keys = { "sticky note", "admin passwords", "passwords", "thumb drive" } },
		{ Tag = "PLASTIC_SPOON", Keys = { "bendy spoon", "plastic spoon", "cutlery" } },
		{ Tag = "BOOMBOX", Keys = { "boombox", "dancing sheet" } },
		{ Tag = "SOURDOUGH_CAR", Keys = { "sourdough vehicle", "loaf mobile", "lamborghini" } },
		{ Tag = "POOL_NOODLE", Keys = { "pool noodle" } },
		{ Tag = "CORN_DOG", Keys = { "corn dog" } },
		{ Tag = "POKEMON_CARD", Keys = { "pokemon card" } },
	},
	ACTION = {
		{ Tag = "UNBOLTING_MOON", Keys = { "unbolting", "monkey wrench" } },
		{ Tag = "EATING_BANANAS", Keys = { "forty bananas", "inhaling bananas", "eating bananas" } },
		{ Tag = "WHEELING_TOILET", Keys = { "wheeling the toilet", "hallway b", "stolen skateboard" } },
		{ Tag = "PLUGGING_MAINFRAME", Keys = { "thumb drive into", "mainframe" } },
		{ Tag = "STIRRING_SPACETIME", Keys = { "spacetime continuum", "stirring" } },
		{ Tag = "HEADSPINNING", Keys = { "headspinning", "ancient manuscripts" } },
		{ Tag = "REVVING_YEAST", Keys = { "invisible engine", "yeast" } },
		{ Tag = "PARALLEL_PARKING", Keys = { "parallel parking" } },
		{ Tag = "KNITTING_SWEATER", Keys = { "knitting", "holiday sweater" } },
		{ Tag = "KARAOKE", Keys = { "karaoke", "80s rock" } },
		{ Tag = "MACARENA", Keys = { "macarena" } },
	},
}

local function normalize(value)
	local str = string.lower(tostring(value or ""))
	str = string.gsub(str, "[%p%s]+", " ")
	str = string.gsub(str, "^%s+", "")
	str = string.gsub(str, "%s+$", "")
	return str
end

WitnessMemory.Normalize = normalize

-- Structured factual extraction
local function extractCanonicalEntity(text, topic)
	local norm = normalize(text)
	local entities = CANONICAL_ENTITIES[topic]
	if not entities then return nil end

	for _, ent in ipairs(entities) do
		for _, key in ipairs(ent.Keys) do
			if string.find(norm, key, 1, true) then
				return ent.Tag
			end
		end
	end
	return nil
end

WitnessMemory.ExtractEntity = extractCanonicalEntity

-- Extract significant non-stopword tokens
local function extractSignificantTokens(text)
	local norm = normalize(text)
	local tokens = {}
	for word in string.gmatch(norm, "%S+") do
		if not STOP_WORDS[word] and #word >= 2 then
			tokens[word] = true
		end
	end
	return tokens
end

WitnessMemory.ExtractTokens = extractSignificantTokens

-- Determines if two statements express equivalent factual meaning on a topic
function WitnessMemory.AreEquivalent(stmt1, stmt2, topic)
	local n1 = normalize(stmt1)
	local n2 = normalize(stmt2)
	if n1 == n2 then return true end

	-- Check canonical entities if mapped
	local ent1 = extractCanonicalEntity(stmt1, topic)
	local ent2 = extractCanonicalEntity(stmt2, topic)
	if ent1 and ent2 then
		return ent1 == ent2
	end

	-- Jaccard similarity of significant tokens
	local tok1 = extractSignificantTokens(stmt1)
	local tok2 = extractSignificantTokens(stmt2)

	local intersection, union = 0, 0
	for w in pairs(tok1) do
		if tok2[w] then intersection += 1 end
		union += 1
	end
	for w in pairs(tok2) do
		if not tok1[w] then union += 1 end
	end

	if union == 0 then return true end
	local similarity = intersection / union
	return similarity >= 0.4
end

-- Determines if two statements on the same topic represent a genuine contradiction
function WitnessMemory.AreContradictory(stmt1, stmt2, topic)
	if WitnessMemory.AreEquivalent(stmt1, stmt2, topic) then
		return false
	end

	local ent1 = extractCanonicalEntity(stmt1, topic)
	local ent2 = extractCanonicalEntity(stmt2, topic)

	if ent1 and ent2 then
		return ent1 ~= ent2
	end

	-- If significant tokens have zero overlap on the same topic, they are contradictory claims
	local tok1 = extractSignificantTokens(stmt1)
	local tok2 = extractSignificantTokens(stmt2)
	local hasOverlap = false
	for w in pairs(tok1) do
		if tok2[w] then hasOverlap = true break end
	end

	return not hasOverlap
end

function WitnessMemory.Create(witness, random)
	random = random or Random.new()
	local truthfulness = witness and witness.Truthfulness or 1
	local isLying = false
	if witness and witness.Lie ~= nil then
		isLying = witness.Lie
	elseif random:NextNumber() > truthfulness then
		isLying = true
	end

	local memory = {
		WitnessId = witness and (witness.Id or witness.Name) or "WITNESS_UNKNOWN",
		Name = witness and witness.Name or "Witness",
		Truthfulness = truthfulness,
		Lie = isLying,
		Topics = witness and witness.Topics or {},
		AnswersByTopic = {},
		History = {},
		Contradictions = {},
		QuestionCount = 0,
	}
	return memory
end

-- PHASE 16: Logical contradiction rules with structured factual values
-- 1. Compare structured factual values, not exact string identity alone.
-- 2. Recognize equivalent statements (e.g. "Observatory Roof Garden" vs "I was at the Observatory Roof Garden").
-- 3. Only flag genuine contradictions (mutually exclusive facts on same topic).
-- 4. Never flag contradictions across different topics (zero false positives).
-- 5. Only authentic/reliable evidence (Reliable == true) can expose a contradiction.
function WitnessMemory.Record(memory, topic, statement, evidenceObj)
	assert(memory and type(memory.AnswersByTopic) == "table", "invalid witness memory")

	topic = string.upper(tostring(topic or "GENERAL"))
	statement = tostring(statement or "")

	local record = {
		Index = #memory.History + 1,
		Topic = topic,
		Statement = statement,
		Normalized = normalize(statement),
		Entity = extractCanonicalEntity(statement, topic),
		Evidence = evidenceObj,
		Timestamp = os.clock(),
	}

	table.insert(memory.History, record)
	memory.AnswersByTopic[topic] = memory.AnswersByTopic[topic] or {}
	local previousTopicAnswers = memory.AnswersByTopic[topic]

	local isContradiction = false
	local contradictionDetail = nil

	-- Rule 1: Internal Contradiction on SAME topic
	if #previousTopicAnswers > 0 then
		local prev = previousTopicAnswers[#previousTopicAnswers]
		if WitnessMemory.AreContradictory(prev.Statement, statement, topic) then
			isContradiction = true
			contradictionDetail = {
				Type = "INTERNAL",
				Topic = topic,
				First = prev,
				Second = record,
				Reason = string.format("Witness previously stated '%s' for topic %s, but now claims conflicting fact '%s'", prev.Statement, topic, statement),
			}
		end
	end

	-- Rule 2: Evidence-Exposed Contradiction
	-- Only authentic reliable evidence for this specific topic can expose a contradiction.
	if not isContradiction and evidenceObj and type(evidenceObj) == "table" then
		if evidenceObj.Reliable == true and string.upper(tostring(evidenceObj.Topic or "")) == topic then
			local fact = evidenceObj.Fact or evidenceObj.Detail or ""
			-- If the witness statement genuinely contradicts the evidence fact
			if WitnessMemory.AreContradictory(statement, fact, topic) then
				isContradiction = true
				contradictionDetail = {
					Type = "EVIDENCE",
					Topic = topic,
					Evidence = evidenceObj,
					Statement = record,
					Reason = string.format("Authentic evidence '%s' disproves witness claim '%s' on %s", evidenceObj.Name, statement, topic),
				}
			end
		end
	end

	table.insert(previousTopicAnswers, record)
	memory.QuestionCount += 1

	if isContradiction and contradictionDetail then
		table.insert(memory.Contradictions, contradictionDetail)
		record.Contradicts = contradictionDetail
	end

	return record, isContradiction, contradictionDetail
end

function WitnessMemory.DetectContradictions(memory)
	return memory and memory.Contradictions or {}
end

return WitnessMemory
