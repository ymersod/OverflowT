local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)

local GameEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("GameEvents")
local StartFlushEvent = GameEvents:WaitForChild("StartFlush")
local FinishFlushEvent = GameEvents:WaitForChild("FinishFlush")

local serverTimer = 0
local inactive = true
local currentHolder = nil

StartFlushEvent.OnServerEvent:Connect(function(player: Player)
	currentHolder = player
	serverTimer = os.clock()
	inactive = false
end)

FinishFlushEvent.OnServerInvoke = function(player: Player)
	if inactive then
		return false --This is to say, there has happened an overflow
	end
	inactive = true
	return true
end

RunService.Heartbeat:Connect(function()
	if inactive then
		return
	end
	local clockedTime = os.clock() - serverTimer
	local isStillRunning = FlushHandler.AddFlushedTime(clockedTime, currentHolder)
	inactive = not isStillRunning
end)
