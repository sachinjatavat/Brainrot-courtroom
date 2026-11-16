local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local CosmeticsCatalog = Shared.CosmeticsCatalog
local Progression = Shared.Progression
local Themes = Shared.Themes
local Animations = Shared.Animations
local AudioCatalog = Shared.AudioCatalog
local PerformanceSettings = Shared.PerformanceSettings

local remotes = ReplicatedStorage:WaitForChild("CourtroomRemotes")
local stateRemote = remotes:WaitForChild("CourtroomState")
local actionRemote = remotes:WaitForChild("CourtroomAction")
local notificationRemote = remotes:WaitForChild("CourtroomNotification")
local playerDataRemote = remotes:WaitForChild("CourtroomPlayerData")
local cosmeticEffectRemote = remotes:WaitForChild("CourtroomCosmeticEffect")

-- Client Local State
local localProfile = {
	Braincoins = 0, XP = 0, Level = 1, Wins = 0, TrialsPlayed = 0,
	Unlocked = { "gavel_wood", "case_leather", "title_rookie", "theme_classic" },
	Equipped = { Gavel = "gavel_wood", Briefcase = "case_leather", Aura = "none", Title = "title_rookie", Theme = "theme_classic" },
	DailyMissions = { Day = 0, Progress = {}, Claimed = {} },
	Achievements = { Progress = {}, Claimed = {} },
}
local clientSettings = {
	LowGraphics = false,
	SFXEnabled = true,
	ScreenShake = true,
}
local lastState = {}
local currentDisplayedPhase = ""

-- Sound helper
local function playSFX(name)
	if not clientSettings.SFXEnabled then return end
	AudioCatalog.PlaySound(name, SoundService)
end

-- Camera Screen Shake
local function shakeCamera(intensity, duration)
	if not clientSettings.ScreenShake then return end
	task.spawn(function()
		local startTime = os.clock()
		while os.clock() - startTime < (duration or 0.3) do
			local offset = Vector3.new(
				(math.random() - 0.5) * (intensity or 0.5),
				(math.random() - 0.5) * (intensity or 0.5),
				0
			)
			camera.CFrame = camera.CFrame * CFrame.new(offset)
			RunService.RenderStepped:Wait()
		end
	end)
end

-- ==================== GUI CREATION ====================
local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "CourtroomInterface"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local uiScale = Instance.new("UIScale")
uiScale.Parent = root
local function updateScale()
	local viewport = camera.ViewportSize
	if viewport.X < 750 then
		uiScale.Scale = math.clamp(viewport.X / 800, 0.70, 1)
	else
		uiScale.Scale = 1
	end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

-- Helper for rounded frames
local function rounded(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

-- Helper for buttons
local function createButton(parent, text, bgColor, textColor, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundColor3 = bgColor or Color3.fromRGB(45, 35, 65)
	btn.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Parent = parent
	rounded(btn, 10)

	btn.Activated:Connect(function()
		playSFX("EquipItem")
		TweenService:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(0.95, 0, 0.95, 0) }):Play()
		task.wait(0.08)
		TweenService:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(1, 0, 1, 0) }):Play()
		if callback then callback() end
	end)
	return btn
end

-- ==================== TOP HUD ====================
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.fromScale(0.5, 0.015)
topBar.Size = UDim2.new(0.96, 0, 0, 48)
topBar.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
topBar.BackgroundTransparency = 0.15
topBar.Parent = root
rounded(topBar, 14)

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topLayout.Padding = UDim.new(0, 10)
topLayout.Parent = topBar

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = topBar

-- Coin Counter
local coinPill = Instance.new("Frame")
coinPill.Size = UDim2.new(0, 130, 0, 36)
coinPill.BackgroundColor3 = Color3.fromRGB(38, 28, 56)
coinPill.Parent = topBar
rounded(coinPill, 10)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.fromScale(1, 1)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBlack
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextScaled = true
coinLabel.Text = "🪙 0"
coinLabel.Parent = coinPill

-- Level & XP Pill
local xpPill = Instance.new("Frame")
xpPill.Size = UDim2.new(0, 140, 0, 36)
xpPill.BackgroundColor3 = Color3.fromRGB(38, 28, 56)
xpPill.Parent = topBar
rounded(xpPill, 10)

local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.fromScale(1, 1)
xpLabel.BackgroundTransparency = 1
xpLabel.Font = Enum.Font.GothamBold
xpLabel.TextColor3 = Color3.fromRGB(72, 224, 214)
xpLabel.TextScaled = true
xpLabel.Text = "Lv. 1 [0/250]"
xpLabel.Parent = xpPill

-- Title Pill
local titlePill = Instance.new("Frame")
titlePill.Size = UDim2.new(0, 150, 0, 36)
titlePill.BackgroundColor3 = Color3.fromRGB(38, 28, 56)
titlePill.Parent = topBar
rounded(titlePill, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.fromScale(1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Color3.fromRGB(255, 180, 220)
titleLabel.TextScaled = true
titleLabel.Text = "« Rookie Juror »"
titleLabel.Parent = titlePill

-- Spacer
local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(0, 8, 0, 0)
spacer.BackgroundTransparency = 1
spacer.Parent = topBar

-- Nav Buttons
local function navButton(iconText, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 95, 0, 36)
	container.BackgroundTransparency = 1
	container.Parent = topBar
	createButton(container, iconText, Color3.fromRGB(60, 42, 85), Color3.fromRGB(255, 240, 210), callback)
end

local shopModal, missionsModal, emotesModal, profileModal, settingsModal

navButton("🛒 SHOP", function()
	shopModal.Visible = not shopModal.Visible
	missionsModal.Visible = false
	emotesModal.Visible = false
	profileModal.Visible = false
	settingsModal.Visible = false
end)

navButton("📋 MISSIONS", function()
	missionsModal.Visible = not missionsModal.Visible
	shopModal.Visible = false
	emotesModal.Visible = false
	profileModal.Visible = false
	settingsModal.Visible = false
end)

navButton("🎭 EMOTES", function()
	emotesModal.Visible = not emotesModal.Visible
	shopModal.Visible = false
	missionsModal.Visible = false
	profileModal.Visible = false
	settingsModal.Visible = false
end)

navButton("👤 PROFILE", function()
	profileModal.Visible = not profileModal.Visible
	shopModal.Visible = false
	missionsModal.Visible = false
	emotesModal.Visible = false
	settingsModal.Visible = false
end)

navButton("⚙️ SETTINGS", function()
	settingsModal.Visible = not settingsModal.Visible
	shopModal.Visible = false
	missionsModal.Visible = false
	emotesModal.Visible = false
	profileModal.Visible = false
end)

-- ==================== TRIAL STATUS BANNER ====================
local statusPanel = Instance.new("Frame")
statusPanel.Name = "StatusPanel"
statusPanel.AnchorPoint = Vector2.new(0.5, 0)
statusPanel.Position = UDim2.fromScale(0.5, 0.08)
statusPanel.Size = UDim2.new(0.72, 0, 0, 92)
statusPanel.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
statusPanel.BackgroundTransparency = 0.12
statusPanel.Parent = root
rounded(statusPanel, 16)

local phaseText = Instance.new("TextLabel")
phaseText.Position = UDim2.fromScale(0, 0.05)
phaseText.Size = UDim2.fromScale(1, 0.42)
phaseText.BackgroundTransparency = 1
phaseText.Font = Enum.Font.GothamBlack
phaseText.TextColor3 = Color3.fromRGB(255, 215, 0)
phaseText.TextScaled = true
phaseText.Text = "⚖️ LOBBY • WAITING FOR JURY"
phaseText.Parent = statusPanel

local detailText = Instance.new("TextLabel")
detailText.Position = UDim2.fromScale(0, 0.48)
detailText.Size = UDim2.fromScale(1, 0.45)
detailText.BackgroundTransparency = 1
detailText.Font = Enum.Font.GothamBold
detailText.TextColor3 = Color3.fromRGB(255, 245, 220)
detailText.TextScaled = true
detailText.Text = "Prepare for the upcoming trial..."
detailText.Parent = statusPanel

-- Argument Input Box
local argumentBox = Instance.new("TextBox")
argumentBox.AnchorPoint = Vector2.new(0.5, 1)
argumentBox.Position = UDim2.fromScale(0.5, 0.74)
argumentBox.Size = UDim2.new(0.65, 0, 0, 42)
argumentBox.BackgroundColor3 = Color3.fromRGB(255, 245, 225)
argumentBox.TextColor3 = Color3.fromRGB(25, 18, 36)
argumentBox.PlaceholderColor3 = Color3.fromRGB(120, 105, 130)
argumentBox.PlaceholderText = "Type your argument (max 180 chars)..."
argumentBox.Text = ""
argumentBox.ClearTextOnFocus = false
argumentBox.Font = Enum.Font.Gotham
argumentBox.TextScaled = true
argumentBox.Visible = false
argumentBox.Parent = root
rounded(argumentBox, 10)

-- ==================== ACTION BAR ====================
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.AnchorPoint = Vector2.new(0.5, 1)
actionBar.Position = UDim2.fromScale(0.5, 0.98)
actionBar.Size = UDim2.new(0.94, 0, 0, 120)
actionBar.BackgroundTransparency = 1
actionBar.Parent = root

local actionGrid = Instance.new("UIGridLayout")
actionGrid.CellSize = UDim2.new(0.18, 0, 0, 48)
actionGrid.CellPadding = UDim2.new(0, 8, 0, 8)
actionGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionGrid.VerticalAlignment = Enum.VerticalAlignment.Center
actionGrid.Parent = actionBar

local function actionBtn(text, color, callback)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Parent = actionBar
	createButton(container, text, color, Color3.fromRGB(25, 18, 36), callback)
	return container
end

-- Create Action Buttons
local guiltyBtn = actionBtn("GUILTY", Color3.fromRGB(255, 80, 80), function() actionRemote:FireServer("Vote", "GUILTY") end)
local notGuiltyBtn = actionBtn("NOT GUILTY", Color3.fromRGB(100, 235, 120), function() actionRemote:FireServer("Vote", "NOT_GUILTY") end)
local presentEvidenceBtn = actionBtn("PRESENT EVIDENCE", Color3.fromRGB(72, 224, 214), function() actionRemote:FireServer("PresentEvidence", 1) end)
local inspectEvidenceBtn = actionBtn("INSPECT EVIDENCE", Color3.fromRGB(72, 224, 214), function() actionRemote:FireServer("InspectEvidence", 1) end)
local questionWitnessBtn = actionBtn("QUESTION WITNESS", Color3.fromRGB(130, 220, 120), function() actionRemote:FireServer("QuestionWitness", 1) end)
local witnessReactBtn = actionBtn("WITNESS REACTS", Color3.fromRGB(130, 220, 120), function() actionRemote:FireServer("WitnessReact", 1) end)
local submitArgumentBtn = actionBtn("SUBMIT ARGUMENT", Color3.fromRGB(255, 210, 77), function()
	actionRemote:FireServer("SubmitArgument", argumentBox.Text)
	argumentBox.Text = ""
end)
local accuseBtn = actionBtn("MAKE ACCUSATION", Color3.fromRGB(255, 95, 160), function() actionRemote:FireServer("Accuse") end)
local statementBtn = actionBtn("GIVE STATEMENT", Color3.fromRGB(255, 210, 77), function() actionRemote:FireServer("DefendantStatement") end)
local confessBtn = actionBtn("CONFESS", Color3.fromRGB(255, 80, 80), function() actionRemote:FireServer("DefendantResponse", "CONFESS") end)
local denyBtn = actionBtn("DENY", Color3.fromRGB(100, 235, 120), function() actionRemote:FireServer("DefendantResponse", "DENY") end)
local silenceBtn = actionBtn("ORDER SILENCE", Color3.fromRGB(255, 210, 77), function() actionRemote:FireServer("JudgePower", "ORDER_SILENCE") end)
local bananaBtn = actionBtn("BANANA FLOOD", Color3.fromRGB(255, 225, 60), function() actionRemote:FireServer("JudgePower", "THROW_BANANA") end)
local securityBtn = actionBtn("SUMMON SECURITY", Color3.fromRGB(255, 80, 80), function() actionRemote:FireServer("JudgePower", "SUMMON_SECURITY") end)
local explosionBtn = actionBtn("💥 EXPLOSION", Color3.fromRGB(255, 60, 60), function() actionRemote:FireServer("JudgePower", "COURTROOM_EXPLOSION") end)
local forceConfessBtn = actionBtn("FORCE CONFESSION", Color3.fromRGB(255, 105, 180), function() actionRemote:FireServer("JudgePower", "FORCE_CONFESSION") end)
local reverseVerdictBtn = actionBtn("REVERSE VERDICT", Color3.fromRGB(102, 224, 129), function() actionRemote:FireServer("JudgePower", "REVERSE_VERDICT") end)
local startArgsBtn = actionBtn("START ARGS", Color3.fromRGB(255, 210, 77), function() actionRemote:FireServer("JudgeControl", "START_ARGUMENTS") end)
local endArgsBtn = actionBtn("END ARGS", Color3.fromRGB(255, 80, 80), function() actionRemote:FireServer("JudgeControl", "END_ARGUMENTS") end)

-- ==================== MODAL WINDOW HELPER ====================
local function createModal(titleText, size)
	local m = Instance.new("Frame")
	m.AnchorPoint = Vector2.new(0.5, 0.5)
	m.Position = UDim2.fromScale(0.5, 0.5)
	m.Size = size or UDim2.new(0.68, 0, 0.65, 0)
	m.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
	m.BorderSizePixel = 0
	m.Visible = false
	m.Parent = root
	rounded(m, 18)

	local mTitle = Instance.new("TextLabel")
	mTitle.Position = UDim2.new(0, 16, 0, 12)
	mTitle.Size = UDim2.new(0.8, 0, 0, 32)
	mTitle.BackgroundTransparency = 1
	mTitle.Font = Enum.Font.GothamBlack
	mTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	mTitle.TextScaled = true
	mTitle.TextXAlignment = Enum.TextXAlignment.Left
	mTitle.Text = titleText
	mTitle.Parent = m

	local closeContainer = Instance.new("Frame")
	closeContainer.Position = UDim2.new(1, -44, 0, 12)
	closeContainer.Size = UDim2.new(0, 32, 0, 32)
	closeContainer.BackgroundTransparency = 1
	closeContainer.Parent = m
	createButton(closeContainer, "X", Color3.fromRGB(200, 50, 60), Color3.fromRGB(255, 255, 255), function()
		m.Visible = false
	end)

	local body = Instance.new("ScrollingFrame")
	body.Position = UDim2.new(0, 16, 0, 56)
	body.Size = UDim2.new(1, -32, 1, -68)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 6
	body.Parent = m

	return m, body
end

-- ==================== SHOP & INVENTORY MODAL ====================
local shopBody
shopModal, shopBody = createModal("🛒 BRAINCOINS SHOP & INVENTORY")

local function renderShop()
	shopBody:ClearAllChildren()
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.31, 0, 0, 110)
	grid.CellPadding = UDim2.new(0, 10, 0, 10)
	grid.Parent = shopBody

	local items = CosmeticsCatalog.GetAll()
	for _, item in ipairs(items) do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
		card.Parent = shopBody
		rounded(card, 12)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Position = UDim2.new(0, 8, 0, 6)
		nameLabel.Size = UDim2.new(1, -16, 0, 22)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = item.Color or Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Text = item.Name
		nameLabel.Parent = card

		local descLabel = Instance.new("TextLabel")
		descLabel.Position = UDim2.new(0, 8, 0, 30)
		descLabel.Size = UDim2.new(1, -16, 0, 32)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextColor3 = Color3.fromRGB(200, 190, 210)
		descLabel.TextScaled = true
		descLabel.Text = item.Description or item.Category
		descLabel.Parent = card

		local isOwned = false
		for _, ownedId in ipairs(localProfile.Unlocked or {}) do
			if ownedId == item.Id then isOwned = true break end
		end

		local isEquipped = (localProfile.Equipped and localProfile.Equipped[item.Category] == item.Id)

		local actionContainer = Instance.new("Frame")
		actionContainer.Position = UDim2.new(0, 8, 0, 68)
		actionContainer.Size = UDim2.new(1, -16, 0, 32)
		actionContainer.BackgroundTransparency = 1
		actionContainer.Parent = card

		if isEquipped then
			createButton(actionContainer, "EQUIPPED", Color3.fromRGB(60, 140, 80), Color3.fromRGB(255, 255, 255), nil)
		elseif isOwned then
			createButton(actionContainer, "EQUIP", Color3.fromRGB(72, 170, 255), Color3.fromRGB(255, 255, 255), function()
				actionRemote:FireServer("EquipItem", { Category = item.Category, ItemId = item.Id })
			end)
		else
			local priceText = (item.Price == 0) and "FREE" or ("BUY 🪙 " .. item.Price)
			createButton(actionContainer, priceText, Color3.fromRGB(255, 180, 50), Color3.fromRGB(25, 18, 36), function()
				actionRemote:FireServer("BuyItem", item.Id)
			end)
		end
	end
end

-- ==================== MISSIONS & ACHIEVEMENTS MODAL ====================
local missionsBody
missionsModal, missionsBody = createModal("📋 DAILY MISSIONS & ACHIEVEMENTS")

local function renderMissions()
	missionsBody:ClearAllChildren()
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.Parent = missionsBody

	local day = math.floor(os.time() / 86400)
	local dailyList = Progression.GetMissionsForDay(day)

	for _, m in ipairs(dailyList) do
		local mCard = Instance.new("Frame")
		mCard.Size = UDim2.new(1, -10, 0, 64)
		mCard.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
		mCard.Parent = missionsBody
		rounded(mCard, 10)

		local mTitle = Instance.new("TextLabel")
		mTitle.Position = UDim2.new(0, 12, 0, 8)
		mTitle.Size = UDim2.new(0.65, 0, 0, 22)
		mTitle.BackgroundTransparency = 1
		mTitle.Font = Enum.Font.GothamBold
		mTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		mTitle.TextScaled = true
		mTitle.TextXAlignment = Enum.TextXAlignment.Left
		mTitle.Text = m.Title .. " (" .. (localProfile.DailyMissions.Progress[m.Id] or 0) .. "/" .. m.Target .. ")"
		mTitle.Parent = mCard

		local mDesc = Instance.new("TextLabel")
		mDesc.Position = UDim2.new(0, 12, 0, 32)
		mDesc.Size = UDim2.new(0.65, 0, 0, 24)
		mDesc.BackgroundTransparency = 1
		mDesc.Font = Enum.Font.Gotham
		mDesc.TextColor3 = Color3.fromRGB(200, 195, 210)
		mDesc.TextScaled = true
		mDesc.TextXAlignment = Enum.TextXAlignment.Left
		mDesc.Text = m.Description .. " [Reward: 🪙 " .. m.RewardCoins .. "]"
		mDesc.Parent = mCard

		local isClaimed = localProfile.DailyMissions.Claimed[m.Id] == true
		local isReady = (localProfile.DailyMissions.Progress[m.Id] or 0) >= m.Target

		local claimContainer = Instance.new("Frame")
		claimContainer.Position = UDim2.new(0.72, 0, 0, 14)
		claimContainer.Size = UDim2.new(0.25, 0, 0, 36)
		claimContainer.BackgroundTransparency = 1
		claimContainer.Parent = mCard

		if isClaimed then
			createButton(claimContainer, "CLAIMED", Color3.fromRGB(50, 50, 60), Color3.fromRGB(150, 150, 160), nil)
		elseif isReady then
			createButton(claimContainer, "CLAIM 🎁", Color3.fromRGB(100, 235, 120), Color3.fromRGB(25, 18, 36), function()
				actionRemote:FireServer("ClaimDailyMission", m.Id)
			end)
		else
			createButton(claimContainer, "IN PROGRESS", Color3.fromRGB(45, 35, 60), Color3.fromRGB(170, 160, 180), nil)
		end
	end
end

-- ==================== EMOTES & REACTIONS MODAL ====================
local emotesBody
emotesModal, emotesBody = createModal("🎭 EMOTES & REACTIONS", UDim2.new(0.5, 0, 0.45, 0))

local emoteList = {
	{ Id = "OBJECTION", Name = "💥 OBJECTION!", Color = Color3.fromRGB(255, 60, 60) },
	{ Id = "GAVEL_SLAM", Name = "🔨 GAVEL SLAM", Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "CRY", Name = "😭 CRY", Color = Color3.fromRGB(72, 170, 255) },
	{ Id = "LAUGH", Name = "🤣 LAUGH", Color = Color3.fromRGB(255, 210, 77) },
	{ Id = "DANCE", Name = "🕺 DANCE", Color = Color3.fromRGB(102, 224, 129) },
	{ Id = "FACEPALM", Name = "🤦 FACEPALM", Color = Color3.fromRGB(220, 180, 140) },
}

local eGrid = Instance.new("UIGridLayout")
eGrid.CellSize = UDim2.new(0.48, 0, 0, 48)
eGrid.CellPadding = UDim2.new(0, 8, 0, 8)
eGrid.Parent = emotesBody

for _, emote in ipairs(emoteList) do
	local c = Instance.new("Frame")
	c.BackgroundTransparency = 1
	c.Parent = emotesBody
	createButton(c, emote.Name, emote.Color, Color3.fromRGB(25, 18, 36), function()
		actionRemote:FireServer("PlayEmote", emote.Id)
		if emote.Id == "OBJECTION" then
			shakeCamera(0.6, 0.3)
		end
		emotesModal.Visible = false
	end)
end

-- ==================== PLAYER PROFILE MODAL ====================
local profileBody
profileModal, profileBody = createModal("👤 PLAYER DOSSIER & STATS", UDim2.new(0.48, 0, 0.52, 0))

local function renderProfile()
	profileBody:ClearAllChildren()
	local pList = Instance.new("UIListLayout")
	pList.Padding = UDim.new(0, 8)
	pList.Parent = profileBody

	local stats = {
		{ Label = "Player Name", Value = player.DisplayName .. " (@" .. player.Name .. ")" },
		{ Label = "Current Level", Value = "Lv. " .. (localProfile.Level or 1) },
		{ Label = "Lifetime XP", Value = (localProfile.XP or 0) .. " XP" },
		{ Label = "Braincoins Balance", Value = "🪙 " .. (localProfile.Braincoins or 0) },
		{ Label = "Trials Completed", Value = tostring(localProfile.TrialsPlayed or 0) },
		{ Label = "Verdicts Won", Value = tostring(localProfile.Wins or 0) },
		{ Label = "Equipped Title", Value = (localProfile.Equipped and localProfile.Equipped.Title) or "title_rookie" },
		{ Label = "Equipped Gavel", Value = (localProfile.Equipped and localProfile.Equipped.Gavel) or "gavel_wood" },
		{ Label = "Equipped Aura", Value = (localProfile.Equipped and localProfile.Equipped.Aura) or "none" },
	}

	for _, s in ipairs(stats) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 36)
		row.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
		row.Parent = profileBody
		rounded(row, 8)

		local l = Instance.new("TextLabel")
		l.Position = UDim2.new(0, 10, 0, 0)
		l.Size = UDim2.new(0.45, 0, 1, 0)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextColor3 = Color3.fromRGB(255, 215, 0)
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = s.Label
		l.Parent = row

		local v = Instance.new("TextLabel")
		v.Position = UDim2.new(0.5, 0, 0, 0)
		v.Size = UDim2.new(0.48, 0, 1, 0)
		v.BackgroundTransparency = 1
		v.Font = Enum.Font.Gotham
		v.TextColor3 = Color3.fromRGB(240, 240, 250)
		v.TextScaled = true
		v.TextXAlignment = Enum.TextXAlignment.Right
		v.Text = s.Value
		v.Parent = row
	end
end

-- ==================== SETTINGS MODAL ====================
local settingsBody
settingsModal, settingsBody = createModal("⚙️ SETTINGS & PERFORMANCE", UDim2.new(0.45, 0, 0.42, 0))

local sList = Instance.new("UIListLayout")
sList.Padding = UDim.new(0, 12)
sList.Parent = settingsBody

local function addToggle(label, initialVal, onToggle)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
	row.Parent = settingsBody
	rounded(row, 10)

	local txt = Instance.new("TextLabel")
	txt.Position = UDim2.new(0, 12, 0, 0)
	txt.Size = UDim2.new(0.6, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextScaled = true
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Text = label
	txt.Parent = row

	local btnBox = Instance.new("Frame")
	btnBox.Position = UDim2.new(0.68, 0, 0, 5)
	btnBox.Size = UDim2.new(0.28, 0, 0, 32)
	btnBox.BackgroundTransparency = 1
	btnBox.Parent = row

	local stateVal = initialVal
	local btn
	btn = createButton(btnBox, stateVal and "ON" or "OFF", stateVal and Color3.fromRGB(100, 235, 120) or Color3.fromRGB(70, 70, 80), Color3.fromRGB(25, 18, 36), function()
		stateVal = not stateVal
		btn.Text = stateVal and "ON" or "OFF"
		btn.BackgroundColor3 = stateVal and Color3.fromRGB(100, 235, 120) or Color3.fromRGB(70, 70, 80)
		onToggle(stateVal)
	end)
end

addToggle("Low Graphics Mode", clientSettings.LowGraphics, function(val)
	clientSettings.LowGraphics = val
	PerformanceSettings.Apply(val and "Low" or "High", workspace)
end)

addToggle("Sound Effects", clientSettings.SFXEnabled, function(val)
	clientSettings.SFXEnabled = val
end)

addToggle("Screen Shake", clientSettings.ScreenShake, function(val)
	clientSettings.ScreenShake = val
end)

-- ==================== DRAMATIC OVERLAYS & ROLE INTRO ====================
local function showDramaticRoleIntro(role, case)
	local roleObjectives = {
		Judge = "Maintain order, swing your gavel, and decide the courtroom's fate!",
		Prosecutor = "Prove the accused committed the crime with indisputable exhibits!",
		Defense = "Cast reasonable doubt, detect contradictions, and protect your client!",
		Defendant = "Survive the accusations, declare innocence, or make a tactical confession!",
		Witness = "Deliver testimony, answer cross-examinations, and hold onto your story!",
		Jury = "Listen closely to arguments, weigh the exhibits, and deliver the final verdict!",
		Spectator = "Observe the legal chaos from the balcony seats!",
	}

	local roleColors = {
		Judge = Color3.fromRGB(255, 215, 0),
		Prosecutor = Color3.fromRGB(255, 80, 80),
		Defense = Color3.fromRGB(72, 224, 214),
		Defendant = Color3.fromRGB(255, 160, 50),
		Witness = Color3.fromRGB(120, 225, 120),
		Jury = Color3.fromRGB(255, 230, 80),
		Spectator = Color3.fromRGB(180, 180, 200),
	}

	playSFX("Objection")
	local splash = Instance.new("Frame")
	splash.AnchorPoint = Vector2.new(0.5, 0.5)
	splash.Position = UDim2.fromScale(0.5, 0.45)
	splash.Size = UDim2.fromScale(0.1, 0.05)
	splash.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
	splash.ZIndex = 12
	splash.Parent = root
	rounded(splash, 20)

	local rTitle = Instance.new("TextLabel")
	rTitle.Position = UDim2.fromScale(0, 0.1)
	rTitle.Size = UDim2.fromScale(1, 0.35)
	rTitle.BackgroundTransparency = 1
	rTitle.Font = Enum.Font.GothamBlack
	rTitle.TextColor3 = roleColors[role] or Color3.fromRGB(255, 215, 0)
	rTitle.TextScaled = true
	rTitle.Text = "YOU ARE THE " .. role:upper() .. "!"
	rTitle.ZIndex = 13
	rTitle.Parent = splash

	local rObj = Instance.new("TextLabel")
	rObj.Position = UDim2.fromScale(0.05, 0.5)
	rObj.Size = UDim2.fromScale(0.9, 0.4)
	rObj.BackgroundTransparency = 1
	rObj.Font = Enum.Font.GothamBold
	rObj.TextColor3 = Color3.fromRGB(255, 245, 220)
	rObj.TextScaled = true
	rObj.Text = roleObjectives[role] or "Participate in the trial."
	rObj.ZIndex = 13
	rObj.Parent = splash

	TweenService:Create(splash, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.75, 0.28),
	}):Play()

	task.delay(4, function()
		if splash.Parent then
			TweenService:Create(splash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.fromScale(0.1, 0.02),
				BackgroundTransparency = 1,
			}):Play()
			task.wait(0.3)
			splash:Destroy()
		end
	end)
end

local function showDramaticObjection()
	playSFX("Objection")
	shakeCamera(0.8, 0.4)

	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.45)
	banner.Size = UDim2.fromScale(0.1, 0.05)
	banner.BackgroundColor3 = Color3.fromRGB(255, 30, 45)
	banner.BorderSizePixel = 0
	banner.ZIndex = 10
	banner.Parent = root
	rounded(banner, 18)

	local bannerText = Instance.new("TextLabel")
	bannerText.Size = UDim2.fromScale(1, 1)
	bannerText.BackgroundTransparency = 1
	bannerText.Font = Enum.Font.GothamBlack
	bannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	bannerText.TextStrokeColor3 = Color3.fromRGB(40, 10, 10)
	bannerText.TextStrokeTransparency = 0
	bannerText.TextScaled = true
	bannerText.Text = "⚡ OBJECTION! ⚡"
	bannerText.ZIndex = 11
	bannerText.Parent = banner

	TweenService:Create(banner, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.85, 0.22),
	}):Play()

	task.delay(1.4, function()
		if banner.Parent then
			TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.fromScale(0.1, 0.02),
				BackgroundTransparency = 1,
			}):Play()
			task.wait(0.25)
			banner:Destroy()
		end
	end)
end

local function showDramaticVerdict(verdict)
	shakeCamera(1.0, 0.6)
	if verdict == "GUILTY" then
		playSFX("VerdictGuilty")
	else
		playSFX("VerdictNotGuilty")
	end

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = (verdict == "GUILTY") and Color3.fromRGB(140, 15, 25) or Color3.fromRGB(20, 100, 160)
	overlay.BackgroundTransparency = 0.8
	overlay.ZIndex = 8
	overlay.Parent = root

	local vLabel = Instance.new("TextLabel")
	vLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	vLabel.Position = UDim2.fromScale(0.5, 0.42)
	vLabel.Size = UDim2.fromScale(0.9, 0.28)
	vLabel.BackgroundTransparency = 1
	vLabel.Font = Enum.Font.GothamBlack
	vLabel.TextColor3 = (verdict == "GUILTY") and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(100, 255, 140)
	vLabel.TextStrokeTransparency = 0
	vLabel.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
	vLabel.TextScaled = true
	vLabel.Text = (verdict == "GUILTY") and "⚖️ GUILTY! ⚖️" or "✨ NOT GUILTY! ✨"
	vLabel.ZIndex = 9
	vLabel.Parent = overlay

	TweenService:Create(overlay, TweenInfo.new(3.5), { BackgroundTransparency = 1 }):Play()
	task.delay(4, function()
		if overlay.Parent then overlay:Destroy() end
	end)
end

-- ==================== STATE RENDERING ====================
local function render(state)
	lastState = state

	-- Check for phase transition
	if state.Phase ~= currentDisplayedPhase then
		currentDisplayedPhase = state.Phase
		if state.Phase == "Briefing" then
			local role = state.Roles and state.Roles[player.UserId] or "Spectator"
			showDramaticRoleIntro(role, state.Case)
		end
	end

	phaseText.Text = string.format("⚖️ %s • %ss", state.Phase:upper(), state.TimeLeft or 0)

	local role = state.Roles and state.Roles[player.UserId] or "Spectator"
	local case = state.Case

	if state.Phase == "Lobby" then
		detailText.Text = "Waiting for players to begin the next trial..."
	elseif state.Phase == "Briefing" and case then
		detailText.Text = string.format("[%s] CASE: %s - %s", role:upper(), case.Crime, case.Briefing)
	elseif state.Phase == "Trial" and case then
		local ev = (state.ActiveEvidence and case.Evidence[state.ActiveEvidence])
		local evText = ev and (" | EXHIBIT: " .. ev.Name) or ""
		local pScore = state.ArgumentScores and state.ArgumentScores.Prosecutor or 0
		local dScore = state.ArgumentScores and state.ArgumentScores.Defense or 0
		detailText.Text = string.format("[%s] CASE: %s%s [P:%d D:%d]", role:upper(), case.Crime, evText, pScore, dScore)
	elseif state.Phase == "Voting" then
		detailText.Text = "Jury members: cast your final vote now!"
	elseif state.Phase == "Verdict" and state.Votes and state.Votes.Result then
		detailText.Text = string.format("VERDICT: %s (Guilty: %d / Not Guilty: %d)", state.Votes.Result, state.Votes.Guilty or 0, state.Votes.NotGuilty or 0)
	elseif state.Phase == "Rewards" and state.Awards and #state.Awards > 0 then
		local topAward = state.Awards[1]
		detailText.Text = string.format("🎉 %s awarded to %s (+%d Coins)!", topAward.Title, topAward.Winner, topAward.Bonus)
	end

	if state.Chaos then
		detailText.Text = "⚡ CHAOS EVENT: " .. state.Chaos:gsub("_", " ") .. " ⚡"
	end

	-- Role action button visibility
	local isJury = (role == "Jury")
	local isJudge = (role == "Judge")
	local isLawyer = (role == "Prosecutor" or role == "Defense")
	local isDefendant = (role == "Defendant")
	local isTrial = (state.Phase == "Trial")
	local isVoting = (state.Phase == "Voting")

	guiltyBtn.Visible = isVoting and isJury
	notGuiltyBtn.Visible = isVoting and isJury

	presentEvidenceBtn.Visible = isTrial and isLawyer
	inspectEvidenceBtn.Visible = isTrial and isLawyer
	questionWitnessBtn.Visible = isTrial and isLawyer
	witnessReactBtn.Visible = isTrial and isLawyer
	submitArgumentBtn.Visible = isTrial and isLawyer
	argumentBox.Visible = isTrial and isLawyer
	accuseBtn.Visible = isTrial and (role == "Prosecutor")

	statementBtn.Visible = isTrial and isDefendant
	confessBtn.Visible = isTrial and isDefendant and state.ConfessionRequired
	denyBtn.Visible = isTrial and isDefendant and state.ConfessionRequired

	silenceBtn.Visible = isTrial and isJudge
	bananaBtn.Visible = isTrial and isJudge
	securityBtn.Visible = isTrial and isJudge
	explosionBtn.Visible = isTrial and isJudge
	forceConfessBtn.Visible = isTrial and isJudge
	reverseVerdictBtn.Visible = isTrial and isJudge
	startArgsBtn.Visible = isTrial and isJudge
	endArgsBtn.Visible = isTrial and isJudge

	-- Sound ticks when countdown is under 5 seconds
	if state.TimeLeft and state.TimeLeft > 0 and state.TimeLeft <= 5 then
		playSFX("CountdownTick")
	end
end

stateRemote.OnClientEvent:Connect(render)

notificationRemote.OnClientEvent:Connect(function(msg)
	detailText.Text = tostring(msg)
	local orig = detailText.TextColor3
	detailText.TextColor3 = Color3.fromRGB(255, 105, 180)
	TweenService:Create(detailText, TweenInfo.new(1.5), { TextColor3 = orig }):Play()
end)

playerDataRemote.OnClientEvent:Connect(function(profile)
	if type(profile) == "table" then
		localProfile = profile
		coinLabel.Text = "🪙 " .. (profile.Braincoins or 0)
		local level = profile.Level or 1
		local xp = profile.XP or 0
		xpLabel.Text = string.format("Lv. %d [%d/%d]", level, xp, Progression.GetNextLevelXP(level))

		if profile.Equipped and profile.Equipped.Title then
			local titleItem = CosmeticsCatalog.Get(profile.Equipped.Title)
			titleLabel.Text = "« " .. (titleItem and titleItem.Name or "Rookie Juror") .. " »"
			if titleItem and titleItem.Color then titleLabel.TextColor3 = titleItem.Color end
		end

		if shopModal.Visible then renderShop() end
		if missionsModal.Visible then renderMissions() end
		if profileModal.Visible then renderProfile() end
	end
end)

cosmeticEffectRemote.OnClientEvent:Connect(function(effectType, arg1, arg2)
	if effectType == "Sound" and arg1 then
		playSFX(arg1)
	elseif effectType == "Emote" and arg2 == "OBJECTION" then
		showDramaticObjection()
	elseif effectType == "Verdict" and arg1 then
		showDramaticVerdict(arg1)
	end
end)

-- Initial UI population
renderShop()
renderMissions()
renderProfile()
