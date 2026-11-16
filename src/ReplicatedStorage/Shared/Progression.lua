local Progression = {}

Progression.DailyMissions = {
	{
		Id = "PLAY_TRIALS",
		Title = "Civic Duty",
		Description = "Participate in 2 complete trials.",
		Target = 2,
		RewardCoins = 150,
		RewardXP = 60,
	},
	{
		Id = "WIN_VERDICT",
		Title = "Master of Justice",
		Description = "Win 1 trial as Prosecutor, Defense, or Defendant.",
		Target = 1,
		RewardCoins = 200,
		RewardXP = 80,
	},
	{
		Id = "PRESENT_EVIDENCE",
		Title = "Exhibit A",
		Description = "Present evidence 2 times during a trial.",
		Target = 2,
		RewardCoins = 120,
		RewardXP = 45,
	},
	{
		Id = "CAST_VOTES",
		Title = "Voice of the People",
		Description = "Cast 2 jury votes in verdict phases.",
		Target = 2,
		RewardCoins = 120,
		RewardXP = 45,
	},
	{
		Id = "SUBMIT_ARGUMENTS",
		Title = "Silver Tongue",
		Description = "Submit 2 arguments as a lawyer.",
		Target = 2,
		RewardCoins = 140,
		RewardXP = 50,
	},
	{
		Id = "JUDGE_POWERS",
		Title = "Absolute Power",
		Description = "Use 2 Judge powers to maintain order.",
		Target = 2,
		RewardCoins = 160,
		RewardXP = 55,
	},
}

Progression.Achievements = {
	{
		Id = "FIRST_TRIAL",
		Title = "First Day in Court",
		Description = "Complete your very first trial.",
		Target = 1,
		RewardCoins = 100,
		RewardXP = 50,
		RewardTitle = "Rookie Juror",
	},
	{
		Id = "WIN_5_TRIALS",
		Title = "Legal Eagle",
		Description = "Win 5 trials as Defense or Prosecutor.",
		Target = 5,
		RewardCoins = 500,
		RewardXP = 200,
		RewardTitle = "Sigma Attorney",
	},
	{
		Id = "ORDER_KEEPER",
		Title = "Order in the Court",
		Description = "Complete 3 trials as the Judge.",
		Target = 3,
		RewardCoins = 350,
		RewardXP = 150,
		RewardTitle = "Supreme Justice",
	},
	{
		Id = "CONTRADICTION_HUNTER",
		Title = "Cap Detector",
		Description = "Detect 3 witness contradictions.",
		Target = 3,
		RewardCoins = 400,
		RewardXP = 180,
		RewardTitle = "Cap Detector",
	},
	{
		Id = "DRIP_CHECK",
		Title = "Brainrot Stylist",
		Description = "Unlock 3 cosmetics from the shop.",
		Target = 3,
		RewardCoins = 300,
		RewardXP = 120,
		RewardTitle = "Ohio Menace",
	},
}

function Progression.GetMissionsForDay(dayNumber)
	-- Returns 3 deterministic daily missions for the day
	local total = #Progression.DailyMissions
	local offset = (dayNumber or 0) % total
	local missions = {}
	for i = 1, 3 do
		local idx = ((offset + i - 1) % total) + 1
		table.insert(missions, Progression.DailyMissions[idx])
	end
	return missions
end

function Progression.GetMission(id)
	for _, m in ipairs(Progression.DailyMissions) do
		if m.Id == id then return m end
	end
	return nil
end

function Progression.GetAchievement(id)
	for _, a in ipairs(Progression.Achievements) do
		if a.Id == id then return a end
	end
	return nil
end

function Progression.GetLevel(xp)
	return math.max(1, math.floor((xp or 0) / 250) + 1)
end

function Progression.GetNextLevelXP(level)
	return level * 250
end

return Progression
