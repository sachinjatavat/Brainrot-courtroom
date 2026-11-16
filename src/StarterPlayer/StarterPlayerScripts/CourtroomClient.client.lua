local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("CourtroomRemotes")
local stateRemote, actionRemote, notificationRemote = remotes:WaitForChild("CourtroomState"), remotes:WaitForChild("CourtroomAction"), remotes:WaitForChild("CourtroomNotification")

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "CourtroomInterface", false
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Size, root.BackgroundColor3, root.BackgroundTransparency = UDim2.fromScale(1, 1), Color3.new(0, 0, 0), 1
root.Parent = gui
local panel = Instance.new("Frame")
panel.AnchorPoint, panel.Position, panel.Size = Vector2.new(.5, 0), UDim2.fromScale(.5, .04), UDim2.fromScale(.62, .2)
panel.BackgroundColor3, panel.BackgroundTransparency = Color3.fromRGB(28, 22, 43), .08
panel.Parent = root
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
local title = Instance.new("TextLabel")
title.Size, title.BackgroundTransparency, title.Font, title.TextColor3, title.TextScaled = UDim2.fromScale(1, .35), 1, Enum.Font.GothamBlack, Color3.fromRGB(255, 210, 77), true
title.Text = "BRAINROT COURTROOM"
title.Parent = panel
local phase = title:Clone()
phase.Position, phase.Size, phase.Font, phase.TextColor3 = UDim2.fromScale(0, .35), UDim2.fromScale(1, .3), Enum.Font.GothamBold, Color3.fromRGB(255, 242, 205)
phase.Text = "Waiting for the jury..."
phase.Parent = panel
local detail = phase:Clone()
detail.Position, detail.Size, detail.TextColor3 = UDim2.fromScale(0, .65), UDim2.fromScale(1, .3), Color3.fromRGB(72, 224, 214)
detail.Text = ""
detail.Parent = panel
local actionBar = Instance.new("Frame")
actionBar.AnchorPoint, actionBar.Position, actionBar.Size, actionBar.BackgroundTransparency = Vector2.new(.5, 1), UDim2.fromScale(.5, .98), UDim2.fromScale(.8, .14), 1
actionBar.Parent = root
local function button(text, color, callback)
	local b = Instance.new("TextButton")
	b.Size, b.BackgroundColor3, b.TextColor3, b.Font, b.TextScaled = UDim2.fromScale(.22, 1), color, Color3.fromRGB(28, 22, 43), Enum.Font.GothamBlack, true
	b.Text = text
	b.Parent = actionBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	b.Activated:Connect(callback)
	return b
end
local layout = Instance.new("UIListLayout", actionBar)
layout.FillDirection, layout.HorizontalAlignment, layout.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, UDim.new(0, 10)
local guiltyButton = button("GUILTY", Color3.fromRGB(255, 91, 91), function() actionRemote:FireServer("Vote", "GUILTY") end)
local notGuiltyButton = button("NOT GUILTY", Color3.fromRGB(102, 224, 129), function() actionRemote:FireServer("Vote", "NOT_GUILTY") end)
local silenceButton = button("ORDER SILENCE", Color3.fromRGB(255, 210, 77), function() actionRemote:FireServer("JudgePower", "ORDER_SILENCE") end)
local bananaButton = button("BANANA", Color3.fromRGB(255, 193, 72), function() actionRemote:FireServer("JudgePower", "THROW_BANANA") end)

local function render(state)
	phase.Text = string.format("%s  •  %ss", state.Phase:upper(), state.TimeLeft or 0)
	local case = state.Case
	if case then
		local role = state.Roles and state.Roles[player.UserId] or "Spectator"
		detail.Text = string.format("%s | CASE: %s", role:upper(), case.Crime:upper())
		if state.Phase == "Briefing" then detail.Text = case.Briefing end
	end
	local role = state.Roles and state.Roles[player.UserId]
	local isJury = role == "Jury"
	local isJudge = role == "Judge"
	guiltyButton.Visible, notGuiltyButton.Visible = state.Phase == "Voting" and isJury, state.Phase == "Voting" and isJury
	silenceButton.Visible, bananaButton.Visible = state.Phase == "Trial" and isJudge, state.Phase == "Trial" and isJudge
	actionBar.Visible = isJury and state.Phase == "Voting" or isJudge and state.Phase == "Trial"
	if state.Chaos then detail.Text = "⚡ CHAOS: " .. state.Chaos:gsub("_", " ") .. " ⚡" end
end
stateRemote.OnClientEvent:Connect(render)
notificationRemote.OnClientEvent:Connect(function(message)
	detail.Text = tostring(message)
	local original = detail.TextColor3
	detail.TextColor3 = Color3.fromRGB(255, 105, 180)
	TweenService:Create(detail, TweenInfo.new(1.2), { TextColor3 = original }):Play()
end)
