local Players = game:GetService("Players")
local Globals = require(script.Parent.Globals)

local GROUP_ID = 35951660

local function ObservePlayers()
	while true do
		for id, vals in pairs(Globals.group) do
			local Player = Players:GetPlayerByUserId(tonumber(id))
			if Player and Player:IsInGroup(GROUP_ID) and not vals.DoubleRewards then
				Globals.group[id] = { DoubleRewards = true }
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
end)

Players.PlayerRemoving:Connect(function(Player)
	local userId = tostring(Player.UserId)
	Globals.group[userId] = nil
end)
