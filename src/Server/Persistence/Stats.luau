local DataStoreService = game:GetService("DataStoreService")
local Stats = DataStoreService:GetDataStore("PlayerStats")

local statPrefix = "Stats_"

export type PlayerStats = {
	Coins: number,
	Wins: number,
}

local statsHandler = {}

local function DefaultStats(): PlayerStats
	return {
		Coins = 0,
		Wins = 0,
	}
end

function statsHandler.GetPlayerStats(playerId: string): PlayerStats?
	local key = statPrefix .. playerId
	local success, data = pcall(function()
		return Stats:GetAsync(key)
	end)

	if not success then
		warn("Failed to get stats for playerId:", playerId, data)
		return nil
	end

	if not data then
		return DefaultStats()
	end

	return data
end

function statsHandler.UpdatePlayerStats(playerId: string, updater: (PlayerStats) -> PlayerStats): PlayerStats?
	local key = statPrefix .. playerId

	local success, data = pcall(function()
		return Stats:UpdateAsync(key, function(oldData)
			local currentData: PlayerStats = oldData or DefaultStats()
			return updater(currentData)
		end)
	end)

	if success and data then
		return data
	else
		warn("Failed to update stats for playerId:", playerId, data)
		return nil
	end
end

return statsHandler
