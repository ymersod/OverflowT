local Players = game:GetService("Players")
local Globals = require(script.Parent.Globals)

local GROUP_ID = 35951660

local rewardsHandler = {}

local itemMults: { [string]: { toiletMult: number, particleMult: number } } = {}

function rewardsHandler.GetRewardMult(playerId): number
	local mult = 1
	if Globals.group[playerId] and Globals.group[playerId].DoubleRewards then
		mult = mult * 2
	end
	if Globals.premium[playerId] and Globals.premium[playerId].DoubleRewards then
		mult = mult * 2
	end
	if itemMults[playerId] then
		mult = mult * itemMults[playerId].toiletMult
		mult = mult * itemMults[playerId].particleMult
	end
	print("Mult for player is: ", mult)
	return mult
end

function rewardsHandler.SetItemMult(playerId: string, multOfItem: number, mode: "Model" | "Particle")
	if mode == "Model" then
		if itemMults[playerId] then
			itemMults[playerId].toiletMult = multOfItem
		else
			itemMults[playerId] = { toiletMult = 1, particleMult = 1 }
		end
	end
	if mode == "Particle" then
		if itemMults[playerId] then
			itemMults[playerId].particleMult = multOfItem
		else
			itemMults[playerId] = { toiletMult = 1, particleMult = 1 }
		end
	end
end

local function ObservePlayers()
	while true do
		for id, vals in pairs(Globals.group) do
			local Player = Players:GetPlayerByUserId(tonumber(id))
			if Player and Player:IsInGroup(GROUP_ID) and not vals.DoubleRewards then
				Globals.group[id] = { DoubleRewards = true }
			end
		end
		for id, vals in pairs(Globals.premium) do
			local Player = Players:GetPlayerByUserId(tonumber(id))
			if Player and Player.MembershipType == Enum.MembershipType.Premium and not vals.DoubleRewards then
				Globals.premium[id] = { DoubleRewards = true }
			end
		end
		task.wait(10)
	end
end
task.spawn(ObservePlayers)

Players.PlayerAdded:Connect(function(Player)
	local userId = tostring(Player.UserId)
	if Player:IsInGroup(GROUP_ID) then
		Globals.group[userId] = { DoubleRewards = true }
	else
		Globals.group[userId] = { DoubleRewards = false }
	end
	if Player.MembershipType == Enum.MembershipType.Premium then
		Globals.premium[userId] = { DoubleRewards = true }
	else
		Globals.premium[userId] = { DoubleRewards = false }
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	local userId = tostring(Player.UserId)
	Globals.group[userId] = nil
	itemMults[userId] = nil
end)

return rewardsHandler
