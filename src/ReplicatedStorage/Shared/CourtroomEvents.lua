local CourtroomEvents = {}

CourtroomEvents.Definitions = {
	GRAVITY_GLITCH = { Duration = 7, Gameplay = "Movement becomes unpredictable." },
	BANANA_FLOOD = { Duration = 7, Gameplay = "Bananas obstruct the courtroom." },
	EVERYONE_DANCES = { Duration = 7, Gameplay = "Players cannot keep still while testimony is taken." },
	JUDGE_TINY = { Duration = 7, Gameplay = "The judge is harder to see." },
	POSITION_SWAP = { Duration = 7, Gameplay = "Two courtroom positions are swapped." },
	VOICE_LOSS = { Duration = 7, Gameplay = "Witness answers are temporarily muted." },
	EVIDENCE_MIXUP = { Duration = 7, Gameplay = "The active evidence is shuffled; inspect it again." },
}

function CourtroomEvents.Get(name)
	return CourtroomEvents.Definitions[name]
end

function CourtroomEvents.IsValid(name)
	return CourtroomEvents.Definitions[name] ~= nil
end

return CourtroomEvents
