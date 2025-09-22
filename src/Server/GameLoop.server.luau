local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TopBarUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("TopBarUpdate")
local GameCancelledEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("GameCancelled")

local FlushHandler = require(script.Parent.FlushHandler)
local Line = require(ServerScriptService.Server.LineArray)
local prevLine = { table.unpack(Line:GetLine()) }

local lobbyZone = CollectionService:GetTagged("LobbyZone")[1]
local lobbyHalfSize = lobbyZone.Size / 2

local INTERMISSION_TIME = 5 -- seconds
local timer = INTERMISSION_TIME

local function GetPlayersInLobby(): { Player }
	local playersInLobby = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local hrp = character.HumanoidRootPart
			local relativePos = lobbyZone.CFrame:PointToObjectSpace(hrp.Position)
			if
				math.abs(relativePos.X) <= lobbyHalfSize.X
				and math.abs(relativePos.Y) <= lobbyHalfSize.Y
				and math.abs(relativePos.Z) <= lobbyHalfSize.Z
			then
				table.insert(playersInLobby, player)
			end
		end
	end

	return playersInLobby
end

task.spawn(function()
	while true do
		timer = INTERMISSION_TIME
		if #Line:GetLine() == 0 then
			while timer > 0 do
				print("Next round in " .. math.floor(timer))
				task.wait(1)
				timer -= 1
			end

			local players = GetPlayersInLobby()
			if #players >= 1 then
				Line:Fill(players)
				FlushHandler.StartToilet()
			else
				GameCancelledEvent:FireAllClients("Cant start game, need at least 2 players ...")
			end
		end
		task.wait(1)
	end
end)

local function arraysEqual(a, b)
	if #a ~= #b then
		return false
	end

	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

RunService.Heartbeat:Connect(function()
	local currentLine = Line:GetLine()
	if #currentLine > 1 and FlushHandler.gameOnGoing then
		TopBarUpdateEvent:FireAllClients(Players:GetPlayerByUserId(currentLine[1]).Name, "Ongoing")
	elseif #currentLine == 0 and not FlushHandler.gameOnGoing then
		TopBarUpdateEvent:FireAllClients(math.max(0, math.floor(timer)), "Intermission")
	elseif #currentLine <= 0 and FlushHandler.gameOnGoing then
		FlushHandler.Overflow()
		GameCancelledEvent:FireAllClients("Game cancelled too few players !")
	end

	if arraysEqual(prevLine, currentLine) then
		return
	end

	prevLine = { table.unpack(currentLine) }
	local players = Players:GetChildren()
	for i = 1, #players do
		local player = players[i]

		local states = player:FindFirstChild("States")
		local index = Line:GetIndex(player.UserId)

		if index then
			states.LinePosition.Value = index
		else
			states.LinePosition.Value = 0
		end
	end
end)
