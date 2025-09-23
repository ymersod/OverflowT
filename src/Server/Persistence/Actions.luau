local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Actions = DataStoreService:GetDataStore("Actions")
local types = require(ReplicatedStorage.Shared.types)

local actionsPrefix = "Actions_"

local actionsHandler = {}

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
	updater: (
		{ [string]: types.Action }
	) -> ({ [string]: types.Action }, boolean?)
): ({ [string]: types.Action }, boolean?)
	local key = actionsPrefix .. playerId

	local outActions, outFlag
	local success, err = pcall(function()
		return Actions:UpdateAsync(key, function(oldData)
			local currentData: { [string]: types.Action } = oldData or DefaultOwned()

			local newData, flag = updater(currentData)

			outActions, outFlag = newData, flag

			return newData
		end)
	end)

	if success and outActions then
		return outActions, outFlag
	else
		warn("Failed to update stats for playerId:", playerId, err)
		return {}, false
	end
end

return actionsHandler
