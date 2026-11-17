local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

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
local MonetizationConfig = Shared.MonetizationConfig

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

local trialSidePanel, lobbyPanel, actionGrid

local function updateScale()
	local viewport = camera.ViewportSize
	local scaleX = viewport.X / 850
	local scaleY = viewport.Y / 520
	local targetScale = math.clamp(math.min(scaleX, scaleY), 0.60, 1.0)
	uiScale.Scale = targetScale

	if trialSidePanel and lobbyPanel and actionGrid then
		if viewport.X < 720 then
			trialSidePanel.Size = UDim2.new(0, 175, 0.52, 0)
			lobbyPanel.Size = UDim2.new(0, 175, 0.48, 0)
			actionGrid.CellSize = UDim2.new(0.23, 0, 0, 44)
		else
			trialSidePanel.Size = UDim2.new(0, 220, 0.6, 0)
			lobbyPanel.Size = UDim2.new(0, 220, 0.52, 0)
			actionGrid.CellSize = UDim2.new(0.18, 0, 0, 48)
		end
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

actionGrid = Instance.new("UIGridLayout")
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
shopModal, shopBody = createModal("🛒 STORE & MONETIZATION EMPORIUM", UDim2.new(0.74, 0, 0.72, 0))

local currentShopCategory = "VIP"
local categoryBar = Instance.new("Frame")
categoryBar.Position = UDim2.new(0, 16, 0, 48)
categoryBar.Size = UDim2.new(1, -32, 0, 32)
categoryBar.BackgroundTransparency = 1
categoryBar.Parent = shopModal

local catLayout = Instance.new("UIListLayout")
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 6)
catLayout.Parent = categoryBar

shopBody.Position = UDim2.new(0, 16, 0, 88)
shopBody.Size = UDim2.new(1, -32, 1, -100)

local SHOP_TABS = {
	{ Key = "VIP", Label = "👑 VIP" },
	{ Key = "PASSES", Label = "🎟️ PASSES" },
	{ Key = "COINS", Label = "🪙 COINS" },
	{ Key = "EMOTES", Label = "🎭 EMOTES" },
	{ Key = "GAVEL", Label = "🔨 GAVELS" },
	{ Key = "CHARACTER", Label = "💼 CHARACTER" },
	{ Key = "THEME", Label = "🏛️ THEMES" },
}

local function renderShopCategories()
	categoryBar:ClearAllChildren()
	catLayout = Instance.new("UIListLayout")
	catLayout.FillDirection = Enum.FillDirection.Horizontal
	catLayout.Padding = UDim.new(0, 6)
	catLayout.Parent = categoryBar

	for _, tab in ipairs(SHOP_TABS) do
		local isSelected = (currentShopCategory == tab.Key)
		local tabContainer = Instance.new("Frame")
		tabContainer.Size = UDim2.new(0.134, 0, 1, 0)
		tabContainer.BackgroundTransparency = 1
		tabContainer.Parent = categoryBar

		local bgCol = isSelected and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(45, 32, 60)
		local txtCol = isSelected and Color3.fromRGB(24, 16, 36) or Color3.fromRGB(240, 235, 250)

		createButton(tabContainer, tab.Label, bgCol, txtCol, function()
			currentShopCategory = tab.Key
			renderShopCategories()
			renderShop()
		end)
	end
end

function renderShop()
	shopBody:ClearAllChildren()
	shopBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopBody.CanvasSize = UDim2.new(0, 0, 0, 0)

	local padShop = Instance.new("UIPadding")
	padShop.PaddingBottom = UDim.new(0, 12)
	padShop.Parent = shopBody

	local isPlayerVIP = false
	if (localProfile.VIPSubscription and localProfile.VIPSubscription.Active) or (localProfile.OwnedGamePasses and localProfile.OwnedGamePasses.VIP_JUDGE) then
		isPlayerVIP = true
	end

	if currentShopCategory == "VIP" then
		-- Big VIP Membership Banner
		local vipBanner = Instance.new("Frame")
		vipBanner.Size = UDim2.new(1, 0, 0, 120)
		vipBanner.BackgroundColor3 = Color3.fromRGB(40, 24, 60)
		vipBanner.Parent = shopBody
		rounded(vipBanner, 14)

		local vipBannerTitle = Instance.new("TextLabel")
		vipBannerTitle.Position = UDim2.new(0, 16, 0, 10)
		vipBannerTitle.Size = UDim2.new(0.65, 0, 0, 26)
		vipBannerTitle.BackgroundTransparency = 1
		vipBannerTitle.Font = Enum.Font.GothamBlack
		vipBannerTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		vipBannerTitle.TextScaled = true
		vipBannerTitle.TextXAlignment = Enum.TextXAlignment.Left
		vipBannerTitle.Text = "👑 VIP COURTROOM MEMBERSHIP"
		vipBannerTitle.Parent = vipBanner

		local vipBannerDesc = Instance.new("TextLabel")
		vipBannerDesc.Position = UDim2.new(0, 16, 0, 38)
		vipBannerDesc.Size = UDim2.new(0.65, 0, 0, 48)
		vipBannerDesc.BackgroundTransparency = 1
		vipBannerDesc.Font = Enum.Font.Gotham
		vipBannerDesc.TextColor3 = Color3.fromRGB(230, 220, 240)
		vipBannerDesc.TextScaled = true
		vipBannerDesc.TextXAlignment = Enum.TextXAlignment.Left
		vipBannerDesc.Text = "• Golden [VIP] Overhead Nameplate\n• Exclusive Diamond Halo & Platinum Gavel\n• Special VIP Emotes & Lounge Access\n• 2,500 Braincoins Monthly Reward!"
		vipBannerDesc.Parent = vipBanner

		local vipActionBox = Instance.new("Frame")
		vipActionBox.Position = UDim2.new(0.7, 0, 0, 20)
		vipActionBox.Size = UDim2.new(0.28, 0, 0, 75)
		vipActionBox.BackgroundTransparency = 1
		vipActionBox.Parent = vipBanner

		if isPlayerVIP then
			createButton(vipActionBox, "CLAIM 2,500 🪙\nMONTHLY BONUS", Color3.fromRGB(255, 200, 40), Color3.fromRGB(24, 16, 36), function()
				actionRemote:FireServer("ClaimVIPBonus")
			end)
		else
			createButton(vipActionBox, "JOIN VIP CLUB\n(R$ 199 / mo)", Color3.fromRGB(255, 215, 0), Color3.fromRGB(24, 16, 36), function()
				local passDef = MonetizationConfig.GamePasses.VIP_JUDGE
				if passDef and passDef.Id and passDef.Id > 0 then
					MarketplaceService:PromptGamePassPurchase(player, passDef.Id)
				else
					detailText.Text = "VIP configured in MonetizationConfig (Creator Dashboard setup ready)!"
				end
			end)
		end

		-- VIP Showcase Items
		local showcaseTitle = Instance.new("TextLabel")
		showcaseTitle.Position = UDim2.new(0, 0, 0, 130)
		showcaseTitle.Size = UDim2.new(1, 0, 0, 24)
		showcaseTitle.BackgroundTransparency = 1
		showcaseTitle.Font = Enum.Font.GothamBold
		showcaseTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		showcaseTitle.TextScaled = true
		showcaseTitle.TextXAlignment = Enum.TextXAlignment.Left
		showcaseTitle.Text = "EXCLUSIVE VIP ITEMS (INCLUDED WITH VIP)"
		showcaseTitle.Parent = shopBody

		local showcaseGrid = Instance.new("Frame")
		showcaseGrid.Position = UDim2.new(0, 0, 0, 160)
		showcaseGrid.Size = UDim2.new(1, 0, 0, 140)
		showcaseGrid.BackgroundTransparency = 1
		showcaseGrid.Parent = shopBody

		local vipItems = { "gavel_vip", "aura_vip", "title_vip" }
		for idx, vId in ipairs(vipItems) do
			local itm = CosmeticsCatalog.Get(vId)
			if itm then
				local card = Instance.new("Frame")
				card.Position = UDim2.new((idx - 1) * 0.33, 0, 0, 0)
				card.Size = UDim2.new(0.31, 0, 0, 130)
				card.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
				card.Parent = showcaseGrid
				rounded(card, 12)

				local nameLbl = Instance.new("TextLabel")
				nameLbl.Position = UDim2.new(0, 8, 0, 8)
				nameLbl.Size = UDim2.new(1, -16, 0, 22)
				nameLbl.BackgroundTransparency = 1
				nameLbl.Font = Enum.Font.GothamBold
				nameLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
				nameLbl.TextScaled = true
				nameLbl.Text = itm.Name
				nameLbl.Parent = card

				local descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.new(0, 8, 0, 34)
				descLbl.Size = UDim2.new(1, -16, 0, 42)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.TextColor3 = Color3.fromRGB(200, 190, 210)
				descLbl.TextScaled = true
				descLbl.Text = itm.Description
				descLbl.Parent = card

				local isEquipped = (localProfile.Equipped and localProfile.Equipped[itm.Category] == itm.Id)
				local actBox = Instance.new("Frame")
				actBox.Position = UDim2.new(0, 8, 0, 86)
				actBox.Size = UDim2.new(1, -16, 0, 32)
				actBox.BackgroundTransparency = 1
				actBox.Parent = card

				if not isPlayerVIP then
					createButton(actBox, "🔒 VIP ONLY", Color3.fromRGB(80, 60, 90), Color3.fromRGB(180, 170, 190), nil)
				elseif isEquipped then
					createButton(actBox, "✓ EQUIPPED", Color3.fromRGB(60, 140, 80), Color3.fromRGB(255, 255, 255), nil)
				else
					createButton(actBox, "EQUIP", Color3.fromRGB(72, 170, 255), Color3.fromRGB(255, 255, 255), function()
						actionRemote:FireServer("EquipItem", { Category = itm.Category, ItemId = itm.Id })
					end)
				end
			end
		end

	elseif currentShopCategory == "PASSES" then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.31, 0, 0, 135)
		grid.CellPadding = UDim2.new(0, 10, 0, 10)
		grid.Parent = shopBody

		for _, pass in pairs(MonetizationConfig.GamePasses) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
			card.Parent = shopBody
			rounded(card, 12)

			local topBar = Instance.new("Frame")
			topBar.Size = UDim2.new(1, 0, 0, 5)
			topBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			topBar.BorderSizePixel = 0
			topBar.Parent = card
			local tbc = Instance.new("UICorner")
			tbc.CornerRadius = UDim.new(0, 10)
			tbc.Parent = topBar

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Position = UDim2.new(0, 8, 0, 8)
			nameLbl.Size = UDim2.new(1, -16, 0, 22)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
			nameLbl.TextScaled = true
			nameLbl.Text = pass.Name
			nameLbl.Parent = card

			local priceLbl = Instance.new("TextLabel")
			priceLbl.Position = UDim2.new(0, 8, 0, 30)
			priceLbl.Size = UDim2.new(1, -16, 0, 16)
			priceLbl.BackgroundTransparency = 1
			priceLbl.Font = Enum.Font.GothamBold
			priceLbl.TextColor3 = Color3.fromRGB(100, 240, 140)
			priceLbl.TextScaled = true
			priceLbl.TextXAlignment = Enum.TextXAlignment.Left
			priceLbl.Text = "R$ " .. pass.PriceRobux .. " (Permanent)"
			priceLbl.Parent = card

			local descLbl = Instance.new("TextLabel")
			descLbl.Position = UDim2.new(0, 8, 0, 48)
			descLbl.Size = UDim2.new(1, -16, 0, 42)
			descLbl.BackgroundTransparency = 1
			descLbl.Font = Enum.Font.Gotham
			descLbl.TextColor3 = Color3.fromRGB(200, 190, 210)
			descLbl.TextScaled = true
			descLbl.Text = pass.Description
			descLbl.Parent = card

			local isOwned = localProfile.OwnedGamePasses and localProfile.OwnedGamePasses[pass.Key]
			local actBox = Instance.new("Frame")
			actBox.Position = UDim2.new(0, 8, 0, 96)
			actBox.Size = UDim2.new(1, -16, 0, 30)
			actBox.BackgroundTransparency = 1
			actBox.Parent = card

			if isOwned then
				createButton(actBox, "✓ OWNED", Color3.fromRGB(60, 140, 80), Color3.fromRGB(255, 255, 255), nil)
			else
				createButton(actBox, "BUY (R$ " .. pass.PriceRobux .. ")", Color3.fromRGB(72, 170, 255), Color3.fromRGB(255, 255, 255), function()
					if pass.Id and pass.Id > 0 then
						MarketplaceService:PromptGamePassPurchase(player, pass.Id)
					else
						detailText.Text = "Pass configured! Set pass ID in MonetizationConfig.lua."
					end
				end)
			end
		end

	elseif currentShopCategory == "COINS" then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.31, 0, 0, 135)
		grid.CellPadding = UDim2.new(0, 10, 0, 10)
		grid.Parent = shopBody

		for _, prod in pairs(MonetizationConfig.DeveloperProducts) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
			card.Parent = shopBody
			rounded(card, 12)

			local topBar = Instance.new("Frame")
			topBar.Size = UDim2.new(1, 0, 0, 5)
			topBar.BackgroundColor3 = Color3.fromRGB(72, 170, 255)
			topBar.BorderSizePixel = 0
			topBar.Parent = card
			local tbc = Instance.new("UICorner")
			tbc.CornerRadius = UDim.new(0, 10)
			tbc.Parent = topBar

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Position = UDim2.new(0, 8, 0, 8)
			nameLbl.Size = UDim2.new(1, -16, 0, 22)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextColor3 = Color3.fromRGB(255, 230, 120)
			nameLbl.TextScaled = true
			nameLbl.Text = prod.Name
			nameLbl.Parent = card

			local priceLbl = Instance.new("TextLabel")
			priceLbl.Position = UDim2.new(0, 8, 0, 30)
			priceLbl.Size = UDim2.new(1, -16, 0, 16)
			priceLbl.BackgroundTransparency = 1
			priceLbl.Font = Enum.Font.GothamBold
			priceLbl.TextColor3 = Color3.fromRGB(100, 240, 140)
			priceLbl.TextScaled = true
			priceLbl.TextXAlignment = Enum.TextXAlignment.Left
			priceLbl.Text = "R$ " .. prod.PriceRobux .. " (Instant)"
			priceLbl.Parent = card

			local descLbl = Instance.new("TextLabel")
			descLbl.Position = UDim2.new(0, 8, 0, 48)
			descLbl.Size = UDim2.new(1, -16, 0, 42)
			descLbl.BackgroundTransparency = 1
			descLbl.Font = Enum.Font.Gotham
			descLbl.TextColor3 = Color3.fromRGB(200, 190, 210)
			descLbl.TextScaled = true
			descLbl.Text = prod.Description
			descLbl.Parent = card

			local actBox = Instance.new("Frame")
			actBox.Position = UDim2.new(0, 8, 0, 96)
			actBox.Size = UDim2.new(1, -16, 0, 30)
			actBox.BackgroundTransparency = 1
			actBox.Parent = card

			createButton(actBox, "BUY (R$ " .. prod.PriceRobux .. ")", Color3.fromRGB(255, 180, 50), Color3.fromRGB(25, 18, 36), function()
				if prod.Id and prod.Id > 0 then
					MarketplaceService:PromptProductPurchase(player, prod.Id)
				else
					detailText.Text = "Product configured! Set product ID in MonetizationConfig.lua."
				end
			end)
		end

	elseif currentShopCategory == "EMOTES" then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.31, 0, 0, 125)
		grid.CellPadding = UDim2.new(0, 10, 0, 10)
		grid.Parent = shopBody

		local emotesList = {
			{ Key = "OBJECTION", Name = "Point Objection!", Type = "Standard", IsFree = true },
			{ Key = "GAVEL_SLAM", Name = "Slam Gavel", Type = "Standard", IsFree = true },
			{ Key = "DANCE", Name = "Victory Dance", Type = "Standard", IsFree = true },
			{ Key = "LAUGH", Name = "Laugh at Court", Type = "Standard", IsFree = true },
			{ Key = "CRY", Name = "Dramatic Cry", Type = "Standard", IsFree = true },
			{ Key = "FACEPALM", Name = "Facepalm", Type = "Standard", IsFree = true },
			{ Key = "VIP_BOW", Name = "Aristocrat Bow", Type = "Premium", IsFree = false },
			{ Key = "CHAMPAGNE", Name = "Pop Champagne", Type = "Premium", IsFree = false },
			{ Key = "MIC_DROP", Name = "Supreme Mic Drop", Type = "Premium", IsFree = false },
		}

		local ownsPass = localProfile.OwnedGamePasses and localProfile.OwnedGamePasses.PREMIUM_EMOTES

		for _, em in ipairs(emotesList) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
			card.Parent = shopBody
			rounded(card, 12)

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Position = UDim2.new(0, 8, 0, 8)
			nameLbl.Size = UDim2.new(1, -16, 0, 22)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextColor3 = em.IsFree and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(255, 215, 0)
			nameLbl.TextScaled = true
			nameLbl.Text = em.Name
			nameLbl.Parent = card

			local tagLbl = Instance.new("TextLabel")
			tagLbl.Position = UDim2.new(0, 8, 0, 32)
			tagLbl.Size = UDim2.new(1, -16, 0, 16)
			tagLbl.BackgroundTransparency = 1
			tagLbl.Font = Enum.Font.Gotham
			tagLbl.TextColor3 = em.IsFree and Color3.fromRGB(160, 230, 160) or Color3.fromRGB(255, 105, 180)
			tagLbl.TextScaled = true
			tagLbl.TextXAlignment = Enum.TextXAlignment.Left
			tagLbl.Text = em.IsFree and "FREE / UNLOCKED" or "PREMIUM EMOTE"
			tagLbl.Parent = card

			local actBox = Instance.new("Frame")
			actBox.Position = UDim2.new(0, 8, 0, 80)
			actBox.Size = UDim2.new(1, -16, 0, 32)
			actBox.BackgroundTransparency = 1
			actBox.Parent = card

			local canPlay = em.IsFree or isPlayerVIP or ownsPass
			if canPlay then
				createButton(actBox, "PLAY EMOTE", Color3.fromRGB(72, 170, 255), Color3.fromRGB(255, 255, 255), function()
					actionRemote:FireServer("PlayEmote", em.Key)
				end)
			else
				createButton(actBox, "🔒 PASS REQUIRED", Color3.fromRGB(80, 60, 90), Color3.fromRGB(180, 170, 190), function()
					currentShopCategory = "PASSES"
					renderShopCategories()
					renderShop()
				end)
			end
		end

	else
		-- Cosmetics Catalog categories: GAVEL, CHARACTER, THEME
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.31, 0, 0, 120)
		grid.CellPadding = UDim2.new(0, 10, 0, 10)
		grid.Parent = shopBody

		local items = {}
		if currentShopCategory == "GAVEL" then
			items = CosmeticsCatalog.GetByCategory("Gavel")
		elseif currentShopCategory == "CHARACTER" then
			for _, item in ipairs(CosmeticsCatalog.GetAll()) do
				if item.Category == "Briefcase" or item.Category == "Aura" or item.Category == "Title" then
					table.insert(items, item)
				end
			end
		elseif currentShopCategory == "THEME" then
			items = CosmeticsCatalog.GetByCategory("Theme")
		end

		for _, item in ipairs(items) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
			card.Parent = shopBody
			rounded(card, 12)

			local rarityBar = Instance.new("Frame")
			rarityBar.Size = UDim2.new(1, 0, 0, 5)
			rarityBar.BackgroundColor3 = (CosmeticsCatalog.Rarities[item.Rarity] and CosmeticsCatalog.Rarities[item.Rarity].Color) or Color3.fromRGB(180, 180, 180)
			rarityBar.BorderSizePixel = 0
			rarityBar.Parent = card
			local rarityCorner = Instance.new("UICorner")
			rarityCorner.CornerRadius = UDim.new(0, 10)
			rarityCorner.Parent = rarityBar

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Position = UDim2.new(0, 8, 0, 8)
			nameLabel.Size = UDim2.new(1, -16, 0, 22)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextColor3 = item.Color or Color3.fromRGB(255, 255, 255)
			nameLabel.TextScaled = true
			nameLabel.Text = item.Name
			nameLabel.Parent = card

			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Position = UDim2.new(0, 8, 0, 32)
			rarityLabel.Size = UDim2.new(1, -16, 0, 16)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Font = Enum.Font.Gotham
			rarityLabel.TextColor3 = (CosmeticsCatalog.Rarities[item.Rarity] and CosmeticsCatalog.Rarities[item.Rarity].Color) or Color3.fromRGB(180, 180, 180)
			rarityLabel.TextScaled = true
			rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
			rarityLabel.Text = item.Rarity or "Common"
			rarityLabel.Parent = card

			local descLabel = Instance.new("TextLabel")
			descLabel.Position = UDim2.new(0, 8, 0, 50)
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
			actionContainer.Position = UDim2.new(0, 8, 0, 84)
			actionContainer.Size = UDim2.new(1, -16, 0, 28)
			actionContainer.BackgroundTransparency = 1
			actionContainer.Parent = card

			if item.VIPOnly and not isPlayerVIP then
				createButton(actionContainer, "👑 VIP ONLY", Color3.fromRGB(80, 60, 90), Color3.fromRGB(180, 170, 190), function()
					currentShopCategory = "VIP"
					renderShopCategories()
					renderShop()
				end)
			elseif isEquipped then
				createButton(actionContainer, "✓ EQUIPPED", Color3.fromRGB(60, 140, 80), Color3.fromRGB(255, 255, 255), nil)
			elseif isOwned then
				createButton(actionContainer, "EQUIP", Color3.fromRGB(72, 170, 255), Color3.fromRGB(255, 255, 255), function()
					actionRemote:FireServer("EquipItem", { Category = item.Category, ItemId = item.Id })
				end)
			else
				local priceText = (item.Price == 0) and "FREE" or ("🪙 " .. item.Price)
				local canAfford = (localProfile.Braincoins or 0) >= item.Price
				createButton(actionContainer, priceText,
					canAfford and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(80, 70, 90),
					Color3.fromRGB(25, 18, 36),
					canAfford and function()
						actionRemote:FireServer("BuyItem", item.Id)
						playSFX("BuyItem")
					end or nil
				)
			end
		end
	end
end

renderShopCategories()

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

-- ==================== LOBBY PLAYER LIST PANEL ====================
lobbyPanel = Instance.new("Frame")
lobbyPanel.Name = "LobbyPanel"
lobbyPanel.AnchorPoint = Vector2.new(1, 0.5)
lobbyPanel.Position = UDim2.new(1, -18, 0.5, 0)
lobbyPanel.Size = UDim2.new(0, 220, 0.52, 0)
lobbyPanel.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
lobbyPanel.BackgroundTransparency = 0.1
lobbyPanel.Visible = false
lobbyPanel.Parent = root
rounded(lobbyPanel, 14)

local lobbyTitle = Instance.new("TextLabel")
lobbyTitle.Position = UDim2.new(0, 0, 0, 0)
lobbyTitle.Size = UDim2.new(1, 0, 0, 36)
lobbyTitle.BackgroundTransparency = 1
lobbyTitle.Font = Enum.Font.GothamBlack
lobbyTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
lobbyTitle.TextScaled = true
lobbyTitle.Text = "⚖️ PLAYERS IN LOBBY"
lobbyTitle.Parent = lobbyPanel

local lobbyScroll = Instance.new("ScrollingFrame")
lobbyScroll.Position = UDim2.new(0, 8, 0, 42)
lobbyScroll.Size = UDim2.new(1, -16, 1, -50)
lobbyScroll.BackgroundTransparency = 1
lobbyScroll.BorderSizePixel = 0
lobbyScroll.ScrollBarThickness = 4
lobbyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
lobbyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
lobbyScroll.Parent = lobbyPanel

local lobbyList = Instance.new("UIListLayout")
lobbyList.Padding = UDim.new(0, 6)
lobbyList.SortOrder = Enum.SortOrder.LayoutOrder
lobbyList.Parent = lobbyScroll

-- PHASE 16 FIX: Reuse existing row frames to prevent unnecessary GUI destruction and memory churn
local lastLobbySignature = ""
local function updateLobbyList(state)
	local players = Players:GetPlayers()
	local sigParts = {}
	for _, p in ipairs(players) do
		local r = (state and state.Roles and state.Roles[p.UserId]) or ""
		table.insert(sigParts, p.UserId .. ":" .. r)
	end
	local sig = table.concat(sigParts, "|")
	if sig == lastLobbySignature then return end
	lastLobbySignature = sig

	local existingRows = {}
	for _, child in ipairs(lobbyScroll:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(existingRows, child)
		end
	end

	for i, p in ipairs(players) do
		local roleStr = ""
		if state and state.Roles and state.Roles[p.UserId] then
			roleStr = " [" .. state.Roles[p.UserId] .. "]"
		end
		local row = existingRows[i]
		if not row then
			row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 36)
			rounded(row, 8)
			local lbl = Instance.new("TextLabel")
			lbl.Name = "Label"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBold
			lbl.TextScaled = true
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = row
			row.Parent = lobbyScroll
		end
		row.BackgroundColor3 = (p == player) and Color3.fromRGB(55, 40, 80) or Color3.fromRGB(34, 25, 48)
		local lbl = row:FindFirstChild("Label")
		if lbl then
			lbl.TextColor3 = (p == player) and Color3.fromRGB(255, 230, 100) or Color3.fromRGB(240, 230, 255)
			lbl.Text = "  " .. p.DisplayName .. roleStr
		end
	end

	for i = #players + 1, #existingRows do
		existingRows[i]:Destroy()
	end
end

-- ==================== TRIAL SIDE PANELS (WITNESS & EVIDENCE) ====================
trialSidePanel = Instance.new("Frame")
trialSidePanel.Name = "TrialSidePanel"
trialSidePanel.AnchorPoint = Vector2.new(0, 0.5)
trialSidePanel.Position = UDim2.new(0, 18, 0.5, 0)
trialSidePanel.Size = UDim2.new(0, 220, 0.6, 0)
trialSidePanel.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
trialSidePanel.BackgroundTransparency = 0.1
trialSidePanel.Visible = false
trialSidePanel.Parent = root
rounded(trialSidePanel, 14)

local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 10)
sideList.Parent = trialSidePanel

-- Section: Argument Scores
local scoreSection = Instance.new("Frame")
scoreSection.Size = UDim2.new(1, 0, 0, 72)
scoreSection.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
scoreSection.Parent = trialSidePanel
rounded(scoreSection, 10)

local scoreTitleLbl = Instance.new("TextLabel")
scoreTitleLbl.Size = UDim2.new(1, 0, 0, 24)
scoreTitleLbl.BackgroundTransparency = 1
scoreTitleLbl.Font = Enum.Font.GothamBold
scoreTitleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
scoreTitleLbl.TextScaled = true
scoreTitleLbl.Text = "⚔️ ARGUMENT SCORES"
scoreTitleLbl.Parent = scoreSection

local prosecutorScoreLbl = Instance.new("TextLabel")
prosecutorScoreLbl.Position = UDim2.new(0, 8, 0, 26)
prosecutorScoreLbl.Size = UDim2.new(1, -16, 0, 20)
prosecutorScoreLbl.BackgroundTransparency = 1
prosecutorScoreLbl.Font = Enum.Font.Gotham
prosecutorScoreLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
prosecutorScoreLbl.TextScaled = true
prosecutorScoreLbl.TextXAlignment = Enum.TextXAlignment.Left
prosecutorScoreLbl.Text = "🔴 Prosecution: 0"
prosecutorScoreLbl.Parent = scoreSection

local defenseScoreLbl = Instance.new("TextLabel")
defenseScoreLbl.Position = UDim2.new(0, 8, 0, 48)
defenseScoreLbl.Size = UDim2.new(1, -16, 0, 20)
defenseScoreLbl.BackgroundTransparency = 1
defenseScoreLbl.Font = Enum.Font.Gotham
defenseScoreLbl.TextColor3 = Color3.fromRGB(72, 224, 214)
defenseScoreLbl.TextScaled = true
defenseScoreLbl.TextXAlignment = Enum.TextXAlignment.Left
defenseScoreLbl.Text = "🔵 Defense: 0"
defenseScoreLbl.Parent = scoreSection

-- Section: Active Evidence
local evidenceSection = Instance.new("Frame")
evidenceSection.Size = UDim2.new(1, 0, 0, 90)
evidenceSection.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
evidenceSection.Parent = trialSidePanel
rounded(evidenceSection, 10)

local evidenceTitleLbl = Instance.new("TextLabel")
evidenceTitleLbl.Size = UDim2.new(1, 0, 0, 24)
evidenceTitleLbl.BackgroundTransparency = 1
evidenceTitleLbl.Font = Enum.Font.GothamBold
evidenceTitleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
evidenceTitleLbl.TextScaled = true
evidenceTitleLbl.Text = "📁 ACTIVE EXHIBIT"
evidenceTitleLbl.Parent = evidenceSection

local evidenceNameLbl = Instance.new("TextLabel")
evidenceNameLbl.Position = UDim2.new(0, 8, 0, 26)
evidenceNameLbl.Size = UDim2.new(1, -16, 0, 22)
evidenceNameLbl.BackgroundTransparency = 1
evidenceNameLbl.Font = Enum.Font.GothamBold
evidenceNameLbl.TextColor3 = Color3.fromRGB(255, 180, 60)
evidenceNameLbl.TextScaled = true
evidenceNameLbl.TextXAlignment = Enum.TextXAlignment.Left
evidenceNameLbl.Text = "None presented"
evidenceNameLbl.Parent = evidenceSection

local evidenceDescLbl = Instance.new("TextLabel")
evidenceDescLbl.Position = UDim2.new(0, 8, 0, 50)
evidenceDescLbl.Size = UDim2.new(1, -16, 0, 36)
evidenceDescLbl.BackgroundTransparency = 1
evidenceDescLbl.Font = Enum.Font.Gotham
evidenceDescLbl.TextColor3 = Color3.fromRGB(210, 200, 220)
evidenceDescLbl.TextScaled = true
evidenceDescLbl.TextXAlignment = Enum.TextXAlignment.Left
evidenceDescLbl.TextYAlignment = Enum.TextYAlignment.Top
evidenceDescLbl.Text = "Present evidence to investigate."
evidenceDescLbl.Parent = evidenceSection

-- Section: Witness Responses Log
local witnessSection = Instance.new("Frame")
witnessSection.Size = UDim2.new(1, 0, 0, 160)
witnessSection.BackgroundColor3 = Color3.fromRGB(34, 25, 48)
witnessSection.Parent = trialSidePanel
rounded(witnessSection, 10)

local witnessTitleLbl = Instance.new("TextLabel")
witnessTitleLbl.Size = UDim2.new(1, 0, 0, 24)
witnessTitleLbl.BackgroundTransparency = 1
witnessTitleLbl.Font = Enum.Font.GothamBold
witnessTitleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
witnessTitleLbl.TextScaled = true
witnessTitleLbl.Text = "👁️ WITNESS LOG"
witnessTitleLbl.Parent = witnessSection

local witnessScroll = Instance.new("ScrollingFrame")
witnessScroll.Position = UDim2.new(0, 4, 0, 26)
witnessScroll.Size = UDim2.new(1, -8, 1, -30)
witnessScroll.BackgroundTransparency = 1
witnessScroll.BorderSizePixel = 0
witnessScroll.ScrollBarThickness = 3
witnessScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
witnessScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
witnessScroll.Parent = witnessSection

local witnessLogList = Instance.new("UIListLayout")
witnessLogList.Padding = UDim.new(0, 4)
witnessLogList.Parent = witnessScroll

local witnessResponseLog = {} -- last N entries

local function appendWitnessLog(entry)
	table.insert(witnessResponseLog, entry)
	if #witnessResponseLog > 6 then table.remove(witnessResponseLog, 1) end

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = entry.Contradiction and Color3.fromRGB(80, 20, 20) or Color3.fromRGB(28, 20, 40)
	rounded(row, 6)

	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Gotham
	t.TextColor3 = entry.Contradiction and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 215, 230)
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = "  " .. entry.Witness .. ": " .. entry.Answer .. (entry.Contradiction and " ⚠️" or "")
	t.Parent = row
	row.Parent = witnessScroll

	local frameChildren = {}
	for _, child in ipairs(witnessScroll:GetChildren()) do
		if child:IsA("Frame") then table.insert(frameChildren, child) end
	end
	if #frameChildren > 6 then
		frameChildren[1]:Destroy()
	end
end

-- ==================== POST-ROUND LEADERBOARD / AWARDS PANEL ====================
local awardsPanel = Instance.new("Frame")
awardsPanel.Name = "AwardsPanel"
awardsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
awardsPanel.Position = UDim2.fromScale(0.5, 0.5)
awardsPanel.Size = UDim2.new(0.6, 0, 0.7, 0)
awardsPanel.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
awardsPanel.BackgroundTransparency = 0.05
awardsPanel.Visible = false
awardsPanel.ZIndex = 6
awardsPanel.Parent = root
rounded(awardsPanel, 20)

local awardsTitleLbl = Instance.new("TextLabel")
awardsTitleLbl.Position = UDim2.new(0, 0, 0, 12)
awardsTitleLbl.Size = UDim2.new(1, 0, 0, 44)
awardsTitleLbl.BackgroundTransparency = 1
awardsTitleLbl.Font = Enum.Font.GothamBlack
awardsTitleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
awardsTitleLbl.TextScaled = true
awardsTitleLbl.Text = "🏆 COURT AWARDS"
awardsTitleLbl.ZIndex = 7
awardsTitleLbl.Parent = awardsPanel

local awardsScroll = Instance.new("ScrollingFrame")
awardsScroll.Position = UDim2.new(0.04, 0, 0, 68)
awardsScroll.Size = UDim2.new(0.92, 0, 1, -84)
awardsScroll.BackgroundTransparency = 1
awardsScroll.BorderSizePixel = 0
awardsScroll.ScrollBarThickness = 5
awardsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
awardsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
awardsScroll.ZIndex = 7
awardsScroll.Parent = awardsPanel

local awardsListLayout = Instance.new("UIListLayout")
awardsListLayout.Padding = UDim.new(0, 10)
awardsListLayout.Parent = awardsScroll

local function showAwardsPanel(awards)
	if not awards or #awards == 0 then return end
	playSFX("Reward")

	-- Clean up previous card frames while keeping layout intact
	for _, child in ipairs(awardsScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, award in ipairs(awards) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 68)
		card.BackgroundColor3 = Color3.fromRGB(44, 32, 65)
		card.ZIndex = 8
		card.Parent = awardsScroll
		rounded(card, 12)

		local medal = Instance.new("TextLabel")
		medal.Position = UDim2.new(0, 10, 0, 10)
		medal.Size = UDim2.new(0, 44, 0, 44)
		medal.BackgroundTransparency = 1
		medal.Font = Enum.Font.GothamBlack
		medal.TextScaled = true
		medal.ZIndex = 9
		medal.Text = i == 1 and "🥇" or (i == 2 and "🥈" or (i == 3 and "🥉" or "⭐"))
		medal.Parent = card

		local aTitle = Instance.new("TextLabel")
		aTitle.Position = UDim2.new(0, 62, 0, 8)
		aTitle.Size = UDim2.new(1, -70, 0, 28)
		aTitle.BackgroundTransparency = 1
		aTitle.Font = Enum.Font.GothamBold
		aTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		aTitle.TextScaled = true
		aTitle.TextXAlignment = Enum.TextXAlignment.Left
		aTitle.ZIndex = 9
		aTitle.Text = award.Title or "Award"
		aTitle.Parent = card

		local aWinner = Instance.new("TextLabel")
		aWinner.Position = UDim2.new(0, 62, 0, 36)
		aWinner.Size = UDim2.new(1, -70, 0, 24)
		aWinner.BackgroundTransparency = 1
		aWinner.Font = Enum.Font.Gotham
		aWinner.TextColor3 = Color3.fromRGB(220, 220, 240)
		aWinner.TextScaled = true
		aWinner.TextXAlignment = Enum.TextXAlignment.Left
		aWinner.ZIndex = 9
		aWinner.Text = (award.Winner or "???") .. " — +" .. (award.Bonus or 0) .. " 🪙"
		aWinner.Parent = card
	end

	awardsPanel.Visible = true
	TweenService:Create(awardsPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.6, 0, 0.7, 0),
	}):Play()

	task.delay(10, function()
		if awardsPanel.Parent then
			TweenService:Create(awardsPanel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			}):Play()
			task.wait(0.4)
			awardsPanel.Visible = false
			awardsPanel.BackgroundTransparency = 0.05
		end
	end)
end

-- ==================== SPECTATOR FOLLOW-CAMERA ====================
-- PHASE 16 FIX: High-performance RenderStepped interpolation, zero tween spam, safe disconnect
local spectatorFollowActive = false
local spectatorTargetIndex = 1
local spectatorRenderConn = nil
local isCinematicPlaying = false
local spectatorUI, specWatchingLbl

local function getFollowablePlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character.PrimaryPart then
			table.insert(list, p)
		end
	end
	return list
end

local function stopSpectatorCamera()
	spectatorFollowActive = false
	if spectatorRenderConn then
		spectatorRenderConn:Disconnect()
		spectatorRenderConn = nil
	end
	spectatorUI.Visible = false
	camera.CameraType = Enum.CameraType.Custom
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		camera.CameraSubject = hum
	end
end

local function startSpectatorCamera()
	if spectatorFollowActive or isCinematicPlaying then return end
	spectatorFollowActive = true
	camera.CameraType = Enum.CameraType.Scriptable
	spectatorUI.Visible = true

	spectatorRenderConn = RunService.RenderStepped:Connect(function(dt)
		if not spectatorFollowActive or isCinematicPlaying then return end
		local targets = getFollowablePlayers()
		if #targets == 0 then
			local desiredCF = CFrame.lookAt(Vector3.new(0, 22, -45), Vector3.new(0, 8, 10))
			camera.CFrame = camera.CFrame:Lerp(desiredCF, math.clamp(dt * 6, 0.05, 1))
			specWatchingLbl.Text = "👁️ COURTROOM"
			return
		end
		spectatorTargetIndex = math.clamp(spectatorTargetIndex, 1, #targets)
		local targetPlayer = targets[spectatorTargetIndex]
		local targetChar = targetPlayer and targetPlayer.Character
		local rootPart = targetChar and targetChar.PrimaryPart
		if rootPart then
			specWatchingLbl.Text = "👁️ " .. string.sub(targetPlayer.DisplayName, 1, 10)
			local targetPos = rootPart.Position
			local desiredCF = CFrame.lookAt(targetPos + Vector3.new(0, 8, 16), targetPos + Vector3.new(0, 2, 0))
			camera.CFrame = camera.CFrame:Lerp(desiredCF, math.clamp(dt * 5, 0.05, 1))
		end
	end)
end

-- Spectator next/prev target UI
spectatorUI = Instance.new("Frame")
spectatorUI.Name = "SpectatorUI"
spectatorUI.AnchorPoint = Vector2.new(0.5, 1)
spectatorUI.Position = UDim2.fromScale(0.5, 0.86)
spectatorUI.Size = UDim2.new(0, 300, 0, 50)
spectatorUI.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
spectatorUI.BackgroundTransparency = 0.15
spectatorUI.Visible = false
spectatorUI.Parent = root
rounded(spectatorUI, 14)

local specLayout = Instance.new("UIListLayout")
specLayout.FillDirection = Enum.FillDirection.Horizontal
specLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
specLayout.VerticalAlignment = Enum.VerticalAlignment.Center
specLayout.Padding = UDim.new(0, 10)
specLayout.Parent = spectatorUI

local prevSpecBtn = Instance.new("Frame")
prevSpecBtn.Size = UDim2.new(0, 80, 0, 36)
prevSpecBtn.BackgroundTransparency = 1
prevSpecBtn.Parent = spectatorUI
createButton(prevSpecBtn, "◀ PREV", Color3.fromRGB(55, 40, 80), Color3.fromRGB(240, 230, 255), function()
	local targets = getFollowablePlayers()
	if #targets > 0 then
		spectatorTargetIndex = ((spectatorTargetIndex - 2) % #targets) + 1
	end
end)

specWatchingLbl = Instance.new("TextLabel")
specWatchingLbl.Size = UDim2.new(0, 110, 0, 36)
specWatchingLbl.BackgroundTransparency = 1
specWatchingLbl.Font = Enum.Font.GothamBold
specWatchingLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
specWatchingLbl.TextScaled = true
specWatchingLbl.Text = "👁️ SPECTATING"
specWatchingLbl.Parent = spectatorUI

local nextSpecBtn = Instance.new("Frame")
nextSpecBtn.Size = UDim2.new(0, 80, 0, 36)
nextSpecBtn.BackgroundTransparency = 1
nextSpecBtn.Parent = spectatorUI
createButton(nextSpecBtn, "NEXT ▶", Color3.fromRGB(55, 40, 80), Color3.fromRGB(240, 230, 255), function()
	local targets = getFollowablePlayers()
	if #targets > 0 then
		spectatorTargetIndex = (spectatorTargetIndex % #targets) + 1
	end
end)

-- ==================== BRIEFING CINEMATIC CAMERA ====================
-- PHASE 16 FIX: Resolves conflict with spectator follow camera and safely returns camera
local function playCinematicBriefing()
	isCinematicPlaying = true
	if spectatorFollowActive then
		stopSpectatorCamera()
	end
	camera.CameraType = Enum.CameraType.Scriptable

	local shots = {
		{ CFrame.new(0, 20, 55), CFrame.new(0, 12, 36) },
		{ CFrame.new(-40, 10, 15), CFrame.new(0, 8, 0) },
		{ CFrame.new(40, 10, 15), CFrame.new(0, 8, 0) },
		{ CFrame.new(0, 8, -15), CFrame.new(0, 8, 36) },
	}

	task.spawn(function()
		for _, shot in ipairs(shots) do
			if not isCinematicPlaying then break end
			local from = shot[1]
			local lookAt = shot[2]
			local cf = CFrame.lookAt(from, lookAt.Position)
			TweenService:Create(camera, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				CFrame = cf,
			}):Play()
			task.wait(1.4)
		end
		isCinematicPlaying = false

		-- Return camera cleanly based on current role and phase
		local currentRole = lastState and lastState.Roles and lastState.Roles[player.UserId] or "Spectator"
		local isMatchActive = (lastState and (lastState.Phase == "Trial" or lastState.Phase == "Voting" or lastState.Phase == "Verdict" or lastState.Phase == "Rewards"))
		if isMatchActive and currentRole == "Spectator" then
			startSpectatorCamera()
		else
			camera.CameraType = Enum.CameraType.Custom
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then camera.CameraSubject = hum end
		end
	end)
end

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
			playCinematicBriefing()
		elseif state.Phase == "Rewards" and state.Awards and #state.Awards > 0 then
			showAwardsPanel(state.Awards)
		elseif state.Phase == "Lobby" then
			isCinematicPlaying = false
			stopSpectatorCamera()
		end
	end

	phaseText.Text = string.format("⚖️ %s • %ss", state.Phase:upper(), state.TimeLeft or 0)

	local role = state.Roles and state.Roles[player.UserId] or "Spectator"
	local case = state.Case

	local isLobby = (state.Phase == "Lobby")
	local isTrial = (state.Phase == "Trial")
	local isVoting = (state.Phase == "Voting")
	local isMatchActive = (isTrial or isVoting or state.Phase == "Verdict" or state.Phase == "Rewards")
	local isGenuineSpectator = isMatchActive and (role == "Spectator")
	local isJury = (role == "Jury")
	local isJudge = (role == "Judge")
	local isLawyer = (role == "Prosecutor" or role == "Defense")
	local isDefendant = (role == "Defendant")

	-- Lobby player list
	lobbyPanel.Visible = isLobby
	if isLobby then
		updateLobbyList(state)
	end

	-- Trial side panel
	trialSidePanel.Visible = isTrial
	if isTrial then
		-- Update argument scores
		local pScore = state.ArgumentScores and state.ArgumentScores.Prosecutor or 0
		local dScore = state.ArgumentScores and state.ArgumentScores.Defense or 0
		prosecutorScoreLbl.Text = "🔴 Prosecution: " .. pScore
		defenseScoreLbl.Text = "🔵 Defense: " .. dScore

		-- Update active evidence
		if state.EvidenceInspection and state.EvidenceInspection.Name then
			evidenceNameLbl.Text = "📄 " .. state.EvidenceInspection.Name
			evidenceDescLbl.Text = state.EvidenceInspection.Detail or ""
		elseif case and state.ActiveEvidence and case.Evidence and case.Evidence[state.ActiveEvidence] then
			local ev = case.Evidence[state.ActiveEvidence]
			evidenceNameLbl.Text = "📄 " .. ev.Name
			evidenceDescLbl.Text = ev.Description or ""
		else
			evidenceNameLbl.Text = "No exhibit presented"
			evidenceDescLbl.Text = "Present evidence to investigate."
		end

		-- Append new witness responses
		if state.WitnessResponses then
			local prevCount = #witnessResponseLog
			local newCount = #state.WitnessResponses
			if newCount > prevCount then
				for i = prevCount + 1, newCount do
					appendWitnessLog(state.WitnessResponses[i])
				end
			elseif newCount == 0 then
				witnessResponseLog = {}
				for _, child in ipairs(witnessScroll:GetChildren()) do
					if child:IsA("Frame") then child:Destroy() end
				end
			end
		end
	end

	-- PHASE 16 FIX: Spectator camera ONLY activates for genuine spectators in active match (never in lobby)
	if isGenuineSpectator and not spectatorFollowActive and not isCinematicPlaying then
		startSpectatorCamera()
	elseif (not isGenuineSpectator or isLobby) and spectatorFollowActive then
		stopSpectatorCamera()
	end

	if state.Phase == "Lobby" then
		detailText.Text = string.format("Waiting for players... (%d/%d)", #Players:GetPlayers(), Config.MinPlayers)
	elseif state.Phase == "Briefing" and case then
		detailText.Text = string.format("[%s] CASE: %s - %s", role:upper(), case.Crime, case.Briefing)
	elseif state.Phase == "Trial" and case then
		local ev = (state.ActiveEvidence and case.Evidence and case.Evidence[state.ActiveEvidence])
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
	elseif effectType == "Awards" and type(arg1) == "table" then
		showAwardsPanel(arg1)
	end
end)

-- Initial UI population
renderShop()
renderMissions()
renderProfile()

-- ==================== MARKETPLACE LISTENERS ====================
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, passId, wasPurchased)
	if wasPurchased then
		actionRemote:FireServer("CheckGamePasses")
		detailText.Text = "🎉 GAME PASS PURCHASE DETECTED! Syncing perks..."
		playSFX("CashEarned")
		if shopModal.Visible then renderShop() end
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, productId, wasPurchased)
	if wasPurchased then
		detailText.Text = "🪙 TRANSACTION SUBMITTED! Server processing delivery..."
		playSFX("CashEarned")
	end
end)
