local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Actions = require(ServerScriptService.Server.Persistence.Actions)
local types = require(ReplicatedStorage.Shared.types)
local ActionEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ActionsEvents")

local GetOwnedActions = ActionEvents:WaitForChild("GetOwnedActions")
local TryUseAction = ActionEvents:WaitForChild("TryUseAction")
local AddChargeToAction = ActionEvents:WaitForChild("AddChargeToAction")

GetOwnedActions.OnServerInvoke = function(player): { [string]: types.Action }
	return Actions.getPlayerOwnedActions(tostring(player.UserId))
end

TryUseAction.OnServerInvoke = function(player, id: string)
	local result, canUse = Actions.UpdatePlayerOwnedActions(tostring(player.UserId), function(currentActions)
		local action = currentActions[tostring(id)]
		if action then
			if action.OwnedAmount > 0 then
				action.OwnedAmount -= 1
				return currentActions, true
			else
				return currentActions, false
			end
		else
			currentActions[id] = {
				ActionId = id,
				OwnedAmount = 0,
			}
			action = currentActions[id]
			return currentActions, false
		end
	end)

	return result, canUse
end

AddChargeToAction.OnServerInvoke = function(player, id: string): { [string]: types.Action }
	return Actions.UpdatePlayerOwnedActions(tostring(player.UserId), function(currentActions)
		local action = currentActions[id]
		if action then
			action.OwnedAmount += 1
		else
			currentActions[id] = {
				ActionId = id,
				OwnedAmount = 1,
			}
			action = currentActions[id]
		end
		return currentActions
	end)
end
