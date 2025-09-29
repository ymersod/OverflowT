local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverUtils = require(script.Parent.serverUtils)
local clientEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ClientEvents")
local giveRewardEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("GameEvents")
	:WaitForChild("GiveReward")
local PlayTimeRewardEvent = clientEvents:WaitForChild("PlaytimeReward")
local UpdatePlayTimeRewards = clientEvents:WaitForChild("UpdatePlaytimeRewards")

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

local function giveReward(player, abilityId: string, amount: number?)
	serverUtils.addToAction(tostring(player.UserId), abilityId, amount or 1)
	PlayTimeRewardEvent:FireClient(player, abilityId, amount or 1)
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

local CHECK_POINT1 = 5
local CHECK_POINT2 = 10
local CHECK_POINT3 = 15

local function setupPlayTimeRewardsPlayer(player)
	local cp1Reached, cp2Reached, cp3Reached
	task.spawn(function()
		local totalTime = 0
		local curTime = os.clock()
		while activePlayers[player.UserId] do
			totalTime += os.clock() - curTime
			curTime = os.clock()

			local updateReward = nil
			if totalTime >= CHECK_POINT1 and not cp1Reached then
				updateReward = 1
				cp1Reached = true
			end
			if totalTime >= CHECK_POINT2 and not cp2Reached then
				updateReward = 2
				cp2Reached = true
			end
			if totalTime >= CHECK_POINT3 and not cp3Reached then
				updateReward = 3
				cp3Reached = true
			end

			UpdatePlayTimeRewards:FireClient(player, math.round(totalTime), CHECK_POINT3, updateReward)
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

	setupPlayTimeRewardsPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	activePlayers[player.UserId] = false
end)

giveRewardEvent.OnServerEvent:Connect(function(player, rewardNr)
	if rewardNr == 1 then
		serverUtils.modifyPlayerLeaderStats(tostring(player.UserId), "Money", 100)
	elseif rewardNr == 2 then
		serverUtils.modifyPlayerLeaderStats(tostring(player.UserId), "Money", 300)
	elseif rewardNr == 3 then
		task.spawn(function()
			giveReward(player, "1", 5)
			task.wait(0.4)
			giveReward(player, "2", 2)
			task.wait(0.4)
			giveReward(player, "4", 1)
		end)
	end
end)
