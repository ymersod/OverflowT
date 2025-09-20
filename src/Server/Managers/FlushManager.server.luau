local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)

local GameEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("GameEvents")
local StartFlushEvent = GameEvents:WaitForChild("StartFlush")
local FinishFlushEvent = GameEvents:WaitForChild("FinishFlush")

local serverTimer = 0

StartFlushEvent.OnServerEvent:Connect(function(_: Player)
	serverTimer = os.clock()
end)

FinishFlushEvent.OnServerInvoke = function(player: Player)
	local clockedTime = os.clock() - serverTimer
	print(clockedTime)
	return FlushHandler.AddFlushedTime(clockedTime, player)
end
