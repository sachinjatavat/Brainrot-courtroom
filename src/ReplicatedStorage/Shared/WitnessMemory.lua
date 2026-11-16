local WitnessMemory = {}

local function normalize(value)
	return string.lower(string.gsub(tostring(value or ""), "%s+", " "))
end

function WitnessMemory.Create(witness, random)
	local memory = {
		WitnessId = witness.Id or witness.Name,
		Story = witness.Story or {},
		Truthfulness = witness.Truthfulness or 1,
		Lie = witness.Lie == true,
		Answers = {},
		Contradictions = {},
		QuestionCount = 0,
	}
	if memory.Truthfulness < 1 and random and random:NextNumber() > memory.Truthfulness then
		memory.Lie = true
	end
	return memory
end

function WitnessMemory.Record(memory, question, answer, evidenceId)
	assert(memory and type(memory.Answers) == "table", "invalid witness memory")
	local record = {
		Question = tostring(question),
		Answer = tostring(answer),
		NormalizedAnswer = normalize(answer),
		EvidenceId = evidenceId,
		Index = #memory.Answers + 1,
	}
	for _, previous in ipairs(memory.Answers) do
		if previous.NormalizedAnswer ~= record.NormalizedAnswer
			and (normalize(previous.Question) == normalize(question)
				or (evidenceId ~= nil and previous.EvidenceId == evidenceId)) then
			table.insert(memory.Contradictions, {
				First = previous,
				Second = record,
			})
			record.Contradicts = previous.Index
			break
		end
	end
	table.insert(memory.Answers, record)
	memory.QuestionCount += 1
	return record, record.Contradicts ~= nil
end

function WitnessMemory.DetectContradictions(memory)
	return memory and memory.Contradictions or {}
end

return WitnessMemory
