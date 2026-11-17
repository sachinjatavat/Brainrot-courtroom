local CaseGenerator = {}

local crimes = {
	{
		Crime = "stealing the moon to make an oversized lamp",
		Object = "the moon",
		Motive = "a severe fear of the dark",
		Truth = {
			LOCATION = "Observatory Roof Garden",
			TIME = "3:15 AM",
			OBJECT = "The celestial moon sphere",
			ACTION = "Unbolting the moon with a giant monkey wrench",
		},
	},
	{
		Crime = "eating 500 bananas during a quiet funeral",
		Object = "500 ripe bananas",
		Motive = "an uncontrollable potassium deficiency",
		Truth = {
			LOCATION = "Peaceful Slumber Chapel",
			TIME = "1:45 PM",
			OBJECT = "A massive crate of yellow bananas",
			ACTION = "Inhaling forty bananas per minute in the front row",
		},
	},
	{
		Crime = "robbing a golden toilet from the Pentagon",
		Object = "a 24-karat porcelain throne",
		Motive = "a quest for supreme bathroom comfort",
		Truth = {
			LOCATION = "Pentagon Sub-Basement 4",
			TIME = "11:59 PM",
			OBJECT = "A glowing 24k solid gold commode",
			ACTION = "Wheeling the toilet down hallway B on a stolen skateboard",
		},
	},
	{
		Crime = "stealing all the courtroom's Wi-Fi passwords",
		Object = "the local router credentials",
		Motive = "an urgent urge to download TikToks",
		Truth = {
			LOCATION = "Courtroom IT Server Closet",
			TIME = "8:30 AM",
			OBJECT = "A laminated sticky note with the admin passwords",
			ACTION = "Plugging a suspicious neon thumb drive into the mainframe",
		},
	},
	{
		Crime = "destroying the universe using a plastic spoon",
		Object = "a bendy soup spoon",
		Motive = "trying to prove cutlery has omnipotent power",
		Truth = {
			LOCATION = "Cosmic Food Court",
			TIME = "5:00 PM",
			OBJECT = "A translucent plastic bendy spoon",
			ACTION = "Stirring the spacetime continuum clockwise",
		},
	},
	{
		Crime = "illegal competitive breakdancing in a sacred library",
		Object = "the forbidden dance floor",
		Motive = "the beat dropped and could not be ignored",
		Truth = {
			LOCATION = "Grand Historical Library Silence Chamber",
			TIME = "2:20 AM",
			OBJECT = "Cardboard dancing sheet and boombox",
			ACTION = "Headspinning across ancient manuscripts",
		},
	},
	{
		Crime = "stealing an invisible Lamborghini made of stale sourdough",
		Object = "the stealth loaf-mobile",
		Motive = "a high-speed gluten getaway",
		Truth = {
			LOCATION = "Artisan Bakery Underground Garage",
			TIME = "4:10 AM",
			OBJECT = "An odorless crusty sourdough vehicle",
			ACTION = "Revving an invisible engine made of yeast",
		},
	},
}

local evidencePool = {
	{ Name = "Suspicious Banana Peel", Topic = "OBJECT", Detail = "Found at the crime scene. Matches the defendant's tooth gap.", Fact = "A massive crate of yellow bananas", Reliable = true },
	{ Name = "CCTV Timestamp Log", Topic = "TIME", Detail = "Official high-security digital clock stamping exact occurrence.", Fact = "3:15 AM", Reliable = true },
	{ Name = "Security Checkpoint Badge Log", Topic = "LOCATION", Detail = "Keycard swipe records entry at the exact restricted sector.", Fact = "Observatory Roof Garden", Reliable = true },
	{ Name = "Blurry Security CCTV Screenshot", Topic = "ACTION", Detail = "Shows a shadowy silhouette doing the Macarena at an unknown hour.", Fact = "Doing the Macarena", Reliable = false },
	{ Name = "Fake Grocery Receipt", Topic = "OBJECT", Detail = "Lists '1x Moon (Discounted)' and swamp water.", Fact = "A carton of swamp milk", Reliable = false },
	{ Name = "Luminescent Sock", Topic = "OBJECT", Detail = "Smells like parmesan and radioactive dust. Tested positive for moon residue.", Fact = "The celestial moon sphere", Reliable = true },
	{ Name = "Recorded Voicemail", Topic = "ACTION", Detail = "A panicked voice whispers: 'Bro, hide the wrench, they are onto us.'", Fact = "Unbolting the moon with a giant monkey wrench", Reliable = true },
	{ Name = "Witness Napkin Doodles", Topic = "LOCATION", Detail = "Depicts a potato wielding a gavel in an imaginary playground.", Fact = "Fantasy potato island", Reliable = false },
	{ Name = "Bent Metal Spoon", Topic = "OBJECT", Detail = "Possesses cosmic gravitational distortion when placed near tea.", Fact = "A translucent plastic bendy spoon", Reliable = true },
	{ Name = "Cracked Wi-Fi Antenna", Topic = "OBJECT", Detail = "Warm to the touch and covered in greasy nacho cheese fingerprints.", Fact = "A laminated sticky note with the admin passwords", Reliable = true },
	{ Name = "Discarded Duck Call Whistle", Topic = "ACTION", Detail = "Yellow plastic whistle smelling strongly of pond algae.", Fact = "Quacking at seagulls", Reliable = false },
}

local witnessArchetypes = {
	{
		Name = "The Dramatic Opera Singer",
		Truthfulness = 0.85,
		Lines = {
			"The tragedy unfolds before my very eyes!",
			"I beheld the crime through tears of artistic passion!",
			"The defendant's guilt vibrates at forty thousand Hertz!",
		},
	},
	{
		Name = "The Forgetful Amnesiac",
		Truthfulness = 0.55,
		Lines = {
			"I swear I remember something... wait, what was the question?",
			"I thought the defendant was my third-grade teacher.",
			"Did I leave my oven on in 2014?",
		},
	},
	{
		Name = "The 200 IQ Detective",
		Truthfulness = 0.90,
		Lines = {
			"My deductions are mathematically incontrovertible.",
			"The trajectory indicates premeditated mischief.",
			"Elementary, my dear jury: the accused is clearly cooked.",
		},
	},
	{
		Name = "The Accidental Accomplice",
		Truthfulness = 0.50,
		Lines = {
			"I am completely innocent! Ignore the bag under my coat.",
			"The defendant forced me into this, allegedly!",
			"Can I please plead the fifth and sixth amendments?",
		},
	},
}

local TOPIC_QUESTIONS = {
	LOCATION = "Where were you located when the crime occurred?",
	TIME = "What time did you witness the event take place?",
	OBJECT = "What specific item or weapon was in the defendant's possession?",
	ACTION = "What action did you observe the defendant committing?",
}

local FABRICATIONS = {
	LOCATION = { "At the Ohio Walmart parking lot", "In a submarine beneath Lake Michigan", "Hiding behind an IKEA wardrobe" },
	TIME = { "High noon at 12:00 PM sharp", "At dusk around 7:45 PM", "During breakfast at 9:00 AM" },
	OBJECT = { "A soggy pool noodle", "A half-eaten corn dog", "A counterfeit Pokemon card" },
	ACTION = { "Practicing parallel parking", "Knitting a festive holiday sweater", "Singing karaoke to 80s rock" },
}

local function choose(list, random)
	return list[random:NextInteger(1, #list)]
end

function CaseGenerator.Create(random)
	random = random or Random.new()
	local crime = choose(crimes, random)
	local truth = crime.Truth

	-- Select 3 to 5 unique pieces of evidence
	local selectedEvidence = {}
	local pool = table.clone(evidencePool)
	local count = random:NextInteger(3, 5)
	for _ = 1, count do
		local index = random:NextInteger(1, #pool)
		local ev = table.clone(table.remove(pool, index))
		-- Tailor reliable evidence to current case truth if topic matches
		if ev.Reliable and truth[ev.Topic] then
			ev.Fact = truth[ev.Topic]
		end
		table.insert(selectedEvidence, ev)
	end

	-- Build 2 to 3 witnesses with structured, consistent stories on all topics
	local witnesses = {}
	local witnessCount = random:NextInteger(2, 3)
	local archPool = table.clone(witnessArchetypes)

	for index = 1, witnessCount do
		local arch = archPool[#archPool > 0 and random:NextInteger(1, #archPool) or 1]
		if #archPool > 0 then table.remove(archPool, table.find(archPool, arch) or 1) end

		local isLiar = random:NextNumber() > arch.Truthfulness
		local witness = {
			Id = "WITNESS_" .. tostring(index),
			Name = arch.Name,
			Truthfulness = arch.Truthfulness,
			Lie = isLiar,
			Lines = table.clone(arch.Lines),
			Topics = {},
			TopicList = { "LOCATION", "TIME", "OBJECT", "ACTION" },
		}

		-- Which topic does the liar fabricate? (1 specific topic, rest truthful to maintain realistic testimony)
		local lieTopic = isLiar and witness.TopicList[random:NextInteger(1, #witness.TopicList)] or nil

		for _, topic in ipairs(witness.TopicList) do
			local stmt
			if isLiar and topic == lieTopic then
				local fabList = FABRICATIONS[topic]
				stmt = fabList[random:NextInteger(1, #fabList)]
			else
				stmt = truth[topic] or "I observed the event clearly."
			end

			witness.Topics[topic] = {
				Question = TOPIC_QUESTIONS[topic],
				Statement = stmt,
			}
		end

		table.insert(witnesses, witness)
	end

	return {
		Id = string.format("CASE-%d-%d", os.time(), random:NextInteger(100, 999)),
		Crime = crime.Crime,
		Object = crime.Object,
		Motive = crime.Motive,
		Truth = truth,
		Briefing = string.format("The accused allegedly committed the crime of %s. Motive: %s.", crime.Crime, crime.Motive),
		Evidence = selectedEvidence,
		Witnesses = witnesses,
	}
end

return CaseGenerator
