local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")

local Color3 = roblox.Color3
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local UDim2 = roblox.UDim2
local UDim = roblox.UDim
local Enum = roblox.Enum
local mockEnum = {}
setmetatable(mockEnum, {
	__index = function(_, k)
		if Enum and Enum[k] then return Enum[k] end
		return {}
	end,
})
mockEnum.ProductPurchaseDecision = {
	PurchaseGranted = 0,
	NotProcessedYet = 1,
}

local function createMockInstance(className)
	local obj = {
		ClassName = className,
		Name = className,
		Children = {},
		Parent = nil,
		Anchored = false,
		CanCollide = false,
		Transparency = 0,
		Size = Vector3.new(2, 2, 1),
		Position = Vector3.new(0, 0, 0),
		CFrame = CFrame.new(0, 0, 0),
		Health = 100,
		MaxHealth = 100,
		WalkSpeed = 16,
		PlatformStand = false,
	}

	local mockSignal = {
		Connect = function(_, fn)
			return { Disconnect = function() end }
		end,
		Wait = function() return true end,
	}

	obj.Touched = mockSignal
	obj.MoveToFinished = mockSignal
	obj.OnServerEvent = mockSignal
	obj.OnClientEvent = mockSignal

	function obj:FireClient(...) end
	function obj:FireAllClients(...) end
	function obj:FireServer(...) end

	function obj:IsA(c) return self.ClassName == c end
	function obj:FindFirstChild(name, recursive)
		for _, c in ipairs(self.Children) do
			if c.Name == name then return c end
			if recursive and c.FindFirstChild then
				local sub = c:FindFirstChild(name, true)
				if sub then return sub end
			end
		end
		return nil
	end
	function obj:FindFirstChildOfClass(c)
		for _, child in ipairs(self.Children) do
			if child.ClassName == c then return child end
		end
		return nil
	end
	function obj:WaitForChild(name)
		local found = self:FindFirstChild(name)
		if not found then
			found = createMockInstance("Folder")
			found.Name = name
			found.Parent = self
			table.insert(self.Children, found)
		end
		return found
	end
	function obj:GetChildren() return self.Children end
	function obj:Destroy()
		self.Parent = nil
		self.Children = {}
	end
	function obj:PivotTo(cf) self.CFrame = cf end
	function obj:GetPivot() return self.CFrame or CFrame.new() end
	function obj:ScaleTo(s) self.Scale = s end
	function obj:GetScale() return self.Scale or 1 end
	function obj:MoveTo(pos) self.TargetPos = pos end
	function obj:ApplyImpulse(imp) self.Impulse = imp end

	setmetatable(obj, {
		__index = function(t, k)
			local child = t:FindFirstChild(k)
			if child then return child end
			return nil
		end,
		__newindex = function(t, k, v)
			if k == "Parent" and v ~= nil and type(v) == "table" and v.Children then
				table.insert(v.Children, t)
			end
			rawset(t, k, v)
		end,
	})
	return obj
end

-- Environment builder
local env = {}
env.Instance = { new = createMockInstance }
env.Color3 = Color3
env.Vector3 = Vector3
env.CFrame = CFrame
env.UDim2 = UDim2
env.UDim = UDim
env.Enum = mockEnum
env.TweenInfo = { new = function(...) return {} end }
env.PhysicalProperties = { new = function(...) return {} end }
env.math = math
env.table = table
env.string = string
env.os = os
env.task = {
	wait = function(s) return s or 0 end,
	delay = function(s, f) return f end,
	spawn = function(f) return f() end,
}

env.Random = {
	new = function(seed)
		local s = seed or os.time()
		local rng = {}
		function rng:NextInteger(min, max)
			s = (s * 1103515245 + 12345) % 2147483648
			local frac = s / 2147483648
			return min + math.floor(frac * (max - min + 1))
		end
		function rng:NextNumber(min, max)
			min = min or 0
			max = max or 1
			s = (s * 1103515245 + 12345) % 2147483648
			local frac = s / 2147483648
			return min + frac * (max - min)
		end
		return rng
	end,
}

env.assert = assert
env.pcall = pcall
env.xpcall = xpcall
env.type = type
env.typeof = typeof or type
env.tostring = tostring
env.tonumber = tonumber
env.ipairs = ipairs
env.pairs = pairs
env.next = next
env.select = select
env.warn = function(...) end
env.print = print

-- Game hierarchy
local gameDataModel = createMockInstance("DataModel")
local repStorage = createMockInstance("Folder")
repStorage.Name = "ReplicatedStorage"
repStorage.Parent = gameDataModel

local sharedFolder = createMockInstance("Folder")
sharedFolder.Name = "Shared"
sharedFolder.Parent = repStorage

local sss = createMockInstance("Folder")
sss.Name = "ServerScriptService"
sss.Parent = gameDataModel

local servicesFolder = createMockInstance("Folder")
servicesFolder.Name = "Services"
servicesFolder.Parent = sss

local testsFolder = createMockInstance("Folder")
testsFolder.Name = "Tests"
testsFolder.Parent = sss

local playersService = createMockInstance("Folder")
playersService.Name = "Players"
playersService.Parent = gameDataModel
playersService.PlayerAdded = {
	Connect = function(_, fn) return { Disconnect = function() end } end,
	Wait = function() return true end,
}
playersService.PlayerRemoving = {
	Connect = function(_, fn) return { Disconnect = function() end } end,
	Wait = function() return true end,
}
playersService.GetPlayers = function(self) return self.Children end
playersService.GetPlayerByUserId = function(self, uid)
	for _, c in ipairs(self.Children) do
		if c.UserId == uid then return c end
	end
	return nil
end

local workspaceMock = createMockInstance("Workspace")
workspaceMock.Gravity = 196.2
env.workspace = workspaceMock

local mockDataStoreStorage = {}

local registeredServices = {
	ReplicatedStorage = repStorage,
	ServerScriptService = sss,
	Players = playersService,
	Workspace = workspaceMock,
	TweenService = {
		Create = function(_, instance, _, props)
			return {
				Play = function()
					for k, v in pairs(props) do
						instance[k] = v
					end
				end,
				Completed = {
					Connect = function(_, cb)
						if cb then cb() end
						return { Disconnect = function() end }
					end,
				},
			}
		end,
	},
	DataStoreService = {
		GetDataStore = function(_, name)
			return {
				GetAsync = function(_, key)
					return mockDataStoreStorage[key]
				end,
				SetAsync = function(_, key, val)
					mockDataStoreStorage[key] = val
					return true
				end,
				UpdateAsync = function(_, key, transform)
					local current = mockDataStoreStorage[key]
					local transformed = transform(current)
					if transformed ~= nil then
						mockDataStoreStorage[key] = transformed
					end
					return transformed
				end,
			}
		end,
	},
	MarketplaceService = {
		ProcessReceipt = nil,
		UserOwnsGamePassAsync = function(_, userId, passId)
			return false
		end,
		PromptGamePassPurchase = function(_, player, passId) end,
		PromptProductPurchase = function(_, player, productId) end,
	},
}

env.game = {
	JobId = "TEST_SERVER_JOB_1",
	GetService = function(self, name)
		return registeredServices[name] or createMockInstance(name)
	end,
	BindToClose = function() end,
}

-- Module cache
local moduleCache = {}
local modulePaths = {
	Shared = "src/ReplicatedStorage/Shared/init.lua",
	Config = "src/ReplicatedStorage/Shared/Config.lua",
	Signal = "src/ReplicatedStorage/Shared/Signal.lua",
	CaseGenerator = "src/ReplicatedStorage/Shared/CaseGenerator.lua",
	RoleAssigner = "src/ReplicatedStorage/Shared/RoleAssigner.lua",
	Verdict = "src/ReplicatedStorage/Shared/Verdict.lua",
	Net = "src/ReplicatedStorage/Shared/Net.lua",
	WitnessMemory = "src/ReplicatedStorage/Shared/WitnessMemory.lua",
	ArgumentScoring = "src/ReplicatedStorage/Shared/ArgumentScoring.lua",
	EvidenceSystem = "src/ReplicatedStorage/Shared/EvidenceSystem.lua",
	CourtroomEvents = "src/ReplicatedStorage/Shared/CourtroomEvents.lua",
	NPCSystem = "src/ReplicatedStorage/Shared/NPCSystem.lua",
	CosmeticsCatalog = "src/ReplicatedStorage/Shared/CosmeticsCatalog.lua",
	Progression = "src/ReplicatedStorage/Shared/Progression.lua",
	Themes = "src/ReplicatedStorage/Shared/Themes.lua",
	Animations = "src/ReplicatedStorage/Shared/Animations.lua",
	AudioCatalog = "src/ReplicatedStorage/Shared/AudioCatalog.lua",
	PerformanceSettings = "src/ReplicatedStorage/Shared/PerformanceSettings.lua",
	MonetizationConfig = "src/ReplicatedStorage/Shared/MonetizationConfig.lua",
	DataService = "src/ServerScriptService/Services/DataService.lua",
	CosmeticsService = "src/ServerScriptService/Services/CosmeticsService.lua",
	MonetizationService = "src/ServerScriptService/Services/MonetizationService.lua",
	MapBuilder = "src/ServerScriptService/Services/MapBuilder.lua",
	LogicTests = "src/ServerScriptService/Tests/LogicTests.lua",
}

local instancesByName = {
	Shared = sharedFolder,
	Services = servicesFolder,
	ServerScriptService = sss,
	ReplicatedStorage = repStorage,
}

local function loadModule(name, path, scriptInstance)
	if moduleCache[name] then return moduleCache[name] end
	local src = fs.readFile(path)
	local bytecode = luau.compile(src)
	local mEnv = table.clone(env)
	mEnv.script = scriptInstance or instancesByName[name]
	local fn = luau.load(bytecode, {
		environment = mEnv,
	})
	local result = fn()
	moduleCache[name] = result
	return result
end

-- Create ModuleScript instances so WaitForChild and dot access works
for name, path in pairs(modulePaths) do
	if name ~= "Shared" then
		local parent = sharedFolder
		if path:find("Services") then parent = servicesFolder
		elseif path:find("Tests") then parent = testsFolder end

		local ms = createMockInstance("ModuleScript")
		ms.Name = name
		ms.Parent = parent
		instancesByName[name] = ms
	end
end

env.require = function(target)
	if type(target) == "table" and target.Name and modulePaths[target.Name] then
		return loadModule(target.Name, modulePaths[target.Name], target)
	end
	error("Cannot require unknown target: " .. tostring(target and target.Name or target))
end

print("==================================================")
print("EXECUTING LOGICTESTS VIA LUNE")
print("==================================================")

local LogicTests = loadModule("LogicTests", modulePaths.LogicTests, instancesByName.LogicTests)
local success, logs = LogicTests.Run()

if success then
	for _, l in ipairs(logs) do
		print(l)
	end
	print("==================================================")
	print("🏆 ALL LOGICTESTS PASSED SUCCESSFULLY! (100%)")
	print("==================================================")
else
	error("LogicTests failed!")
end
