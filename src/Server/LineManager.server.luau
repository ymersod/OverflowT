local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Line = require(ServerScriptService.Server.LineArray)
local LineEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("LineEvents")

local SkipAheadEvent = LineEvents:WaitForChild("SkipAhead")
local CutAllEvent = LineEvents:WaitForChild("CutAll")
local NextEvent = LineEvents:WaitForChild("Next")
local RemoveEvent = LineEvents:WaitForChild("Remove")

RunService.Heartbeat:Connect(function()
	Line:ProcessNext()
end)

SkipAheadEvent.OnServerEvent:Connect(function(player: Player)
	Line:Enqueue(Line.OperationType.SkipAhead, player.UserId)
end)

CutAllEvent.OnServerEvent:Connect(function(player: Player)
	Line:Enqueue(Line.OperationType.CutAll, player.UserId)
end)

NextEvent.OnServerEvent:Connect(function(player: Player)
	Line:Enqueue(Line.OperationType.Next, player.UserId)
end)

RemoveEvent.OnServerEvent:Connect(function(player: Player)
	Line:Enqueue(Line.OperationType.Remove, player.UserId)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	Line:Enqueue(Line.OperationType.Remove, player.UserId)
end)
