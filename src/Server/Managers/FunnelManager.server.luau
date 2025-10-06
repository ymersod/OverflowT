local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local enums = require(ReplicatedStorage.Shared.enums)
local funnelEvents = require(ServerScriptService.Server.funnelEvents)

local funnels = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("Funnel")
local shop = funnels:WaitForChild("Shop")
local playTimeRewards = funnels:WaitForChild("PlayTimeRewards")

shop.OnServerEvent:Connect(function(player, mode)
	local sessionName = enums.Analytics.Shop.SessionName
	if mode == enums.Analytics.Shop.Opened.Name then
		funnelEvents.LogStepPlayers({ player }, enums.Analytics.Shop.Opened.Name, sessionName)
	elseif mode == enums.Analytics.Shop.Closed.Name then
		funnelEvents.LogStepPlayers({ player }, enums.Analytics.Shop.Closed.Name, sessionName, true)
	elseif mode == enums.Analytics.Shop.SwitchOverview.Name then
		funnelEvents.LogStepPlayers({ player }, enums.Analytics.Shop.SwitchOverview.Name, sessionName, false, true)
	end
end)

playTimeRewards.OnServerEvent:Connect(function(player, rewardToEnable)
	local sessionName = enums.Analytics.PlaytimeRewards.SessionName
	local mode = rewardToEnable == 1 and enums.Analytics.PlaytimeRewards.Clicked5MinReward.Name
		or rewardToEnable == 2 and enums.Analytics.PlaytimeRewards.Clicked10MinReward.Name
		or rewardToEnable == 3 and enums.Analytics.PlaytimeRewards.Clicked15MinReward.Name

	if mode == enums.Analytics.PlaytimeRewards.Clicked5MinReward.Name then
		funnelEvents.LogStepPlayers({ player }, enums.Analytics.PlaytimeRewards.Clicked5MinReward.Name, sessionName)
	elseif mode == enums.Analytics.PlaytimeRewards.Clicked10MinReward.Name then
		funnelEvents.LogStepPlayers({ player }, enums.Analytics.PlaytimeRewards.Clicked10MinReward.Name, sessionName)
	elseif mode == enums.Analytics.PlaytimeRewards.Clicked15MinReward.Name then
		funnelEvents.LogStepPlayers({ player }, enums.Analytics.PlaytimeRewards.Clicked15MinReward.Name, sessionName)
	end
end)
