local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Globals = require(script.Parent.Globals)
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local enums = require(ReplicatedStorage.Shared.enums)
local LineArray = require(script.Parent.LineArray)
local ragdollUtils = require(script.Parent.ragdollUtils)
local serverUtils = require(script.Parent.serverUtils)
local ServerScriptService = game:GetService("ServerScriptService")
local ActionHandler = require(ServerScriptService.Server.ActionHandler)
local afkWarning = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("AfkWarning")
local EndGameScreenEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("EndGameScreen")

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

		if curFirstInLine == line[1] and not Globals.flushStarted then
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
				local playerId = line[1]
				ActionHandler:Enqueue(function()
					if LineArray.Line[1] == playerId then
						EndGameScreenEvent:InvokeClient(player, enums.EndGameScreen.Afk)
						LineArray:Remove(playerId)
						serverUtils.playExplosionOnPlayer(player, 3)
						ragdollUtils.ragdoll(player, Globals.BlowBackDir, 3)
					end
				end)
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
