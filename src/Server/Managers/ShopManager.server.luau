local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local enums = require(ReplicatedStorage.Shared.enums)
local ShopObjects = require(ServerScriptService.Server.Persistence.ShopObjects)
local funnelEvents = require(ServerScriptService.Server.funnelEvents)
local shopHandler = require(ServerScriptService.Server.shopHandler)
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

local shopItems = ServerStorage:WaitForChild("ShopItems"):GetDescendants()

getShopItemsEvent.OnServerInvoke = function(_: Player)
	local filteredShopItems = {}

	for _, item in ipairs(shopItems) do
		local id = item:GetAttribute("Id")
		local name = item:GetAttribute("Name")
		local shopFunction = item:GetAttribute("ShopItemType")
		local priceMoney = item:GetAttribute("PriceMoney")
		local priceRobux = item:GetAttribute("PriceRobux")
		local imageId = item:GetAttribute("ImageId")
		local itemPlacement = item:GetAttribute("ItemPlacement")

		if id and name and shopFunction and priceMoney and priceRobux and imageId and itemPlacement then
			local shopItem: types.ShopItem = {
				Id = id,
				Name = name,
				ShopFunction = shopFunction,
				PriceMoney = priceMoney,
				PriceRobux = priceRobux,
				ImageId = imageId,
				ItemPlacement = itemPlacement,
			}
			table.insert(filteredShopItems, shopItem)
		end
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

buyShopItemEvent.OnServerInvoke = function(player: Player, id: number, equipMode: string?)
	return shopHandler.BuyItem(player, id, equipMode)
end

equipShopItemEvent.OnServerInvoke = function(player: Player, id: number, mode: "Model" | "Particle")
	funnelEvents.LogStepPlayers(
		{ player },
		enums.Analytics.Shop.EquipItem.Name,
		enums.Analytics.Shop.SessionName,
		false,
		true
	)

	local localstats = player:FindFirstChild("localstats")
	local equippedItem: IntValue?
	if mode == "Particle" then
		equippedItem = localstats and localstats:FindFirstChild("EquippedParticles")
	end
	if mode == "Model" then
		equippedItem = localstats and localstats:FindFirstChild("EquippedToilet")
	end

	if equippedItem and equippedItem:IsA("IntValue") then
		equippedItem.Value = id --TODO: Should prob do a server check to make sure player owns the thing
	else
		warn("Could not find the intvalue corresponding to the equipped item")
	end
end
