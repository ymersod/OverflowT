local DataStoreService = game:GetService("DataStoreService")
local ShopObjects = DataStoreService:GetDataStore("ShopObjects")

local shopPrefix = "ShopObjects_"

local shopObjectsHandler = {}

local function DefaultOwned(): { number }
	return {}
end

function shopObjectsHandler.GetPlayerOwnedShopObjects(playerId: string): { number }
	local key = shopPrefix .. playerId
	local success, data = pcall(function()
		return ShopObjects:GetAsync(key)
	end)

	if not success then
		warn("Failed to get player owned objects for playerId:", playerId, data)
		return {}
	end

	if not data then
		return DefaultOwned()
	end

	return data
end

function shopObjectsHandler.UpdatePlayerOwnedShopObjects(
	playerId: string,
	updater: ({ number }) -> { number }
): { number }
	local key = shopPrefix .. playerId

	local success, result = pcall(function()
		return ShopObjects:UpdateAsync(key, function(oldData)
			local currentData: { number } = oldData or DefaultOwned()

			return updater(currentData)
		end)
	end)
	print(success)
	if success and result then
		return result
	else
		warn("Failed to update stats for playerId:", playerId, result)
		return {}
	end
end

return shopObjectsHandler
