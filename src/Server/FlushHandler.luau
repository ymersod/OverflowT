local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EndGameScreenEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("EndGameScreen")

local Stats = require(ServerScriptService.Server.Persistence.Stats)
local LineArray = require(ServerScriptService.Server.LineArray)
local flushHandler = {
	curCap = 0,
	totalTimeHeld = 0,
}

type PlayerHeld = {
	player: Player,
	timeHeld: number,
}

local hardCap = 15 -- Seconds
-- TODO: Used for giving rewards later
local playerHeldTime: { PlayerHeld } = {}

local function RewardWinners()
	-- TODO: Coins should be rewarded from held time
	local playerIds = LineArray:GetLine()

	local losingPlayer = playerIds[1]
	EndGameScreenEvent:FireClient(Players:GetPlayerByUserId(losingPlayer, false))

	--Skipping first since he was the one who made it Overflow
	for i = 2, #playerIds do
		local playerId = playerIds[i]
		local stats = Stats.UpdatePlayerStats(playerId, function(currentStats)
			currentStats.Coins += 50
			currentStats.Wins += 1
			return currentStats
		end)
		print(stats)

		EndGameScreenEvent:FireClient(Players:GetPlayerByUserId(playerId, true, 50))
	end
end

local function Overflow()
	print("OVERFLOW!!!!!")
	RewardWinners()
	LineArray:ResetLine()
end

function flushHandler.AddFlushedTime(flushedTime: number, curPlayer: Player): boolean
	flushHandler.totalTimeHeld += flushedTime
	print("TotalTimeHeld: " .. flushHandler.totalTimeHeld)

	if flushHandler.totalTimeHeld >= flushHandler.curCap then
		Overflow()
		return false
	else
		table.insert(playerHeldTime, { player = curPlayer, timeHeld = flushedTime })
	end
	return true
end

function flushHandler.StartToilet()
	flushHandler.curCap = math.random(hardCap - 2, hardCap + 2)
	flushHandler.totalTimeHeld = 0
	playerHeldTime = {}
end

return flushHandler
