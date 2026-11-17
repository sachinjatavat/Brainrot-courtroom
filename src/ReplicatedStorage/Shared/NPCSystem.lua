local NPCSystem = {}

NPCSystem.Personalities = {
	Calm = { Reaction = "observes carefully", Bias = 0.5 },
	Drama = { Reaction = "gasps dramatically over the objection", Bias = 0.7 },
	Skeptic = { Reaction = "crosses arms and demands hard proof", Bias = 0.3 },
	Excited = { Reaction = "takes enthusiastic notes", Bias = 0.6 },
}

NPCSystem.SpectatorNames = {
	"Auntie Karen from Ohio", "Sigma Observer", "Anonymous Juror in Disguise",
	"Law Student with Overdue Tuition", "Local Pigeon Enthusiast",
	"Conspiracy Theorist with Tinfoil Hat", "Bystander Who Wanted Free Air Conditioning",
}

function NPCSystem.CreateSecurity(index)
	return {
		Id = "SECURITY_" .. tostring(index),
		Name = "Officer " .. (index == 1 and "Flapjack" or "Ironclad"),
		Role = "Security",
		Personality = index % 2 == 0 and "Skeptic" or "Calm",
	}
end

-- BUG 4 FIX: Functional Humanoid Security Guard Model with proper joints, uniform, and badge
function NPCSystem.CreateSecurityModel(index, spawnPosition)
	local name = "Officer " .. (index == 1 and "Flapjack" or "Ironclad")
	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = false
	root.Position = spawnPosition or Vector3.new(-40 + index * 6, 3.5, -28)
	root.Parent = model
	model.PrimaryPart = root

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(24, 34, 64) -- Police Navy
	torso.Material = Enum.Material.SmoothPlastic
	torso.CanCollide = true
	torso.Anchored = false
	torso.CFrame = root.CFrame
	torso.Parent = model

	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Part0 = root
	rootJoint.Part1 = torso
	rootJoint.Parent = root

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = Color3.fromRGB(225, 190, 155)
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = true
	head.Anchored = false
	head.CFrame = torso.CFrame * CFrame.new(0, 1.6, 0)
	head.Parent = model

	local neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.Part0 = torso
	neck.Part1 = head
	neck.C0 = CFrame.new(0, 1, 0)
	neck.C1 = CFrame.new(0, -0.6, 0)
	neck.Parent = torso

	local function createLimb(limbName, size, offset, color)
		local limb = Instance.new("Part")
		limb.Name = limbName
		limb.Size = size
		limb.Color = color
		limb.Material = Enum.Material.SmoothPlastic
		limb.CanCollide = false
		limb.Anchored = false
		limb.CFrame = torso.CFrame * offset
		limb.Parent = model

		local motor = Instance.new("Motor6D")
		motor.Name = limbName
		motor.Part0 = torso
		motor.Part1 = limb
		motor.C0 = offset
		motor.Parent = torso
		return limb
	end

	createLimb("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0), Color3.fromRGB(24, 34, 64))
	createLimb("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0), Color3.fromRGB(24, 34, 64))
	createLimb("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0), Color3.fromRGB(20, 20, 26))
	createLimb("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0), Color3.fromRGB(20, 20, 26))

	-- Gold Officer Badge
	local badge = Instance.new("Part")
	badge.Name = "OfficerBadge"
	badge.Size = Vector3.new(0.5, 0.5, 0.1)
	badge.Color = Color3.fromRGB(255, 215, 0)
	badge.Material = Enum.Material.Neon
	badge.CanCollide = false
	badge.Anchored = false
	badge.CFrame = torso.CFrame * CFrame.new(0.4, 0.4, -0.55)
	badge.Parent = model

	local badgeWeld = Instance.new("WeldConstraint")
	badgeWeld.Part0 = torso
	badgeWeld.Part1 = badge
	badgeWeld.Parent = badge

	-- Security Officer Cap
	local cap = Instance.new("Part")
	cap.Name = "OfficerCap"
	cap.Size = Vector3.new(1.4, 0.4, 1.4)
	cap.Color = Color3.fromRGB(18, 26, 48)
	cap.Material = Enum.Material.SmoothPlastic
	cap.CanCollide = false
	cap.Anchored = false
	cap.CFrame = head.CFrame * CFrame.new(0, 0.7, 0)
	cap.Parent = model

	local capWeld = Instance.new("WeldConstraint")
	capWeld.Part0 = head
	capWeld.Part1 = cap
	capWeld.Parent = cap

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 12
	humanoid.DisplayName = name .. " (Security)"
	humanoid.Parent = model

	return model
end

-- BUG 4 FIX: Safe Humanoid Escort Sequence with disconnect & missing character fallback
function NPCSystem.EscortToJail(guardModels, defendantPlayer, jailPosition, onComplete)
	jailPosition = jailPosition or Vector3.new(0, 3, 40)
	local defaultStandPos = Vector3.new(0, 3, -15)

	task.spawn(function()
		local targetPos = defaultStandPos
		local defChar = defendantPlayer and defendantPlayer.Character
		if defChar and defChar.PrimaryPart then
			targetPos = defChar.PrimaryPart.Position
		end

		-- Phase 1: Guards approach the defendant stand
		for _, guard in ipairs(guardModels) do
			if guard and guard:FindFirstChild("Humanoid") and guard.PrimaryPart then
				pcall(function()
					guard.Humanoid:MoveTo(targetPos + Vector3.new(guard.Name:find("Flapjack") and -3 or 3, 0, 0))
				end)
			end
		end

		task.wait(2)

		-- Phase 2: Escort to Jail
		-- Check if defendant is still connected / has character
		local defValid = defendantPlayer and defendantPlayer.Parent and defendantPlayer.Character and defendantPlayer.Character.PrimaryPart
		if defValid then
			pcall(function()
				local defHum = defendantPlayer.Character:FindFirstChild("Humanoid")
				if defHum then defHum.WalkSpeed = 8 end
				defendantPlayer.Character:PivotTo(CFrame.new(targetPos, jailPosition))
			end)
		end

		-- Move guards to jail
		for _, guard in ipairs(guardModels) do
			if guard and guard:FindFirstChild("Humanoid") and guard.PrimaryPart then
				pcall(function()
					guard.Humanoid:MoveTo(jailPosition + Vector3.new(guard.Name:find("Flapjack") and -3 or 3, 0, -2))
				end)
			end
		end

		task.wait(2.5)

		-- Phase 3: Lock defendant into jail cell
		if defendantPlayer and defendantPlayer.Parent and defendantPlayer.Character then
			pcall(function()
				defendantPlayer.Character:PivotTo(CFrame.new(jailPosition + Vector3.new(0, 1, 0)))
			end)
		end

		if onComplete then
			pcall(onComplete)
		end
	end)
end

function NPCSystem.CreateBotWitness(index, random)
	random = random or Random.new()
	local personalities = { "Calm", "Drama", "Skeptic", "Excited" }
	local personality = personalities[random:NextInteger(1, #personalities)]
	return {
		Id = "BOT_WITNESS_" .. tostring(index),
		Name = "AI Witness #" .. tostring(index),
		Personality = personality,
		Truthfulness = (personality == "Skeptic" and 0.75) or (personality == "Drama" and 0.60) or 0.90,
		Bot = true,
		Lines = {
			"I observed the incident from a safe distance of exactly 42 studs.",
			"My sensory data indicates unusual potassium activity.",
			"The suspect made a suspicious gesture before disappearing.",
			"I require further forensic substantiation.",
		},
		Topics = {
			LOCATION = { Question = "Where were you?", Statement = "In the observation bay, 42 studs away." },
			TIME = { Question = "What time?", Statement = "At 3:15 AM precisely." },
			OBJECT = { Question = "What object?", Statement = "A suspicious yellow crescent specimen." },
			ACTION = { Question = "What action?", Statement = "Suspicious gestures followed by rapid departure." },
		},
		TopicList = { "LOCATION", "TIME", "OBJECT", "ACTION" },
	}
end

function NPCSystem.CreateBotLawyer(role, random)
	random = random or Random.new()
	local names = (role == "Prosecutor")
		and { "Miles Edgeworth Jr.", "Prosecutor Steel", "Sigma Attorney Payne" }
		or { "Phoenix Wright-Hand", "Public Defender Bob", "Legal Eagle Saul" }
	local name = names[random:NextInteger(1, #names)]

	local arguments = (role == "Prosecutor") and {
		"The exhibit clearly proves malicious intent and cosmic disregard for law!",
		"Witness testimony establishes a timeline that leaves zero room for doubt!",
		"Fingerprints found on the banana correlate 99.8% with the accused!",
		"The defendant's sudden panic is an undeniable confession of guilt!",
	} or {
		"The prosecution's timeline is riddled with glaring contradictions!",
		"Reasonable doubt is evident: the sock could belong to anyone with feet!",
		"My client was in a completely different dimension at the time of the heist!",
		"The witness statement violates basic laws of culinary physics!",
	}

	return {
		Id = "BOT_" .. role:upper(),
		Name = name,
		Role = role,
		Bot = true,
		Arguments = arguments,
	}
end

function NPCSystem.CreateBotDefendant(random)
	random = random or Random.new()
	local names = { "Suspect Skibidi", "Noob The Accused", "Glitch McPixel", "Ohio Suspect 404" }
	local statements = {
		"I was just looking for a snack, I swear on my mother's Wi-Fi router!",
		"It was a complete misunderstanding, the golden toilet tripped and fell into my hands!",
		"I have never even seen a moon in my entire life, Your Honor!",
		"My twin brother from another multiverse did it, not me!",
	}
	return {
		Id = "BOT_DEFENDANT",
		Name = names[random:NextInteger(1, #names)],
		Role = "Defendant",
		Bot = true,
		Statements = statements,
	}
end

function NPCSystem.CreateSpectators(count, random)
	random = random or Random.new()
	local roster = {}
	for i = 1, count or 6 do
		local name = NPCSystem.SpectatorNames[((i - 1) % #NPCSystem.SpectatorNames) + 1]
		table.insert(roster, {
			Id = "SPECTATOR_" .. tostring(i),
			Name = name,
			SeatIndex = i,
		})
	end
	return roster
end

function NPCSystem.EvaluateBotVote(argumentScores, activeEvidence, random)
	random = random or Random.new()
	local pScore = argumentScores and argumentScores.Prosecutor or 0
	local dScore = argumentScores and argumentScores.Defense or 0

	local guiltyChance = 0.50
	local scoreDiff = pScore - dScore
	guiltyChance = math.clamp(guiltyChance + (scoreDiff * 0.05), 0.15, 0.85)

	if activeEvidence and activeEvidence.Reliable then
		guiltyChance = math.clamp(guiltyChance + 0.15, 0.15, 0.90)
	end

	return (random:NextNumber() < guiltyChance) and "GUILTY" or "NOT_GUILTY"
end

return NPCSystem
