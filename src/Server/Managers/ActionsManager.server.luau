local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local enums = require(ReplicatedStorage.Shared.enums)
local funnelEvents = require(ServerScriptService.Server.funnelEvents)
local serverUtils = require(ServerScriptService.Server.serverUtils)

local ActionEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ActionsEvents")
local TryUseAction = ActionEvents:WaitForChild("TryUseAction")
local AddChargeToAction = ActionEvents:WaitForChild("AddChargeToAction")

TryUseAction.OnServerInvoke = function(player, id: string)
	local canUse = serverUtils.useAction(tostring(player.UserId), id)

	task.defer(function()
		funnelEvents.LogStepPlayers(
			{ player },
			enums.Analytics.Game.TryUseAction.Name,
			enums.Analytics.Game.SessionName,
			false,
			true
		)
		if canUse then
			funnelEvents.LogStepPlayers(
				{ player },
				enums.Analytics.Game.UsedActon.Name,
				enums.Analytics.Game.SessionName,
				false,
				true
			)
		end
	end)

	return canUse
end

AddChargeToAction.OnServerInvoke = function(player, id: string)
	serverUtils.addToAction(tostring(player.UserId), id)
end
