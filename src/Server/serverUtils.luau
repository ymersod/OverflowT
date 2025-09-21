local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local serverUtils = {}

function serverUtils.updatePlayerLeaderStats(playerId: string, playerStats: Stats.PlayerStats)
	-- print("do it")
	local player = Players:GetPlayerByUserId(playerId)
	local leaderStats = player:FindFirstChild("leaderstats")

	local money: IntValue? = leaderStats:FindFirstChild("Money")
	local wins: IntValue? = leaderStats:FindFirstChild("wins")

	if money and money:IsA("IntValue") then
		money.Value = playerStats.Coins
	end
	if wins and wins:IsA("IntValue") then
		wins.Value = playerStats.Wins
	end
end

return serverUtils
