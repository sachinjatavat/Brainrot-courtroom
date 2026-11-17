local CosmeticsService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local CosmeticsCatalog = Shared.CosmeticsCatalog

local function createWeld(part0, part1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0 or CFrame.new()
	weld.Parent = part0
	return weld
end

function CosmeticsService.Clear(character)
	if not character then return end
	local oldGavel = character:FindFirstChild("EquippedGavel")
	if oldGavel then oldGavel:Destroy() end
	local oldCase = character:FindFirstChild("EquippedBriefcase")
	if oldCase then oldCase:Destroy() end
	local oldAura = character:FindFirstChild("EquippedAura")
	if oldAura then oldAura:Destroy() end
	local oldTitle = character:FindFirstChild("OverheadTitle")
	if oldTitle then oldTitle:Destroy() end
end

function CosmeticsService.ApplyTitle(player, character, titleId, profile)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	local existing = character:FindFirstChild("OverheadTitle")
	if existing then existing:Destroy() end

	local isVip = false
	if profile then
		if profile.OwnedGamePasses and (profile.OwnedGamePasses["VIP_JUDGE"] or profile.OwnedGamePasses["VIP_NAMEPLATE"]) then
			isVip = true
		elseif profile.VIPSubscription and profile.VIPSubscription.Active then
			if profile.VIPSubscription.Expiration == 0 or os.time() <= profile.VIPSubscription.Expiration then
				isVip = true
			end
		end
	end

	local item = (titleId and titleId ~= "none") and CosmeticsCatalog.Get(titleId) or nil
	if not item and not isVip then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadTitle"
	billboard.Size = UDim2.fromScale(5, 1.2)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = false
	billboard.Adornee = head
	billboard.Parent = character

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = isVip and Color3.fromRGB(255, 215, 0) or ((item and item.Color) or Color3.fromRGB(255, 255, 255))
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(15, 10, 25)
	label.TextScaled = true

	local titleText = ""
	if isVip then
		titleText = "[★ VIP ★] "
	end
	if item then
		titleText ..= "« " .. item.Name .. " »"
	elseif isVip then
		titleText ..= "« Courtroom Elite »"
	end

	label.Text = titleText
	label.Parent = billboard
end

function CosmeticsService.ApplyAura(character, auraId)
	if not character or not auraId or auraId == "none" then return end
	local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
	if not root then return end

	local existing = character:FindFirstChild("EquippedAura")
	if existing then existing:Destroy() end

	local item = CosmeticsCatalog.Get(auraId)
	if not item then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "EquippedAura"
	attachment.Parent = root

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AuraParticles"
	emitter.Color = ColorSequence.new(item.Color or Color3.fromRGB(255, 220, 100))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Rate = 18
	emitter.Lifetime = NumberRange.new(1.0, 1.8)
	emitter.Speed = NumberRange.new(1, 2.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 0.7
	emitter.Parent = attachment
end

function CosmeticsService.ApplyGavel(character, gavelId)
	if not character or not gavelId then return end
	local arm = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not arm then return end

	local existing = character:FindFirstChild("EquippedGavel")
	if existing then existing:Destroy() end

	local item = CosmeticsCatalog.Get(gavelId) or CosmeticsCatalog.Get("gavel_wood")

	local model = Instance.new("Model")
	model.Name = "EquippedGavel"
	model.Parent = character

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 1.8, 0.3)
	handle.Color = item.Color or Color3.fromRGB(141, 82, 50)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.8, 0.6, 0.6)
	head.Color = item.Color or Color3.fromRGB(141, 82, 50)
	head.Material = Enum.Material.Wood
	head.CanCollide = false
	head.Parent = model

	createWeld(handle, head, CFrame.new(0, 0.9, 0))
	createWeld(arm, handle, CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(-90), 0, 0))
end

function CosmeticsService.ApplyBriefcase(character, caseId)
	if not character or not caseId then return end
	local arm = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	if not arm then return end

	local existing = character:FindFirstChild("EquippedBriefcase")
	if existing then existing:Destroy() end

	local item = CosmeticsCatalog.Get(caseId) or CosmeticsCatalog.Get("case_leather")

	local model = Instance.new("Model")
	model.Name = "EquippedBriefcase"
	model.Parent = character

	local casePart = Instance.new("Part")
	casePart.Name = "Case"
	casePart.Size = Vector3.new(1.6, 1.2, 0.4)
	casePart.Color = item.Color or Color3.fromRGB(100, 60, 35)
	casePart.Material = Enum.Material.Leather
	casePart.CanCollide = false
	casePart.Parent = model

	createWeld(arm, casePart, CFrame.new(0, -1.0, 0) * CFrame.Angles(0, math.rad(90), 0))
end

function CosmeticsService.Apply(player, role, profile)
	local character = player.Character
	if not character then return end
	CosmeticsService.Clear(character)

	local equipped = profile and profile.Equipped or {}

	-- Title and Aura for everyone
	CosmeticsService.ApplyTitle(player, character, equipped.Title, profile)
	CosmeticsService.ApplyAura(character, equipped.Aura)

	-- Role props
	if role == "Judge" then
		CosmeticsService.ApplyGavel(character, equipped.Gavel or "gavel_wood")
	elseif role == "Prosecutor" or role == "Defense" then
		CosmeticsService.ApplyBriefcase(character, equipped.Briefcase or "case_leather")
	end
end

return CosmeticsService
