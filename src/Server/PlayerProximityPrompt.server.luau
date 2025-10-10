local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FlushHandler = require(script.Parent.FlushHandler)
local LineArray = require(script.Parent.LineArray)
local MonetizationHandler = require(script.Parent.MonetizationHandler)
local proximityPrompt: ProximityPrompt = ReplicatedStorage:WaitForChild("TrollProx")
local trollEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("GameEvents")
	:WaitForChild("TrollEvent")

local proxArr: { [string]: { prox: ProximityPrompt } } = {}
Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer.CharacterAdded:Connect(function(char)
		local proximityClone = proximityPrompt:Clone()
		proximityClone.Enabled = false
		proximityClone.ObjectText = newPlayer.Name
		proximityClone.Parent = char
		proxArr[tostring(newPlayer.UserId)] = { prox = proximityClone }

		trollEvent:FireAllClients(newPlayer, proximityClone)
	end)
end)

Players.PlayerRemoving:Connect(function(playerToRemove)
	proxArr[tostring(playerToRemove.UserId)] = nil
end)

trollEvent.OnServerEvent:Connect(function(player, playerToRemove: Player)
	MonetizationHandler.PromptRobuxPurchase(player, "TrollPlayer", "1", nil, playerToRemove)
end)

task.spawn(function()
	RunService.Heartbeat:Connect(function()
		-- print(proxArr)
		local toEnable = true
		if not FlushHandler.gameOnGoing then
			toEnable = false
		end

		for id, item in pairs(proxArr) do
			local lineId = LineArray:GetIndex(tonumber(id))
			if toEnable and lineId then
				item.prox.Enabled = true
			elseif not toEnable then
				item.prox.Enabled = false
			end
		end
	end)
end)
