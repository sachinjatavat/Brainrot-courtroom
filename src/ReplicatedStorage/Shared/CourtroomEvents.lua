local CourtroomEvents = {}

CourtroomEvents.Definitions = {
	GRAVITY_GLITCH = { Duration = 8, Gameplay = "Cosmic anti-gravity active! Jump heights drastically increased." },
	BANANA_FLOOD = { Duration = 8, Gameplay = "Dozens of slippery bananas rain from the ceiling." },
	EVERYONE_DANCES = { Duration = 7, Gameplay = "Courtroom mandatory groove! Everyone breaks into a victory dance." },
	JUDGE_TINY = { Duration = 9, Gameplay = "The Judge shrinks to miniature size." },
	POSITION_SWAP = { Duration = 7, Gameplay = "Two players swap positions in the courtroom." },
	VOICE_LOSS = { Duration = 6, Gameplay = "Testimony is temporarily silenced under high static." },
	EVIDENCE_MIXUP = { Duration = 8, Gameplay = "Exhibits are scrambled! Re-examine evidence immediately." },
	COURTROOM_FLOOD = { Duration = 8, Gameplay = "Rising water fills the floor! Swim or climb the benches." },
	ROLE_SWAP = { Duration = 10, Gameplay = "CHAOS: Prosecutor and Defense must argue from opposing tables!" },
	BRAINROT_INVASION = { Duration = 8, Gameplay = "Bouncing neon orbs invade the chamber, knocking players back." },
	COURTROOM_EXPLOSION = { Duration = 5, Gameplay = "Dramatic explosion! Shockwaves and flying paperwork." },
}

function CourtroomEvents.Get(name)
	return CourtroomEvents.Definitions[name]
end

function CourtroomEvents.IsValid(name)
	return CourtroomEvents.Definitions[name] ~= nil
end

function CourtroomEvents.List()
	local list = {}
	for k, v in pairs(CourtroomEvents.Definitions) do
		table.insert(list, { Name = k, Duration = v.Duration, Gameplay = v.Gameplay })
	end
	return list
end

return CourtroomEvents
