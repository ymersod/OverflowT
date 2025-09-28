local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local actions = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("Actions")
local serverUtils = require(script.Parent.serverUtils)
local Stats = require(ServerScriptService.Server.Persistence.Stats)

Players.PlayerAdded:Connect(function(player)
	local localStats = Instance.new("Folder")
	localStats.Name = "localstats"
	localStats.Parent = player

	local localStatsActions = Instance.new("Folder")
	localStatsActions.Name = "localstatsactions"
	localStatsActions.Parent = localStats

	local states = Instance.new("Folder")
	states.Name = "States"
	states.Parent = player

	-- Determines position in line for client to observe
	local LinePosition = Instance.new("IntValue")
	LinePosition.Value = 0
	LinePosition.Name = "LinePosition"
	LinePosition.Parent = states

	local leaderStats = Instance.new("Folder")
	leaderStats.Name = "leaderstats"
	leaderStats.Parent = player

	local Wins = Instance.new("IntValue")
	Wins.Value = 0
	Wins.Name = "Wins"
	Wins.Parent = leaderStats

	local Money = Instance.new("IntValue")
	Money.Value = 0
	Money.Name = "Money"
	Money.Parent = leaderStats

	local EquippedParticles = Instance.new("IntValue")
	EquippedParticles.Value = 1
	EquippedParticles.Name = "EquippedParticles"
	EquippedParticles.Parent = localStats

	local EquippedToilet = Instance.new("IntValue")
	EquippedToilet.Value = 100
	EquippedToilet.Name = "EquippedToilet"
	EquippedToilet.Parent = localStats

	for _, action in ipairs(actions:GetChildren()) do
		local actionId = action:GetAttribute("ActionId")

		if actionId then
			local actionInstance = Instance.new("IntValue")
			actionInstance.Value = 0
			actionInstance.Name = actionId
			actionInstance.Parent = localStatsActions
		end
	end

	local playerStats = Stats.GetPlayerStats(player.UserId)
	serverUtils.updatePlayerLeaderStats(player.UserId, playerStats)
end)
