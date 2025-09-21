local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EndGameScreenEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("EndGameScreen")

local serverUtils = require(script.Parent.serverUtils)
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local LineArray = require(ServerScriptService.Server.LineArray)
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
local playerHeldTime: { PlayerHeld } = {}

local function calcCoins(playerId: number)
	local timeHeld = 1
	for _, entry in ipairs(playerHeldTime) do
		if entry.player.UserId == playerId then
			if entry.timeHeld > timeHeld then
				timeHeld = entry.timeHeld
			end
			break
		end
	end
	return math.ceil(timeHeld * 10)
end

local function RewardWinners()
	local playerIds = LineArray:GetLine()

	local losingPlayer = playerIds[1]
	EndGameScreenEvent:FireClient(Players:GetPlayerByUserId(losingPlayer), false)

	--Skipping first since he was the one who made it Overflow
	for i = 2, #playerIds do
		local playerId = playerIds[i]
		local coinsEarned = calcCoins(playerId)
		local newStats = Stats.UpdatePlayerStats(playerId, function(currentStats)
			currentStats.Coins += coinsEarned
			currentStats.Wins += 1
			return currentStats
		end)
		serverUtils.updatePlayerLeaderStats(playerId, newStats)

		EndGameScreenEvent:FireClient(Players:GetPlayerByUserId(playerId), true, 50)
	end
end

local function Overflow()
	print("OVERFLOW!!!!!")
	flushHandler.gameOnGoing = false
	RewardWinners()
	LineArray:ResetLine()
end

function flushHandler.AddFlushedTime(flushedTime: number, curPlayer: Player)
	if not flushHandler.gameOnGoing then
		return
	end

	flushHandler.totalTimeHeld += flushedTime
	print("TotalTimeHeld: " .. flushHandler.totalTimeHeld)

	if flushHandler.totalTimeHeld >= flushHandler.curCap then
		Overflow()
	else
		table.insert(playerHeldTime, { player = curPlayer, timeHeld = flushedTime })
	end
end

function flushHandler.StartToilet()
	flushHandler.gameOnGoing = true
	flushHandler.curCap = math.random(hardCap - 2, hardCap + 2)
	flushHandler.totalTimeHeld = 0
	playerHeldTime = {}
end

return flushHandler
