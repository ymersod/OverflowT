local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)
local ShopObjects = require(ServerScriptService.Server.Persistence.ShopObjects)
local types = require(ReplicatedStorage.Shared.types)

local getShopItemsEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("GetShopItems")
local getOwnedShopItemsEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("GetOwnedShopItems")
local buyShopItemEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("BuyShopItem")
local equipShopItemEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("EquipShopItem")

local shopItems = ServerStorage:WaitForChild("BubbleTypes"):GetChildren()

getShopItemsEvent.OnServerInvoke = function(_: Player)
	local filteredShopItems = {}

	for _, item in ipairs(shopItems) do
		local shopItem: types.ShopItem = {
			Id = item:GetAttribute("Id"),
			Name = item:GetAttribute("Name"),
			ShopFunction = item:GetAttribute("ShopItemType"),
			PriceMoney = item:GetAttribute("PriceMoney"),
			PriceRobux = item:GetAttribute("PriceRobux"),
		}
		table.insert(filteredShopItems, shopItem)
	end
	table.sort(filteredShopItems, function(a, b)
		local aId = a.Id or 0
		local bId = b.Id or 0
		return aId < bId
	end)

	return filteredShopItems
end

getOwnedShopItemsEvent.OnServerInvoke = function(player: Player)
	local ownedItems = ShopObjects.GetPlayerOwnedShopObjects(tostring(player.UserId))
	return ownedItems
end

buyShopItemEvent.OnServerInvoke = function(player: Player, id: number)
	return ShopObjects.UpdatePlayerOwnedShopObjects(tostring(player.UserId), function(ownedObjects)
		if not table.find(ownedObjects, id) then
			table.insert(ownedObjects, id)
		end

		return ownedObjects
	end)
end

equipShopItemEvent.OnServerInvoke = function(player: Player, id: number)
	local localstats = player:FindFirstChild("localstats")
	local equippedItem: IntValue? = localstats and localstats:FindFirstChild("EquippedShopItem")

	if equippedItem and equippedItem:IsA("IntValue") then
		equippedItem.Value = id --TODO: Should prob do a server check to make sure player owns the thing
	else
		warn("Could not find the intvalue corresponding to the equipped item")
	end
end
