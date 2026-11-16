local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Net = require(SharedFolder:WaitForChild("Net"))
local DataService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("DataService"))
local MapBuilder = require(ServerScriptService:WaitForChild("Services"):WaitForChild("MapBuilder"))
local RoundService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("RoundService"))

local remotes = ReplicatedStorage:FindFirstChild("CourtroomRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "CourtroomRemotes"
	remotes.Parent = ReplicatedStorage
end

for _, name in pairs(Net.Events) do
	if not remotes:FindFirstChild(name) then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
end

if not workspace:FindFirstChild("BrainrotCourtroomMap") then
	MapBuilder.Build()
end
DataService.Start()
RoundService.Start(remotes, DataService)
