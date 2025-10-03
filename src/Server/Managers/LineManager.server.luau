local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local tags = require(ReplicatedStorage.Shared.tags)
local Line = require(ServerScriptService.Server.LineArray)
local ActionHandler = require(ServerScriptService.Server.ActionHandler)
local serverUtils = require(ServerScriptService.Server.serverUtils)
local LineEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("LineEvents")

local SkipAheadEvent = LineEvents:WaitForChild("SkipAhead")
local CutAllEvent = LineEvents:WaitForChild("CutAll")
local NextEvent = LineEvents:WaitForChild("Next")
local RemoveEvent = LineEvents:WaitForChild("Remove")

local isJammed: BoolValue = CollectionService:GetTagged(tags.IS_JAMMED)[1]

local function makeLineAction(player, actionId, lineFunc, validationFunc: (() -> boolean)?)
	return function()
		local playerId = player.UserId
		local usableAction = serverUtils.getActionIfUsable(playerId, actionId)
		if not usableAction then
			return
		end
		if validationFunc and not validationFunc() then
			return
		end
		local success = lineFunc(Line, playerId)
		if not success then
			return
		end
		serverUtils.updateActionDB(playerId, usableAction)
	end
end

SkipAheadEvent.OnServerEvent:Connect(function(player: Player, actionId: string)
	print(player.UserId .. " skipping one")
	ActionHandler:Enqueue(makeLineAction(player, actionId, Line.SkipAhead))
end)

CutAllEvent.OnServerEvent:Connect(function(player: Player, actionId: string)
	print(player.UserId .. " cuts all")
	ActionHandler:Enqueue(makeLineAction(player, actionId, Line.CutAll))
end)

NextEvent.OnServerEvent:Connect(function(player: Player, from: "Flush" | "SkipAhead", actionId: string?)
	print(player.UserId .. " next")

	if from == "SkipAhead" then
		ActionHandler:Enqueue(makeLineAction(player, actionId, Line.Next, function()
			return Line:GetIndex(player.UserId) == 1
		end))
		return
	end

	if isJammed.Value then
		print("sry is jammed haha")
		return
	end
	ActionHandler:Enqueue(function()
		if Line:GetLine()[1] == player.UserId then
			Line:Next()
		end
	end)
end)

RemoveEvent.OnServerEvent:Connect(function(player: Player)
	ActionHandler:Enqueue(function()
		Line:Remove(player.UserId)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	ActionHandler:Enqueue(function()
		Line:Remove(player.UserId)
	end)
end)

RunService.Heartbeat:Connect(function()
	ActionHandler:Process()
end)
