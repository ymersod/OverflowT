local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Actions = require(ServerScriptService.Server.Persistence.Actions)
local UpdateActionsFromServer = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ActionsEvents")
	:WaitForChild("UpdateActionsFromServer")
local clientEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ClientEvents")
local PlayTimeRewardEvent = clientEvents:WaitForChild("PlaytimeReward")

-- SETTINGS
local CUT_CD = 60 -- 60
local CUT_ALL_CD = 120 -- 120
local SKIP_CD = 300 -- 300
local RESET_TOILET = 600 -- 600

local activePlayers = {}

local function randomiseCd(cd: number)
	local newCd = math.random(cd - cd / 10, cd + cd / 10)
	return newCd
end

local function giveReward(player, abilityId: string)
	local newActions = Actions.UpdatePlayerOwnedActions(tostring(player.UserId), function(currentActions)
		local action = currentActions[abilityId]
		if action then
			action.OwnedAmount += 1
		else
			currentActions[abilityId] = {
				ActionId = abilityId,
				OwnedAmount = 1,
			}
			action = currentActions[abilityId]
		end
		return currentActions
	end)
	UpdateActionsFromServer:InvokeClient(player, newActions)
	PlayTimeRewardEvent:FireClient(player, abilityId)
end

local function setupRewardSystem(cd: number, player, abilityId: number)
	local newCd = randomiseCd(cd)
	local curCd = os.clock()
	task.spawn(function()
		while activePlayers[player.UserId] do
			local diff = os.clock() - curCd
			if diff >= newCd then
				giveReward(player, tostring(abilityId))
				newCd = randomiseCd(cd)
				curCd = os.clock()
			end

			task.wait(1)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	activePlayers[player.UserId] = true
	setupRewardSystem(CUT_CD, player, 1)
	setupRewardSystem(CUT_ALL_CD, player, 2)
	setupRewardSystem(SKIP_CD, player, 4)
	setupRewardSystem(RESET_TOILET, player, 3)
end)

Players.PlayerRemoving:Connect(function(player)
	activePlayers[player.UserId] = false
end)
