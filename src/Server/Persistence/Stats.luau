local DataStoreService = game:GetService("DataStoreService")
local Stats = DataStoreService:GetDataStore("PlayerStats")
local OrderedStatsStore = DataStoreService:GetOrderedDataStore("PlayerStatsStore")

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

	local success, result = pcall(function()
		return Stats:UpdateAsync(key, function(oldData)
			local currentData: PlayerStats = oldData or DefaultStats()

			return updater(currentData)
		end)
	end)
	statsHandler.UpdateOrderedPlayerStatsStore(playerId, result)
	if success and result then
		return result
	else
		warn("Failed to update stats for playerId:", playerId, result)
		return nil
	end
end

function statsHandler.UpdateOrderedPlayerStatsStore(playerId, currentStats: PlayerStats)
	local success, err = pcall(function()
		return OrderedStatsStore:SetAsync(playerId, currentStats.Wins)
	end)

	if not success then
		warn("Failed to update ordered store for playerId:", playerId, err)
	end
end

function statsHandler.GetTopPlayers(limit: number): { key: string, value: number }?
	limit = limit or 10

	local success, pages = pcall(function()
		-- false = descending order (highest first)
		return OrderedStatsStore:GetSortedAsync(false, limit)
	end)

	if not success then
		warn("Failed to get top players:", pages)
		return nil
	end

	-- GetCurrentPage returns an array of { key = playerId, value = score }
	local topPlayers = pages:GetCurrentPage()
	return topPlayers
end

return statsHandler
