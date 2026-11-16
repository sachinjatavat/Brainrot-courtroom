local Verdict = {}

function Verdict.Calculate(votes, required, argumentScores)
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
	local argumentDifference = (argumentScores and argumentScores.Prosecutor or 0) - (argumentScores and argumentScores.Defense or 0)
	if guilty == notGuilty and required then
		if argumentDifference >= 3 then return "GUILTY", guilty, notGuilty end
		if argumentDifference <= -3 then return "NOT_GUILTY", guilty, notGuilty end
		return "TIE", guilty, notGuilty
	end
	if guilty == notGuilty then return "NOT_GUILTY", guilty, notGuilty end
	if guilty > notGuilty and argumentDifference <= -5 then return "NOT_GUILTY", guilty, notGuilty end
	if notGuilty > guilty and argumentDifference >= 5 then return "GUILTY", guilty, notGuilty end
	return guilty > notGuilty and "GUILTY" or "NOT_GUILTY", guilty, notGuilty
end

return Verdict
