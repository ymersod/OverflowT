local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local serverUtils = require(ServerScriptService.Server.serverUtils)

local ActionEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ActionsEvents")
local TryUseAction = ActionEvents:WaitForChild("TryUseAction")
local AddChargeToAction = ActionEvents:WaitForChild("AddChargeToAction")

TryUseAction.OnServerInvoke = function(player, id: string)
	local canUse = serverUtils.useAction(tostring(player.UserId), id)

	return canUse
end

AddChargeToAction.OnServerInvoke = function(player, id: string)
	serverUtils.addToAction(tostring(player.UserId), id)
end
