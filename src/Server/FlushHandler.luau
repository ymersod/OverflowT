local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local EndGameScreenEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("EndGameScreen")

local EconomyFunnels = require(script.Parent.EconomyFunnels)
local enums = require(ReplicatedStorage.Shared.enums)
local Globals = require(script.Parent.Globals)
local MonetizationHandler = require(script.Parent.MonetizationHandler)
local RewardsHandler = require(script.Parent.RewardsHandler)
local flushUtils = require(script.Parent.flushUtils)
local funnelEvents = require(script.Parent.funnelEvents)
local ragdollUtils = require(script.Parent.ragdollUtils)
local serverUtils = require(script.Parent.serverUtils)
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local LineArray = require(ServerScriptService.Server.LineArray)
local ToiletSwitcher = require(ServerScriptService.Server.Toilet.ToiletSwitcher)

local flushHandler = {
	curCap = 0,
	totalTimeHeld = 0,
	gameOnGoing = false,
}

type PlayerHeld = {
	player: Player,
	timeHeld: number,
}

local hardCap = 15 -- Seconds
local playerHeldTime = {}

local function calcCoins(playerId: number)
	local timeHeld = playerHeldTime[playerId]
	if not timeHeld or timeHeld < 1 then
		timeHeld = 1
	end
	return math.ceil(timeHeld * 10)
end

local function RewardWinners()
	local playerIds = LineArray:GetLine()
	task.defer(function()
		funnelEvents.OnboardPlayersUserId(playerIds, enums.Analytics.Onboarding.CompletedFirstGame.Name)
		funnelEvents.LogStepPlayerIds(
			playerIds,
			enums.Analytics.Game.FinishedGame.Name,
			enums.Analytics.Game.SessionName,
			true
		)
	end)

	local startRewardIndex
	if playerIds and #playerIds == 1 then
		startRewardIndex = 1
	else
		startRewardIndex = 2
		local losingPlayerId = playerIds[1]
		local losingPlayer = losingPlayerId and Players:GetPlayerByUserId(losingPlayerId)
		if losingPlayer then
			ragdollUtils.ragdoll(losingPlayer, Globals.BlowBackDir, 3)
			EndGameScreenEvent:InvokeClient(losingPlayer, enums.EndGameScreen.Lose)

			local curWinStreak = serverUtils.GetLeaderStatVal(losingPlayerId, "WinStreak")

			MonetizationHandler.PromptRobuxPurchase(losingPlayer, "RecoverWinstreak", "1", curWinStreak)

			serverUtils.modifyPlayerLeaderStats(losingPlayerId, "WinStreak", -1)
			task.spawn(function()
				if curWinStreak then
					EconomyFunnels.LogEconomyEventPlayers(
						{ losingPlayer },
						Enum.AnalyticsEconomyFlowType.Sink,
						"WinStreak",
						curWinStreak,
						0,
						Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
						"Lose match (WINSTREAK)"
					)
				end

				Stats.UpdatePlayerStats(losingPlayerId, function(currentStats)
					currentStats.Coins += 0
					currentStats.Wins += 0
					currentStats.WinStreak = 0
					return currentStats
				end)
			end)
		end
	end

	--Skipping first since he was the one who made it Overflow
	for i = startRewardIndex, #playerIds do
		local playerId = playerIds[i]
		local coinsEarned = calcCoins(playerId)
		local winsEarned = 1
		local mult = RewardsHandler.GetRewardMult(playerId)
		coinsEarned = coinsEarned * mult
		winsEarned = winsEarned * mult

		local soundLength = EndGameScreenEvent:InvokeClient(
			Players:GetPlayerByUserId(playerId),
			enums.EndGameScreen.Win,
			coinsEarned,
			winsEarned
		)

		task.defer(function()
			local curWinStreaks = serverUtils.GetLeaderStatVal(playerId, "WinStreak")
			local curWins = serverUtils.GetLeaderStatVal(playerId, "Wins")
			local curMoney = serverUtils.GetLeaderStatVal(playerId, "Money")

			if curWinStreaks and curWins and curMoney then
				EconomyFunnels.LogEconomyEventPlayerIds(
					{ playerId },
					Enum.AnalyticsEconomyFlowType.Source,
					"WinStreak",
					1,
					curWinStreaks + 1,
					Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
					"Win match (WINSTREAK)"
				)
				EconomyFunnels.LogEconomyEventPlayerIds(
					{ playerId },
					Enum.AnalyticsEconomyFlowType.Source,
					"Wins",
					winsEarned,
					curWins + winsEarned,
					Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
					"Win match (WINS)"
				)
				EconomyFunnels.LogEconomyEventPlayerIds(
					{ playerId },
					Enum.AnalyticsEconomyFlowType.Source,
					"Money",
					coinsEarned,
					curMoney + coinsEarned,
					Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
					"Win match (MONEY)"
				)
			end
		end)

		task.delay(soundLength, function()
			serverUtils.modifyPlayerLeaderStats(playerId, "Money", coinsEarned)
			serverUtils.modifyPlayerLeaderStats(playerId, "Wins", winsEarned)
			serverUtils.modifyPlayerLeaderStats(playerId, "WinStreak", 1)
			task.spawn(function()
				Stats.UpdatePlayerStats(playerId, function(currentStats)
					currentStats.Coins += coinsEarned
					currentStats.Wins += winsEarned
					currentStats.WinStreak += 1
					return currentStats
				end)
			end)
		end)
	end
	serverUtils.handlePlayerSpots(false)
end

function flushHandler.Overflow()
	print("OVERFLOW!!!!!")
	flushHandler.gameOnGoing = false
	RewardWinners()
	LineArray:ResetLine()
	ToiletSwitcher.SwitchToilet(flushHandler.gameOnGoing)
end

function flushHandler.AddFlushedTime(flushedTime: number, curPlayer: Player)
	if not flushHandler.gameOnGoing then
		return
	end

	flushHandler.totalTimeHeld += flushedTime
	-- print("TotalTimeHeld: " .. flushHandler.totalTimeHeld)

	if flushHandler.totalTimeHeld >= flushHandler.curCap then
		flushHandler.Overflow()
	else
		local timeHeld = playerHeldTime[curPlayer.UserId]
		if timeHeld then
			playerHeldTime[curPlayer.UserId] = timeHeld + flushedTime
		else
			playerHeldTime[curPlayer.UserId] = flushedTime
		end
	end
end

function flushHandler.ResetTimeHeld()
	flushHandler.totalTimeHeld = 0
end

function flushHandler.StartToilet()
	flushHandler.gameOnGoing = true
	flushHandler.curCap = math.random(hardCap - 2, hardCap + 2)
	flushHandler.totalTimeHeld = 0
	playerHeldTime = {}
	ToiletSwitcher.SwitchToilet(flushHandler.gameOnGoing)
end

function flushHandler.SetToFrozen(isFreezed)
	ToiletSwitcher.SwitchToFrozen(isFreezed)
end

local curPlayer
local function ObserveLine()
	task.spawn(function()
		RunService.Heartbeat:Connect(function()
			if not flushHandler.gameOnGoing then
				curPlayer = nil
				return
			end

			local line = LineArray:GetLine()
			if not line or #line <= 1 then
				return
			end

			local firstPlayer = line[1]
			-- print("First: ", firstPlayer)
			if curPlayer ~= firstPlayer then
				local player = Players:GetPlayerByUserId(firstPlayer)

				if player then
					task.spawn(function()
						-- print("Spawning!")
						flushUtils.SetupPlayerBubbleType(player)
						flushUtils.SetPlayerToilet(player)
					end)
				end
			end

			curPlayer = firstPlayer
		end)
	end)
end
ObserveLine()

return flushHandler
