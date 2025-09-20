local ServerScriptService = game:GetService("ServerScriptService")
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

local function Overflow()
	print("OVERFLOW!!!!!")
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
