local PerformanceSettings = {}

PerformanceSettings.Presets = {
	Low = {
		CastShadows = false,
		EnableParticles = false,
		MaxAuraDistance = 40,
		SmoothSurfaces = true,
		DisableDecorations = true,
	},
	High = {
		CastShadows = true,
		EnableParticles = true,
		MaxAuraDistance = 150,
		SmoothSurfaces = false,
		DisableDecorations = false,
	},
}

function PerformanceSettings.Apply(mode, targetRoot)
	local preset = PerformanceSettings.Presets[mode] or PerformanceSettings.Presets.High
	targetRoot = targetRoot or workspace

	for _, item in ipairs(targetRoot:GetDescendants()) do
		if item:IsA("BasePart") then
			if preset.CastShadows == false then
				item.CastShadow = false
			end
			if preset.SmoothSurfaces and (item.Material == Enum.Material.Cobblestone or item.Material == Enum.Material.DiamondPlate) then
				item.Material = Enum.Material.SmoothPlastic
			end
		elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") then
			item.Enabled = preset.EnableParticles
		end
	end
end

return PerformanceSettings
