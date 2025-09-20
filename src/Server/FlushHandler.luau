local ServerScriptService = game:GetService("ServerScriptService")
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local LineArray = require(ServerScriptService.Server.LineArray)
local flushHandler = {}

type PlayerHeld = {
	player: Player,
	timeHeld: number,
}

local hardCap = 10 -- Seconds
local curCap = 0
local totalTimeHeld = 0
-- TODO: Used for giving rewards later
local playerHeldTime: { PlayerHeld } = {}

local function RewardWinners()
	-- TODO: Coins should be rewarded from held time
	local playerIds = LineArray:GetLine()
	--Skipping first since he was the one who made it Overflow
	for i = 2, #playerIds do
		playerId = playerIds[i]
		Stats.UpdatePlayerStats(playerId, function(currentStats)
			currentStats.Coins += 50
			currentStats.Wins += 1
		end)
	end
end

local function Overflow()
	print("OVERFLOW!!!!!")
	RewardWinners()
	LineArray:ResetLine()
end

function flushHandler.AddFlushedTime(flushedTime: number, curPlayer: Player): boolean
	totalTimeHeld += flushedTime
	print("TotalTimeHeld: " .. totalTimeHeld)

	if totalTimeHeld >= curCap then
		Overflow()
		return false
	else
		table.insert(playerHeldTime, { player = curPlayer, timeHeld = flushedTime })
	end
	return true
end

function flushHandler.StartToilet()
	curCap = math.random(hardCap - 2, hardCap + 2)
	totalTimeHeld = 0
	playerHeldTime = {}
end

return flushHandler
