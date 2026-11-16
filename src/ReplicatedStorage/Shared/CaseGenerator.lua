local CaseGenerator = {}

local crimes = {
	{ Crime = "stealing 500 kilograms of invisible cheese", Object = "invisible cheese", Motive = "a suspicious lactose-related prophecy" },
	{ Crime = "eating the moon", Object = "the moon", Motive = "a midnight snack gone celestial" },
	{ Crime = "robbing a toilet", Object = "a porcelain throne", Motive = "revenge for a bad flush" },
	{ Crime = "stealing another player's Wi-Fi", Object = "a neighbor's signal", Motive = "an urgent need for faster memes" },
	{ Crime = "illegal dancing in public", Object = "the courtroom floor", Motive = "an unstoppable bassline" },
	{ Crime = "replacing everyone's brain with spaghetti", Object = "the collective noodle supply", Motive = "a very carb-heavy conspiracy" },
	{ Crime = "destroying the universe using a banana", Object = "a cosmically ripe banana", Motive = "proving fruit can be powerful" },
	{ Crime = "stealing a Lamborghini made of bread", Object = "the loaf-mobile", Motive = "a gluten-fueled getaway" },
}

local evidence = {
	{ Name = "Suspicious Banana", Detail = "It has a tiny fingerprint and an even tinier alibi.", Reliable = false },
	{ Name = "Blurry Security Screenshot", Detail = "A silhouette appears to be doing the worm at 3:04 AM.", Reliable = false },
	{ Name = "Fake Receipt", Detail = "One kilogram of moon listed as a breakfast item.", Reliable = false },
	{ Name = "Mysterious Footprint", Detail = "The print is shaped like a screaming star.", Reliable = true },
	{ Name = "Recorded Voice Message", Detail = "A voice whispers: 'I regret nothing, probably.'", Reliable = true },
	{ Name = "Witness Napkin Diagram", Detail = "It depicts a potato, three arrows, and legal confidence.", Reliable = false },
	{ Name = "Official Court Sock", Detail = "Recovered from the scene. Smells like courtroom.", Reliable = true },
}

local personalities = {
	{ Name = "The Dramatic Poet", Lines = { "The truth is a slippery noodle!", "I saw everything, spiritually.", "Objection to reality!" } },
	{ Name = "The Forgetful One", Lines = { "I had a statement, but it walked away.", "Was I here?", "Wait, who is on trial?" } },
	{ Name = "The Overconfident Detective", Lines = { "Case closed. I have not investigated it.", "My instincts are 98% accurate.", "The evidence is evidence because I said so." } },
	{ Name = "The Accidental Self-Accuser", Lines = { "The defendant did it! Also, possibly me.", "I confess to being a witness.", "Please do not inspect my pockets." } },
	{ Name = "The Unrelated Storyteller", Lines = { "This reminds me of my battle with a toaster.", "When I was a young spoon...", "Anyway, the banana had excellent posture." } },
}

local function choose(list, random)
	return list[random:NextInteger(1, #list)]
end

function CaseGenerator.Create(random)
	local crime = choose(crimes, random)
	local selectedEvidence = {}
	local pool = table.clone(evidence)
	local count = random:NextInteger(3, 5)
	for _ = 1, count do
		local index = random:NextInteger(1, #pool)
		table.insert(selectedEvidence, table.remove(pool, index))
	end
	local witnesses = {}
	for _ = 1, 2 do
		table.insert(witnesses, choose(personalities, random))
	end
	return {
		Id = string.format("CASE-%d-%d", os.time(), random:NextInteger(100, 999)),
		Crime = crime.Crime,
		Object = crime.Object,
		Motive = crime.Motive,
		Briefing = string.format("The accused allegedly committed the crime of %s. The prosecution claims the motive was %s.", crime.Crime, crime.Motive),
		Evidence = selectedEvidence,
		Witnesses = witnesses,
	}
end

return CaseGenerator
