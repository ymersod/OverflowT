local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local LineArray = require(script.Parent.LineArray)
local afkWarning = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("AfkWarning")

local curFirstInLine
local warningCalled, warnedPlayer
local timer = os.clock()
local AFK_CAP = 20 -- 20
local UNTIL_WARNING = 5 -- 5

local function checkAfks()
	while true do
		task.wait(1)
		local line = LineArray.Line
		if not line or #line <= 1 then
			if warningCalled then
				afkWarning:FireClient(warnedPlayer, false)
				warningCalled = false
				warnedPlayer = nil
			end
			timer = os.clock()
			continue
		end
		local player = Players:GetPlayerByUserId(line[1])
		if curFirstInLine == line[1] then
			local diff = math.ceil(os.clock() - timer)
			print("How long have i been afk ", diff)

			if diff >= AFK_CAP - UNTIL_WARNING then
				if player then
					afkWarning:FireClient(player, true, AFK_CAP - diff)
					warningCalled = true
					warnedPlayer = player
				end
			end
			if diff >= AFK_CAP then
				SoundEffectHandler.Play("AfkKick")
				LineArray:Enqueue(LineArray.OperationType.Remove, line[1])
			end
		else
			timer = os.clock()
			curFirstInLine = line[1]
			if warningCalled then
				afkWarning:FireClient(warnedPlayer, false)
				warningCalled = false
				warnedPlayer = nil
			end
		end
	end
end
task.spawn(checkAfks)
