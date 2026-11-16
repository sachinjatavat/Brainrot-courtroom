local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Animations = {}

local activeTweens = {}

local function findMotors(character)
	local motors = {}
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") then
			motors[desc.Name] = desc
		end
	end
	return motors
end

local function restoreMotors(motors, originals, duration)
	for name, original in pairs(originals) do
		local motor = motors[name]
		if motor and motor.Parent then
			TweenService:Create(motor, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transform = original,
			}):Play()
		end
	end
end

local function spawnReactionBillboard(character, text, color, duration)
	local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ReactionEffect"
	billboard.Size = UDim2.fromScale(6, 2.5)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = character

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color or Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
	label.TextScaled = true
	label.Text = text
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	-- Pop in animation
	label.Size = UDim2.fromScale(0.2, 0.2)
	TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1, 1),
	}):Play()

	task.delay((duration or 2) - 0.3, function()
		if label.Parent then
			TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.fromScale(0.1, 0.1),
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end
	end)

	Debris:AddItem(billboard, duration or 2)
end

function Animations.Play(character, emoteName, duration)
	if not character or not character.Parent then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	duration = duration or 2
	local motors = findMotors(character)
	local originals = {}
	for name, motor in pairs(motors) do
		originals[name] = motor.Transform
	end

	if emoteName == "OBJECTION" then
		spawnReactionBillboard(character, "OBJECTION!", Color3.fromRGB(255, 50, 50), duration)
		local shoulder = motors["Right Shoulder"] or motors["RightShoulder"]
		local waist = motors["Waist"]
		local neck = motors["Neck"]

		if shoulder then
			TweenService:Create(shoulder, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Transform = CFrame.Angles(math.rad(90), 0, math.rad(-15)),
			}):Play()
		end
		if waist then
			TweenService:Create(waist, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				Transform = CFrame.Angles(0, math.rad(-15), 0),
			}):Play()
		end
		if neck then
			TweenService:Create(neck, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				Transform = CFrame.Angles(math.rad(5), math.rad(15), 0),
			}):Play()
		end

		task.delay(duration, function()
			restoreMotors(motors, originals, 0.3)
		end)

	elseif emoteName == "GAVEL_SLAM" then
		spawnReactionBillboard(character, "ORDER IN COURT!", Color3.fromRGB(255, 215, 0), duration)
		local shoulder = motors["Right Shoulder"] or motors["RightShoulder"]
		local waist = motors["Waist"]

		if shoulder then
			-- Raise high
			local upTween = TweenService:Create(shoulder, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transform = CFrame.Angles(math.rad(120), 0, math.rad(10)),
			})
			upTween:Play()
			upTween.Completed:Connect(function()
				-- Slam down fast
				TweenService:Create(shoulder, TweenInfo.new(0.12, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
					Transform = CFrame.Angles(math.rad(45), 0, 0),
				}):Play()
			end)
		end
		if waist then
			TweenService:Create(waist, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
				Transform = CFrame.Angles(math.rad(10), 0, 0),
			}):Play()
		end

		task.delay(duration, function()
			restoreMotors(motors, originals, 0.3)
		end)

	elseif emoteName == "CRY" then
		spawnReactionBillboard(character, "😭😭😭", Color3.fromRGB(72, 170, 255), duration)
		local neck = motors["Neck"]
		local waist = motors["Waist"]
		local rightShoulder = motors["Right Shoulder"] or motors["RightShoulder"]
		local leftShoulder = motors["Left Shoulder"] or motors["LeftShoulder"]

		if neck then
			TweenService:Create(neck, TweenInfo.new(0.3), { Transform = CFrame.Angles(math.rad(-30), 0, 0) }):Play()
		end
		if waist then
			TweenService:Create(waist, TweenInfo.new(0.3), { Transform = CFrame.Angles(math.rad(25), 0, 0) }):Play()
		end
		if rightShoulder and leftShoulder then
			TweenService:Create(rightShoulder, TweenInfo.new(0.3), { Transform = CFrame.Angles(math.rad(110), 0, math.rad(-40)) }):Play()
			TweenService:Create(leftShoulder, TweenInfo.new(0.3), { Transform = CFrame.Angles(math.rad(110), 0, math.rad(40)) }):Play()
		end

		-- Weep oscillation
		task.spawn(function()
			local endTime = os.clock() + duration
			while os.clock() < endTime and waist and waist.Parent do
				TweenService:Create(waist, TweenInfo.new(0.15), { Transform = CFrame.Angles(math.rad(28), 0, 0) }):Play()
				task.wait(0.15)
				TweenService:Create(waist, TweenInfo.new(0.15), { Transform = CFrame.Angles(math.rad(22), 0, 0) }):Play()
				task.wait(0.15)
			end
			restoreMotors(motors, originals, 0.3)
		end)

	elseif emoteName == "LAUGH" then
		spawnReactionBillboard(character, "HAHAHA! 🤣", Color3.fromRGB(255, 220, 50), duration)
		local neck = motors["Neck"]
		local waist = motors["Waist"]

		if neck then
			TweenService:Create(neck, TweenInfo.new(0.2), { Transform = CFrame.Angles(math.rad(25), 0, 0) }):Play()
		end

		task.spawn(function()
			local endTime = os.clock() + duration
			while os.clock() < endTime and waist and waist.Parent do
				TweenService:Create(waist, TweenInfo.new(0.1), { Transform = CFrame.Angles(math.rad(-10), 0, 0) }):Play()
				task.wait(0.1)
				TweenService:Create(waist, TweenInfo.new(0.1), { Transform = CFrame.Angles(math.rad(0), 0, 0) }):Play()
				task.wait(0.1)
			end
			restoreMotors(motors, originals, 0.3)
		end)

	elseif emoteName == "DANCE" then
		spawnReactionBillboard(character, "VICTORY DANCE! 🕺", Color3.fromRGB(105, 255, 140), duration)
		local rightShoulder = motors["Right Shoulder"] or motors["RightShoulder"]
		local leftShoulder = motors["Left Shoulder"] or motors["LeftShoulder"]
		local waist = motors["Waist"]

		task.spawn(function()
			local endTime = os.clock() + duration
			local step = 0
			while os.clock() < endTime and character.Parent do
				step = step + 1
				local angle = (step % 2 == 0) and 1 or -1
				if rightShoulder then
					TweenService:Create(rightShoulder, TweenInfo.new(0.2), { Transform = CFrame.Angles(math.rad(130 * angle), 0, math.rad(20)) }):Play()
				end
				if leftShoulder then
					TweenService:Create(leftShoulder, TweenInfo.new(0.2), { Transform = CFrame.Angles(math.rad(-130 * angle), 0, math.rad(-20)) }):Play()
				end
				if waist then
					TweenService:Create(waist, TweenInfo.new(0.2), { Transform = CFrame.Angles(0, math.rad(25 * angle), 0) }):Play()
				end
				task.wait(0.22)
			end
			restoreMotors(motors, originals, 0.3)
		end)

	elseif emoteName == "FACEPALM" then
		spawnReactionBillboard(character, "🤦‍♂️", Color3.fromRGB(220, 180, 140), duration)
		local leftShoulder = motors["Left Shoulder"] or motors["LeftShoulder"]
		local neck = motors["Neck"]

		if leftShoulder then
			TweenService:Create(leftShoulder, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				Transform = CFrame.Angles(math.rad(115), 0, math.rad(45)),
			}):Play()
		end
		if neck then
			TweenService:Create(neck, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				Transform = CFrame.Angles(math.rad(-15), 0, 0),
			}):Play()
		end

		task.delay(duration, function()
			restoreMotors(motors, originals, 0.3)
		end)
	end
end

return Animations
