local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ServerScriptService = game:GetService("ServerScriptService")
local Line = require(ServerScriptService.Server.LineArray)
local prevLine = { table.unpack(Line:GetLine()) }

task.delay(30, function()
	local currentPlayers = Players:GetPlayers()
	Line:Fill(currentPlayers)
	print("Line filled with players after 10 seconds")
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
	for i = 1, #currentLine do
		local player = Players:GetPlayerByUserId(currentLine[i])
		if not player then
			continue
		end
		local states = player:FindFirstChild("States")
		states.LinePosition.Value = i
	end
end)
