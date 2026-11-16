local Verdict = {}

function Verdict.Calculate(votes, required)
	local guilty, notGuilty = 0, 0
	for _, vote in pairs(votes) do
		if vote == "GUILTY" then
			guilty += 1
		elseif vote == "NOT_GUILTY" then
			notGuilty += 1
		end
	end
	local valid = guilty + notGuilty
	if valid == 0 then
		return "NOT_GUILTY", guilty, notGuilty
	end
	if guilty == notGuilty and required then
		return "TIE", guilty, notGuilty
	end
	return guilty > notGuilty and "GUILTY" or "NOT_GUILTY", guilty, notGuilty
end

return Verdict
