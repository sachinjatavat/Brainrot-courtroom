local SoundService = game:GetService("SoundService")

local AudioCatalog = {}

AudioCatalog.Sounds = {
	GavelSlam = {
		SoundId = "rbxasset://sounds/action_falling.mp3",
		Volume = 1.0,
		PlaybackSpeed = 1.6,
	},
	Objection = {
		SoundId = "rbxasset://sounds/bell.wav",
		Volume = 1.2,
		PlaybackSpeed = 0.9,
	},
	VerdictGuilty = {
		SoundId = "rbxasset://sounds/uproar.mp3",
		Volume = 1.1,
		PlaybackSpeed = 0.75,
	},
	VerdictNotGuilty = {
		SoundId = "rbxasset://sounds/electronicpingshort.wav",
		Volume = 1.0,
		PlaybackSpeed = 1.2,
	},
	CashEarned = {
		SoundId = "rbxasset://sounds/button.wav",
		Volume = 0.8,
		PlaybackSpeed = 1.8,
	},
	JailDoor = {
		SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
		Volume = 0.9,
		PlaybackSpeed = 0.6,
	},
	BananaSlip = {
		SoundId = "rbxasset://sounds/action_jump.mp3",
		Volume = 1.0,
		PlaybackSpeed = 1.5,
	},
	CountdownTick = {
		SoundId = "rbxasset://sounds/switch.wav",
		Volume = 0.5,
		PlaybackSpeed = 1.0,
	},
	EquipItem = {
		SoundId = "rbxasset://sounds/button.wav",
		Volume = 0.7,
		PlaybackSpeed = 1.4,
	},
}

function AudioCatalog.PlaySound(name, parent)
	local config = AudioCatalog.Sounds[name]
	if not config then return nil end

	local sound = Instance.new("Sound")
	sound.Name = "SFX_" .. name
	sound.SoundId = config.SoundId
	sound.Volume = config.Volume or 1
	sound.PlaybackSpeed = config.PlaybackSpeed or 1
	sound.RollOffMaxDistance = 150
	sound.Parent = parent or SoundService
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(6, function()
		if sound.Parent then sound:Destroy() end
	end)
	return sound
end

return AudioCatalog
