local EvidenceSystem = {}

function EvidenceSystem.Inspect(caseData, index)
	local evidence = caseData and caseData.Evidence and caseData.Evidence[index]
	if not evidence then return nil end
	return {
		Index = index,
		Name = evidence.Name,
		Detail = evidence.Detail,
		Reliable = evidence.Reliable == true,
		Misleading = evidence.Reliable ~= true,
	}
end

function EvidenceSystem.Present(caseData, index, presenter)
	local inspected = EvidenceSystem.Inspect(caseData, index)
	if not inspected then return nil end
	inspected.Presenter = presenter
	inspected.Presented = true
	return inspected
end

function EvidenceSystem.React(witness, evidence)
	if not evidence then return "The witness has no reaction." end
	if evidence.Misleading then
		return witness.Name .. " looks relieved and calls it misleading."
	end
	if witness.Lie then
		return witness.Name .. " becomes defensive when confronted with genuine evidence."
	end
	return witness.Name .. " confirms that the evidence fits their story."
end

return EvidenceSystem
