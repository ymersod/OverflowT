local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ShopObjects = require(ServerScriptService.Server.Persistence.ShopObjects)
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local EconomyFunnels = require(script.Parent.EconomyFunnels)
local MonetizationHandler = require(script.Parent.MonetizationHandler)
local funnelEvents = require(script.Parent.funnelEvents)
local serverUtils = require(script.Parent.serverUtils)
local enums = require(ReplicatedStorage.Shared.enums)

local shopItems = ServerStorage:WaitForChild("ShopItems"):GetDescendants()

local shopHandler = {}
local itemToBuy

function shopHandler.BuyItem(player: Player, id: number, equipMode: string?)
	for _, shopItem in ipairs(shopItems) do
		local itemId = shopItem:GetAttribute("Id")
		if itemId and itemId == id then
			itemToBuy = shopItem
		end
	end

	local itemPrice = itemToBuy and itemToBuy:GetAttribute("PriceMoney")
	local itemName = itemToBuy and itemToBuy:GetAttribute("Name")

	local localstats = player:FindFirstChild("leaderstats")
	local money: IntValue? = localstats and localstats:FindFirstChild("Money")

	if itemPrice and money and itemName then
		funnelEvents.LogStepPlayers(
			{ player },
			enums.Analytics.Shop.TryBuy.Name,
			enums.Analytics.Shop.SessionName,
			false,
			true
		)
		if money.Value >= itemPrice then
			task.spawn(function()
				local curMoney = serverUtils.GetLeaderStatVal(tostring(player.UserId), "Money")
				if curMoney then
					EconomyFunnels.LogEconomyEventPlayers(
						{ player },
						Enum.AnalyticsEconomyFlowType.Sink,
						"Money",
						itemPrice,
						curMoney - itemPrice,
						Enum.AnalyticsEconomyTransactionType.Shop.Name,
						itemName .. " Money"
					)
				end
			end)

			serverUtils.modifyPlayerLeaderStats(tostring(player.UserId), "Money", -itemPrice)
			task.defer(function()
				funnelEvents.OnboardPlayersPlayer({ player }, enums.Analytics.Onboarding.BoughtFirstItem.Name)
				funnelEvents.LogStepPlayers(
					{ player },
					enums.Analytics.Shop.BuyItem.Name,
					enums.Analytics.Shop.SessionName,
					false,
					true
				)
			end)

			task.spawn(function()
				Stats.UpdatePlayerStats(tostring(player.UserId), function(currentStats)
					currentStats.Coins -= itemPrice
					currentStats.Wins += 0
					currentStats.WinStreak += 0
					return currentStats
				end)
			end)

			return ShopObjects.UpdatePlayerOwnedShopObjects(tostring(player.UserId), function(ownedObjects)
				if not table.find(ownedObjects, id) then
					table.insert(ownedObjects, id)
				end

				return ownedObjects
			end)
		else
			if equipMode then
				MonetizationHandler.PromptRobuxPurchase(player, equipMode, tostring(id))
			end
		end
	end
	return ShopObjects.GetPlayerOwnedShopObjects(tostring(player.UserId))
end

return shopHandler
