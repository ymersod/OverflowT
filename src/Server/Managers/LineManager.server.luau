local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local tags = require(ReplicatedStorage.Shared.tags)
local Line = require(ServerScriptService.Server.LineArray)
local LineEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("LineEvents")

local SkipAheadEvent = LineEvents:WaitForChild("SkipAhead")
local CutAllEvent = LineEvents:WaitForChild("CutAll")
local NextEvent = LineEvents:WaitForChild("Next")
local RemoveEvent = LineEvents:WaitForChild("Remove")

local isJammed: BoolValue = CollectionService:GetTagged(tags.IS_JAMMED)[1]

RunService.Heartbeat:Connect(function()
	Line:ProcessNext()
end)

SkipAheadEvent.OnServerEvent:Connect(function(player: Player)
	print(player.UserId .. " skipping one")
	Line:Enqueue(Line.OperationType.SkipAhead, player.UserId)
end)

CutAllEvent.OnServerEvent:Connect(function(player: Player)
	print(player.UserId .. " cuts all")
	Line:Enqueue(Line.OperationType.CutAll, player.UserId)
end)

NextEvent.OnServerEvent:Connect(function(player: Player, from: "Flush" | "SkipAhead")
	print(player.UserId .. " next")

	if from == "Flush" and isJammed.Value then
		print("sry is jammed haha")
		return
	else
		Line:Enqueue(Line.OperationType.Next, player.UserId)
	end
end)

RemoveEvent.OnServerEvent:Connect(function(player: Player)
	Line:Enqueue(Line.OperationType.Remove, player.UserId)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	Line:Enqueue(Line.OperationType.Remove, player.UserId)
end)
