local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local enums = require(ReplicatedStorage.Shared.enums)
local FlushHandler = require(script.Parent.FlushHandler)
local Globals = require(script.Parent.Globals)
local LineArray = require(script.Parent.LineArray)
local ragdollUtils = require(script.Parent.ragdollUtils)
local serverUtils = require(script.Parent.serverUtils)
local proximityPrompt: ProximityPrompt = ReplicatedStorage:WaitForChild("TrollProx")
local trollEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("GameEvents")
	:WaitForChild("TrollEvent")
local EndGameScreenEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("EndGameScreen")

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

trollEvent.OnServerEvent:Connect(function(_, playerToRemove: Player)
	LineArray:Enqueue(LineArray.OperationType.Remove, playerToRemove.UserId)

	local char = playerToRemove.Character
	local root: Part? = char and char:FindFirstChild("HumanoidRootPart")
	serverUtils.playExplosionOnPlayer(playerToRemove, 3)
	if root then
		local _ = -root.CFrame.LookVector
		ragdollUtils.ragdoll(playerToRemove, Globals.BlowBackDir, 3)
	else
		ragdollUtils.ragdoll(playerToRemove, Globals.BlowBackDir, 3)
		warn("No HumanoidRootPart found for " .. playerToRemove.Name)
	end
	EndGameScreenEvent:InvokeClient(playerToRemove, enums.EndGameScreen.Trolled)
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
