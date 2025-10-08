local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MonetizationHandler = require(ServerScriptService.Server.MonetizationHandler)
local monetizationEvents =
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("MonetizationEvents")
local promptBuyEvent = monetizationEvents:WaitForChild("PromptBuy")

promptBuyEvent.OnServerEvent:Connect(function(player, type: string, localId: string)
	MonetizationHandler.PromptRobuxPurchase(player, type, localId)
end)
