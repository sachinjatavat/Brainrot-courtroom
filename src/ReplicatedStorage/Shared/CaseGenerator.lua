local CaseGenerator = {}

local crimes = {
	{ Crime = "stealing the moon to make an oversized lamp", Object = "the moon", Motive = "a severe fear of the dark" },
	{ Crime = "eating 500 bananas during a quiet funeral", Object = "500 ripe bananas", Motive = "an uncontrollable potassium deficiency" },
	{ Crime = "robbing a golden toilet from the Pentagon", Object = "a 24-karat porcelain throne", Motive = "a quest for supreme bathroom comfort" },
	{ Crime = "stealing all the courtroom's Wi-Fi passwords", Object = "the local router credentials", Motive = "an urgent urge to download TikToks" },
	{ Crime = "destroying the universe using a plastic spoon", Object = "a bendy soup spoon", Motive = "trying to prove cutlery has omnipotent power" },
	{ Crime = "illegal competitive breakdancing in a sacred library", Object = "the forbidden dance floor", Motive = "the beat dropped and could not be ignored" },
	{ Crime = "stealing an invisible Lamborghini made of stale sourdough", Object = "the stealth loaf-mobile", Motive = "a high-speed gluten getaway" },
	{ Crime = "replacing the entire jury's brains with wet macaroni", Object = "three boxes of elbow pasta", Motive = "an extreme culinary conspiracy" },
	{ Crime = "hacking the Judge's soundboard to play Vine thuds", Object = "the judicial audio mixer", Motive = "comedic timing was deemed mandatory" },
	{ Crime = "summoning an Ohio demon using expired milk", Object = "a carton of 2% dairy", Motive = "curiosity about regional folklore" },
	{ Crime = "stealing the courtroom clock to extend lunch break", Object = "the brass wall clock", Motive = "a craving for 4-hour naps" },
	{ Crime = "selling counterfeit rizz insurance without a license", Object = "fake policy certificates", Motive = "unadulterated financial greed" },
	{ Crime = "downloading an entire car over 3G cellular data", Object = "a virtual sedan", Motive = "the pirate slogan said 'you wouldn't'" },
	{ Crime = "filling the holding cell with 10,000 plastic ducks", Object = "ten thousand squeaking waterfowl", Motive = "artistic expression of existential dread" },
}

local evidence = {
	{ Name = "Suspicious Banana Peel", Detail = "Found at the crime scene. Has a tiny bite mark matching the defendant's tooth gap.", Reliable = true },
	{ Name = "Blurry Security CCTV Screenshot", Detail = "Shows a shadowy silhouette doing the Macarena at 3:17 AM.", Reliable = false },
	{ Name = "Fake Grocery Receipt", Detail = "Lists '1x Moon (Discounted)' and 'Three gallons of Ohio swamp water'.", Reliable = false },
	{ Name = "Luminescent Sock", Detail = "Smells like parmesan and radioactive dust. Tested positive for moon residue.", Reliable = true },
	{ Name = "Recorded Voicemail", Detail = "A panicked voice whispers: 'Bro, hide the spoon, they are onto us.'", Reliable = true },
	{ Name = "Witness Napkin Doodles", Detail = "Depicts a potato wielding a gavel, with arrows pointing directly at the defendant.", Reliable = false },
	{ Name = "Bent Metal Spoon", Detail = "Possesses cosmic gravitational distortion when placed near tea.", Reliable = true },
	{ Name = "Stale Baguette Steering Wheel", Detail = "Crumbly evidence recovered from an invisible garage.", Reliable = false },
	{ Name = "Unlabeled USB Thumb Drive", Detail = "Contains 40 gigabytes of low-resolution dancing cat videos.", Reliable = false },
	{ Name = "Confidential Diary Entry", Detail = "Reads: 'Today I shall commit the ultimate heist, nobody will suspect my rizz.'", Reliable = true },
	{ Name = "Cracked Wi-Fi Antenna", Detail = "Warm to the touch and covered in greasy nacho cheese fingerprints.", Reliable = true },
	{ Name = "Discarded Duck Call Whistle", Detail = "Yellow plastic whistle smelling strongly of pond algae.", Reliable = false },
}

local personalities = {
	{
		Name = "The Dramatic Opera Singer",
		Truthfulness = 0.85,
		Story = { "saw a shimmering silhouette in the moonlight", "heard a high-pitched soprano scream" },
		Lines = {
			"The tragedy unfolds before my very eyes!",
			"I beheld the crime through tears of artistic passion!",
			"The defendant's guilt vibrates at forty thousand Hertz!",
			"Truth is but an aria floating on the winds of justice!",
		},
	},
	{
		Name = "The Forgetful Amnesiac",
		Truthfulness = 0.60,
		Story = { "was near the scene looking for lost keys", "confused the defendant with a potted fern" },
		Lines = {
			"I swear I remember something... wait, what was the question?",
			"I thought the defendant was my third-grade teacher.",
			"Did I leave my oven on in 2014?",
			"I saw a person, or perhaps three raccoons in a trench coat.",
		},
	},
	{
		Name = "The 200 IQ Detective",
		Truthfulness = 0.90,
		Story = { "observed dust trajectory and acoustic echoes", "deduced the exact motive within 0.4 seconds" },
		Lines = {
			"My deductions are mathematically incontrovertible.",
			"The angle of the banana peel indicates premeditated mischief.",
			"Elementary, my dear jury: the accused is clearly cooked.",
			"The circumstantial data aligns with ninety-nine percent probability.",
		},
	},
	{
		Name = "The Accidental Accomplice",
		Truthfulness = 0.50,
		Story = { "was accidentally holding the stolen loot", "panicked and hid behind a water cooler" },
		Lines = {
			"I am completely innocent! Ignore the bag of moon dust under my coat.",
			"The defendant forced me to eat thirty bananas, allegedly!",
			"Can I please plead the fifth, sixth, and seventh amendments?",
			"I was merely inspecting the security vault for structural flaws!",
		},
	},
	{
		Name = "The Ohio Mystic",
		Truthfulness = 0.70,
		Story = { "consulted tea leaves and swamp echoes", "sensed negative aura entering the building" },
		Lines = {
			"The ancient Ohio scriptures predicted this exact scandal.",
			"The defendant's aura is murky brown with patches of deceit.",
			"The toilet heist was written in the stars, Your Honor.",
			"Beware the fifth moon of Skibidi!",
		},
	},
	{
		Name = "The Overly Excited Intern",
		Truthfulness = 0.80,
		Story = { "was delivering cold coffees", "witnessed a frantic dash down the corridor" },
		Lines = {
			"OMG, this is my first trial! You guys are all so cool!",
			"I definitely saw someone sprint by carrying a giant spoon!",
			"Should I take notes or do an interpretive dance?",
			"The defendant looked super suspicious and dropped a napkin!",
		},
	},
}

local function choose(list, random)
	return list[random:NextInteger(1, #list)]
end

function CaseGenerator.Create(random)
	random = random or Random.new()
	local crime = choose(crimes, random)

	-- Select 3 to 5 unique pieces of evidence
	local selectedEvidence = {}
	local pool = table.clone(evidence)
	local count = random:NextInteger(3, 5)
	for _ = 1, count do
		local index = random:NextInteger(1, #pool)
		table.insert(selectedEvidence, table.remove(pool, index))
	end

	-- Select 2 to 3 witnesses with unique IDs and stories
	local witnesses = {}
	local witnessCount = random:NextInteger(2, 3)
	local persPool = table.clone(personalities)
	for index = 1, witnessCount do
		local pIndex = random:NextInteger(1, #persPool)
		local personality = table.clone(table.remove(persPool, pIndex) or choose(personalities, random))
		personality.Id = "WITNESS_" .. tostring(index)
		personality.Story = table.clone(personality.Story)
		personality.Lie = random:NextNumber() > personality.Truthfulness
		table.insert(witnesses, personality)
	end

	return {
		Id = string.format("CASE-%d-%d", os.time(), random:NextInteger(100, 999)),
		Crime = crime.Crime,
		Object = crime.Object,
		Motive = crime.Motive,
		Briefing = string.format("The accused allegedly committed the crime of %s. The prosecution asserts the motive was %s.", crime.Crime, crime.Motive),
		Evidence = selectedEvidence,
		Witnesses = witnesses,
	}
end

return CaseGenerator
