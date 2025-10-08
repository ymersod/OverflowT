local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ShopObjects = require(ServerScriptService.Server.Persistence.ShopObjects)
local serverUtils = require(script.Parent.serverUtils)

local processPurchaseEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("MonetizationEvents")
	:WaitForChild("ProcessPurchase")

local monetizationHandler = {}

local devProductList: { [string]: { [string]: { devProductId: number, name: string } } } = {
	Action = {
		["1"] = { devProductId = 3425190700, name = "Cut" },
		["2"] = { devProductId = 3425190785, name = "CutAll" },
		["3"] = { devProductId = 3425180213, name = "ResetToilet" },
		["4"] = { devProductId = 3425190851, name = "SkipFlush" },
		["5"] = { devProductId = 3425191290, name = "JamToilet" },
		["6"] = { devProductId = 3425191185, name = "Overflow" },
		["7"] = { devProductId = 3425190938, name = "FreezeToilet" },
	},
	Particle = {
		["2"] = { devProductId = 3425194427, name = "BobaTea" },
		["3"] = { devProductId = 3425194557, name = "CottonCandy" },
		["4"] = { devProductId = 3425194706, name = "Farts" },
		["5"] = { devProductId = 3425194775, name = "Void" },
		["6"] = { devProductId = 3425194886, name = "Rainbow" },
		["7"] = { devProductId = 3425195517, name = "AutummClover" },
		["8"] = { devProductId = 3425195875, name = "SpringClover" },
		["9"] = { devProductId = 3425196124, name = "Money" },
		["10"] = { devProductId = 3425196259, name = "Starry" },
		["11"] = { devProductId = 3425196451, name = "Robux" },
	},
	Model = {
		["101"] = { devProductId = 3425219288, name = "Plastic brown" },
		["102"] = { devProductId = 3425219509, name = "Plastic purple" },
		["103"] = { devProductId = 3425219719, name = "Plastic yellow" },
		["104"] = { devProductId = 3425219871, name = "Plastic orange" },
		["105"] = { devProductId = 3425219976, name = "Plastic blue" },
		["106"] = { devProductId = 3425220095, name = "Plastic green" },
		["107"] = { devProductId = 3425220397, name = "Plastic pink" },
		["108"] = { devProductId = 3425220695, name = "Coal" },
		["109"] = { devProductId = 3425220803, name = "Wood" },
		["110"] = { devProductId = 3425220952, name = "Bronze" },
		["111"] = { devProductId = 3425221035, name = "Silver" },
		["112"] = { devProductId = 3425221147, name = "Redstone" },
		["113"] = { devProductId = 3425221288, name = "Diamond" },
		["114"] = { devProductId = 3425221367, name = "Emerald" },
		["200"] = { devProductId = 3425221462, name = "Shiny" },
		["201"] = { devProductId = 3425221547, name = "Rainbow" },
		["202"] = { devProductId = 3425221629, name = "Thunder" },
		["203"] = { devProductId = 3425221723, name = "Skibidi" },
	},
}

function monetizationHandler.PromptRobuxPurchase(player, type: string, localId: string)
	local devProduct = devProductList[type][localId]

	if devProduct then
		MarketplaceService:PromptProductPurchase(player, devProduct.devProductId)
	else
		warn("Devproduct not found")
	end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted
	for typeName, typeTable in pairs(devProductList) do
		for localId, data in pairs(typeTable) do
			if data.devProductId == receiptInfo.ProductId then
				if typeName == "Action" then
					serverUtils.addToAction(player.UserId, localId, 1)
					granted = true
				elseif typeName == "Model" or typeName == "Particle" then
					ShopObjects.UpdatePlayerOwnedShopObjects(tostring(player.UserId), function(ownedObjects)
						if not table.find(ownedObjects, tonumber(localId)) then
							granted = true
							table.insert(ownedObjects, tonumber(localId))
						end

						return ownedObjects
					end)
					processPurchaseEvent:FireClient(player, tonumber(localId), typeName)
				end
			end
		end
	end

	if granted then
		print("processing shopitem purchase..")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

return monetizationHandler
