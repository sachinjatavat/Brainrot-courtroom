local WitnessMemory = {}

local function normalize(value)
	local str = string.lower(tostring(value or ""))
	-- Replace punctuation and multiple spaces with a single space
	str = string.gsub(str, "[%p%s]+", " ")
	str = string.gsub(str, "^%s+", "")
	str = string.gsub(str, "%s+$", "")
	return str
end

WitnessMemory.Normalize = normalize

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
		AnswersByTopic = {}, -- topic -> array of answer records
		History = {},        -- ordered list of all answers
		Contradictions = {}, -- flagged genuine contradictions
		QuestionCount = 0,
	}
	return memory
end

-- BUG 3 FIX: Logical contradiction rules
-- 1. Only flag genuine contradictions.
-- 2. Internal contradiction: only if witness previously answered on the SAME topic with a conflicting statement.
-- 3. Evidence contradiction: only if authentic reliable evidence (Reliable == true) disproves the witness's claim on that topic.
-- 4. Never flag contradictions across different topics (zero false positives).
function WitnessMemory.Record(memory, topic, statement, evidenceObj)
	assert(memory and type(memory.AnswersByTopic) == "table", "invalid witness memory")

	topic = string.upper(tostring(topic or "GENERAL"))
	statement = tostring(statement or "")

	local record = {
		Index = #memory.History + 1,
		Topic = topic,
		Statement = statement,
		Normalized = normalize(statement),
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
		if prev.Normalized ~= record.Normalized then
			isContradiction = true
			contradictionDetail = {
				Type = "INTERNAL",
				Topic = topic,
				First = prev,
				Second = record,
				Reason = string.format("Witness previously stated '%s' for topic %s, but now claims '%s'", prev.Statement, topic, statement),
			}
		end
	end

	-- Rule 2: Evidence-Exposed Contradiction
	-- Only authentic/reliable evidence for this specific topic can expose a contradiction.
	if not isContradiction and evidenceObj and type(evidenceObj) == "table" then
		if evidenceObj.Reliable == true and string.upper(tostring(evidenceObj.Topic or "")) == topic then
			local fact = evidenceObj.Fact or evidenceObj.Detail or ""
			local normFact = normalize(fact)
			if normFact ~= "" and normFact ~= record.Normalized then
				-- If the evidence details directly conflict with the statement
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
