local Config = {
	Name = "BRAINROT COURTROOM: THE FINAL VERDICT",
	MinPlayers = 2,
	TargetPlayers = 8,
	Round = {
		IntermissionSeconds = 15,
		BriefingSeconds = 10,
		TrialSeconds = 150,
		VotingSeconds = 25,
		VerdictSeconds = 12,
		ChaosMinimumSeconds = 30,
		ChaosMaximumSeconds = 60,
	},
	Rewards = {
		Participation = 25,
		Winner = 80,
		Conviction = 45,
		Defender = 55,
		BestLawyer = 35,
		Daily = 150,
	},
	RoleOrder = { "Judge", "Prosecutor", "Defense", "Defendant", "Witness", "Witness", "Jury" },
	Colors = {
		Ink = Color3.fromRGB(28, 22, 43),
		Cream = Color3.fromRGB(255, 242, 205),
		Pink = Color3.fromRGB(255, 105, 180),
		Cyan = Color3.fromRGB(72, 224, 214),
		Yellow = Color3.fromRGB(255, 210, 77),
		Red = Color3.fromRGB(255, 91, 91),
		Green = Color3.fromRGB(102, 224, 129),
	},
}

return Config
