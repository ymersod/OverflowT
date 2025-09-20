local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local FlushHandler = require(script.Parent.FlushHandler)
local Line = require(ServerScriptService.Server.LineArray)
local prevLine = { table.unpack(Line:GetLine()) }

local lobbyZone = CollectionService:GetTagged("LobbyZone")[1]
local lobbyHalfSize = lobbyZone.Size / 2

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

-- Main loop
task.spawn(function()
	while true do
		task.wait(5) -- INTERMISSION TIME

		if #Line:GetLine() > 0 then
			print("Game is ongoing!")
		else
			Line:Fill(GetPlayersInLobby())
			FlushHandler.StartToilet()
			print("Line filled with players after 10 seconds")
		end
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
	if arraysEqual(prevLine, currentLine) then
		return
	end
	print(currentLine)
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
