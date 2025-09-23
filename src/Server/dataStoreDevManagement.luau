local DataStoreService = game:GetService("DataStoreService")

local ShopObjects = DataStoreService:GetDataStore("ShopObjects")
local Stats = DataStoreService:GetDataStore("PlayerStats")
local Actions = DataStoreService:GetDataStore("Actions")
local OrderedStatsStore = DataStoreService:GetOrderedDataStore("PlayerStatsStore")

dataStoreManagementFunctions = {}

local statPrefix = "Stats_"
local shopPrefix = "ShopObjects_"
local actionsPrefix = "Actions_"

function dataStoreManagementFunctions.removePlayerFromStatsStore(playerId)
	local success, err = pcall(function()
		return Stats:RemoveAsync(statPrefix .. playerId)
	end)
	if success then
		return { success = true, payload = "player " .. playerId .. " removed from statsstore" }
	end
	return { success = false, payload = err }
end

function dataStoreManagementFunctions.removePlayerFromShopObjectsStore(playerId)
	local success, err = pcall(function()
		return ShopObjects:RemoveAsync(shopPrefix .. playerId)
	end)
	if success then
		return { success = true, payload = "player " .. playerId .. " removed from shopobjectsstore" }
	end
	return { success = false, payload = err }
end

function dataStoreManagementFunctions.removePlayerFromActionsStore(playerId)
	local success, err = pcall(function()
		return Actions:RemoveAsync(actionsPrefix .. playerId)
	end)
	if success then
		return { success = true, payload = "player " .. playerId .. " removed from actionsstore" }
	end
	return { success = false, payload = err }
end

function dataStoreManagementFunctions.removePlayerFromOrderedStatsStore(playerId)
	local success, err = pcall(function()
		return OrderedStatsStore:RemoveAsync(playerId)
	end)
	if success then
		return { success = true, payload = "player " .. playerId .. " removed from ordered stats store" }
	end
	return { success = false, payload = err }
end

return dataStoreManagementFunctions
