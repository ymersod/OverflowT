local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local enums = require(ReplicatedStorage.Shared.enums)
local RewardsHandler = require(script.Parent.RewardsHandler)
local funnelEvents = require(script.Parent.funnelEvents)
local serverUtils = require(script.Parent.serverUtils)
local clientEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ClientEvents")
local giveRewardEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("GameEvents")
	:WaitForChild("GiveReward")
local PlayTimeRewardEvent = clientEvents:WaitForChild("PlaytimeReward")
local UpdatePlayTimeRewards = clientEvents:WaitForChild("UpdatePlaytimeRewards")

-- SETTINGS
local TASK_WAIT = 10 -- how often we check

local CUT_TARGET_AVG = 120 -- 60
local CUT_CHANCE = TASK_WAIT / CUT_TARGET_AVG

local CUT_ALL_TAGET_AVG = 300 -- 300
local CUT_ALL_CHANCE = TASK_WAIT / CUT_ALL_TAGET_AVG

local SKIP_TARGET_AVG = 600
local SKIP_CD_CHANCE = TASK_WAIT / SKIP_TARGET_AVG

local RESET_TOILET_TARGET_AVG = 3600
local RESET_TOILET_CHANCE = TASK_WAIT / RESET_TOILET_TARGET_AVG

local FREEZE_TOILET_TARGET_AVG = 7200
local FREEZE_TOILET_CHANCE = TASK_WAIT / FREEZE_TOILET_TARGET_AVG

local JAM_FLUSH_TARGET_AVG = 21600
local JAM_FLUSH_CHANCE = TASK_WAIT / JAM_FLUSH_TARGET_AVG

local OVERFLOW_TARGET_AVG = 43200
local OVERFLOW_CHANCE = TASK_WAIT / OVERFLOW_TARGET_AVG

local settingsOdds = {
	{ CUT_CHANCE, 1 },
	{ CUT_ALL_CHANCE, 2 },
	{ SKIP_CD_CHANCE, 4 },
	{ RESET_TOILET_CHANCE, 3 },
	{ FREEZE_TOILET_CHANCE, 7 },
	{ JAM_FLUSH_CHANCE, 5 },
	{ OVERFLOW_CHANCE, 6 },
}

local activePlayers = {}

local function randomiseChance(chance: number)
	return math.random() < chance -- returns true if "won"
end

local function giveReward(player, abilityId: string, type: "Random" | "Playtime", amount: number?)
	serverUtils.addToAction(tostring(player.UserId), abilityId, amount or 1)
	PlayTimeRewardEvent:FireClient(player, abilityId, amount or 1, type)
end

local function setupRewardSystem(chance: number, player, abilityId: number)
	task.spawn(function()
		while activePlayers[player.UserId] do
			task.wait(math.random(TASK_WAIT - 2, TASK_WAIT + 2))
			if randomiseChance(chance) then
				giveReward(player, tostring(abilityId), "Random")
			end
		end
	end)
end

local CHECK_POINT1 = 300
local CHECK_POINT2 = 600
local CHECK_POINT3 = 900

local function setupPlayTimeRewardsPlayer(player)
	local cp1Reached, cp2Reached, cp3Reached
	task.spawn(function()
		local totalTime = 0
		local curTime = os.clock()
		while activePlayers[player.UserId] do
			totalTime += os.clock() - curTime
			curTime = os.clock()

			local updateReward = nil
			local sessionName = enums.Analytics.PlaytimeRewards.SessionName
			if totalTime >= CHECK_POINT1 and not cp1Reached then
				updateReward = 1
				funnelEvents.LogStepPlayers({ player }, enums.Analytics.PlaytimeRewards.Reached5Min.Name, sessionName)
				cp1Reached = true
			end
			if totalTime >= CHECK_POINT2 and not cp2Reached then
				updateReward = 2
				funnelEvents.LogStepPlayers({ player }, enums.Analytics.PlaytimeRewards.Reached10Min.Name, sessionName)
				cp2Reached = true
			end
			if totalTime >= CHECK_POINT3 and not cp3Reached then
				updateReward = 3
				funnelEvents.LogStepPlayers({ player }, enums.Analytics.PlaytimeRewards.Reached15Min.Name, sessionName)
				cp3Reached = true
			end

			UpdatePlayTimeRewards:FireClient(player, math.round(totalTime), CHECK_POINT3, updateReward)
			task.wait(1)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	activePlayers[player.UserId] = true

	for _, n in ipairs(settingsOdds) do
		setupRewardSystem(n[1], player, n[2])
	end

	setupPlayTimeRewardsPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	activePlayers[player.UserId] = false
end)

giveRewardEvent.OnServerEvent:Connect(function(player, rewardNr)
	local cp1 = 100
	local cp2 = 300

	local mult = RewardsHandler.GetRewardMult(tostring(player.UserId))
	cp1 = cp1 * mult
	cp2 = cp2 * mult

	if rewardNr == 1 then
		serverUtils.modifyPlayerLeaderStats(tostring(player.UserId), "Money", cp1)
		task.spawn(function()
			Stats.UpdatePlayerStats(tostring(player.UserId), function(currentStats)
				currentStats.Coins += cp1
				currentStats.Wins += 0
				currentStats.WinStreak += 0
				return currentStats
			end)
		end)
	elseif rewardNr == 2 then
		serverUtils.modifyPlayerLeaderStats(tostring(player.UserId), "Money", cp2)
		task.spawn(function()
			Stats.UpdatePlayerStats(tostring(player.UserId), function(currentStats)
				currentStats.Coins += cp2
				currentStats.Wins += 0
				currentStats.WinStreak += 0
				return currentStats
			end)
		end)
	elseif rewardNr == 3 then
		task.spawn(function()
			giveReward(player, "1", "Playtime", 3)
			task.wait(0.4)
			giveReward(player, "2", "Playtime", 2)
			task.wait(0.4)
			giveReward(player, "4", "Playtime", 1)
			task.wait(0.4)
			giveReward(player, "7", "Playtime", 1)
		end)
	end
end)
