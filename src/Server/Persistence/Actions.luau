local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Actions = DataStoreService:GetDataStore("Actions")
local types = require(ReplicatedStorage.Shared.types)

local actionsPrefix = "Actions_"

local actionsHandler = {}
local actionsCache: { [string]: { [string]: types.Action } } = {}

local function DefaultOwned(): { [string]: types.Action }
	return {}
end

function actionsHandler.getPlayerOwnedActions(playerId: string): { [string]: types.Action }
	local key = actionsPrefix .. playerId
	local success, data = pcall(function()
		return Actions:GetAsync(key)
	end)

	if not success then
		warn("Failed to get player owned actions for playerId:", playerId, data)
		return {}
	end

	if not data then
		return DefaultOwned()
	end

	return data
end

function actionsHandler.UpdatePlayerOwnedActions(
	playerId: string,
	updater: () -> { [string]: types.Action }
): { [string]: types.Action }
	local key = actionsPrefix .. playerId

	local success, result = pcall(function()
		return Actions:UpdateAsync(key, function()
			return updater()
		end)
	end)
	if success and result then
		return result
	else
		warn("Failed to update actions for playerId:", playerId, result)
		return {}
	end
end

function actionsHandler.UpdateCache(playerId: string, actionId: string, amount: number)
	local currAction = actionsCache[playerId][actionId]

	if not currAction then
		-- print("el not found in cahce creating new one")
		actionsCache[playerId][actionId] = { ActionId = actionId, OwnedAmount = 0 + amount }
	else
		-- print("el fount updating")
		actionsCache[playerId][actionId].OwnedAmount += amount
	end
	print(actionsCache)
end

function actionsHandler.ResetActions(playerId: string)
	actionsCache[playerId] = {}

	actionsHandler.UpdatePlayerOwnedActions(playerId, function()
		return actionsCache[playerId]
	end)
end

Players.PlayerAdded:Connect(function(player)
	local localStats = player:WaitForChild("localstats")
	local localStatsActions = localStats and localStats:WaitForChild("localstatsactions")

	if not localStatsActions then
		warn("NO LOCALSTATSACTIONSFOUND = BIIIIIG ERROR MONKAW YIKERS")
		return
	end

	local actions: { [string]: types.Action } = actionsHandler.getPlayerOwnedActions(tostring(player.UserId))
	for _, action in pairs(actions) do
		local id = action.ActionId
		local corrLocalStatsAction: IntValue? = localStatsActions:WaitForChild(id)

		if corrLocalStatsAction then
			corrLocalStatsAction.Value = action.OwnedAmount
		else
			print("Couldnt find corresponding localstat smadge")
		end
	end
	actionsCache[tostring(player.UserId)] = actions
end)

Players.PlayerRemoving:Connect(function(player)
	actionsHandler.UpdatePlayerOwnedActions(tostring(player.UserId), function()
		return actionsCache[tostring(player.UserId)]
	end)
	print("players saved!")
end)

return actionsHandler
