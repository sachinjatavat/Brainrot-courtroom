local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = require(ReplicatedStorage.Shared)
local DataService = require(ServerScriptService.Services.DataService)
local MapBuilder = require(ServerScriptService.Services.MapBuilder)
local RoundService = require(ServerScriptService.Services.RoundService)

local remotes = Instance.new("Folder")
remotes.Name = "CourtroomRemotes"
remotes.Parent = ReplicatedStorage
for _, name in pairs(Shared.Net.Events) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

if not workspace:FindFirstChild("BrainrotCourtroomMap") then MapBuilder.Build() end
DataService.Start()
RoundService.Start(remotes, DataService)
