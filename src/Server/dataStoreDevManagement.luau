local DataStoreService = game:GetService("DataStoreService")

local ShopObjects = DataStoreService:GetDataStore("ShopObjects")
local Stats = DataStoreService:GetDataStore("PlayerStats")

dataStoreManagementFunctions = {}

local statPrefix = "Stats_"
local shopPrefix = "ShopObjects_"

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

function dataStoreManagementFunctions.clearAllKeysInDataStores()
	local clearSuccessObj = dataStoreManagementFunctions.clearStatsStore()
	if not clearSuccessObj.success then
		warn(clearSuccessObj.payload)
	end

	clearSuccessObj = dataStoreManagementFunctions.clearShopObjectStore()
	if not clearSuccessObj.success then
		warn(clearSuccessObj.payload)
	end
end

return dataStoreManagementFunctions
