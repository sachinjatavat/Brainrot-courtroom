local ArgumentScoring = {}

local function contains(text, value)
	return string.find(string.lower(tostring(text)), string.lower(tostring(value or "")), 1, true) ~= nil
end

function ArgumentScoring.Evaluate(text, side, caseData, witnessMemories, presentedEvidence)
	local argument = tostring(text or "")
	local score = 0
	local reasons = {}
	local evidenceHits = 0
	for index, evidence in ipairs(caseData.Evidence or {}) do
		if contains(argument, evidence.Name) or contains(argument, "evidence " .. index) or contains(argument, evidence.Object) then
			evidenceHits += 1
			score += evidence.Reliable and 3 or -2
			table.insert(reasons, evidence.Reliable and "relevant genuine evidence" or "misleading evidence")
		end
	end
	if contains(argument, "contradiction") or contains(argument, "changed their story") then
		local contradictionCount = 0
		for _, memory in pairs(witnessMemories or {}) do
			contradictionCount += #(memory.Contradictions or {})
		end
		score += contradictionCount > 0 and math.min(6, contradictionCount * 2) or -1
		table.insert(reasons, contradictionCount > 0 and "exposed testimony contradiction" or "unsupported contradiction claim")
	end
	if contains(argument, "consistent") or contains(argument, "matches testimony") then
		score += 2
		table.insert(reasons, "testimony consistency")
	end
	if side == "Defense" and contains(argument, "reasonable doubt") then
		score += 2
		table.insert(reasons, "reasonable doubt")
	elseif side == "Prosecutor" and (contains(argument, "motive") or contains(argument, "guilty")) then
		score += 1
		table.insert(reasons, "case theory")
	end
	if presentedEvidence and evidenceHits == 0 then
		score -= 1
	end
	return {
		Side = side,
		Text = argument,
		Score = score,
		Reasons = reasons,
	}
end

return ArgumentScoring
