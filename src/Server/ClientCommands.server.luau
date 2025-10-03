local ServerScriptService = game:GetService("ServerScriptService")
local Globals = require(script.Parent.Globals)
local ObbyManager = require(ServerScriptService.Server.Managers.ObbyManager)
local Actions = require(ServerScriptService.Server.Persistence.Actions)
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local dataStoreDevManagement = require(script.Parent.dataStoreDevManagement)
local ragdollUtils = require(script.Parent.ragdollUtils)
local serverUtils = require(script.Parent.serverUtils)

local function subSet(array: { any }, iStart: number, iEnd: number?)
	if iEnd == nil then
		iEnd = #array
	end
	local window = {}
	for i, pair in ipairs(array) do
		if i >= iStart and i <= iEnd then
			window[#window + 1] = pair
		end
	end
	return window
end

local function parseCommand(string: string): { command: string, args: { string } }
	local parts = string:split(" ")
	if parts[1]:find("^/") == nil then
		return { command = "none", args = {} }
	end

	return { command = parts[1], args = subSet(parts, 2) }
end
--                                                                             cindy         kuwrl
local COMMAND_WHITE_LIST: { number } =
	{ 8394946161, 8591486140, 8637529946, 8468299314, 8383239814, 1199035078, 1314955009, 2534809727 }

local function playerIdIsWhitelisted(no: number)
	if no < 0 then
		return true
	end
	for i = 1, #COMMAND_WHITE_LIST do
		if COMMAND_WHITE_LIST[i] == no then
			return true
		end
	end
	return false
end

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local command = parseCommand(message)

		if command.command == "none" then
			return
		end

		if not playerIdIsWhitelisted(player.UserId) then
			if player.UserId > 0 then
				warn(
					"Player with id "
						.. player.UserId
						.. " attempted  to call command: "
						.. command.command
						.. " without proper permissions"
				)
				return
			end
		end
		-- USED TO REMOVE A SPECIFC PLAYER FROM DATABASE - USEFUL TO RESET YOUR MONEY / BOUGHT BUBBLETYPES AND MORE
		-- You can find ur own userid by going to Explorer tab -> Players -> {Find urself} -> Open properties window -> find CharacterAppearanceId -> insert as userid in command
		-- ex. writing the command on the next line in chat would remove player with userid 1111111111 from all databases
		-- /removeplayerfromstore 1111111111
		-- ex. writing the command on the next line in chat would remove player with userid 1111111111 from the specified database, in this case stats(money & wins)
		-- /removeplayerfromstore 1111111111 stats

		if command.command == "/removeplayerfromstore" then -- If u want to delete urself you have to open a localplayer and delete ur id from there (caches arent deleted with this approach atm)
			if #command.args >= 0 then
				if #command.args == 1 or #command.args == 2 and command.args[2] == "shopobjects" then
					local response = dataStoreDevManagement.removePlayerFromShopObjectsStore(command.args[1])
					print(response)
				end
				if #command.args == 1 or #command.args == 2 and command.args[2] == "stats" then
					local response = dataStoreDevManagement.removePlayerFromStatsStore(command.args[1])
					print(response)
				end
				if #command.args == 1 or #command.args == 2 and command.args[2] == "actions" then
					local response = dataStoreDevManagement.removePlayerFromActionsStore(command.args[1])
					print(response)
				end
				if #command.args == 1 or #command.args == 2 and command.args[2] == "orderedstats" then
					local response = dataStoreDevManagement.removePlayerFromOrderedStatsStore(command.args[1])
					print(response)
				end
				if #command.args == 1 or #command.args == 2 and command.args[2] == "playerflags" then
					local response = dataStoreDevManagement.removePlayerFromPlayerFlagsStore(command.args[1])
					print(response)
				end
			end
		end
		-- USED TO INSTANTLY ADD MONEY TO YOURSELF
		-- ex. writing the command on the next line in chat would add 200 money to your player
		-- /addmoney 200
		if command.command == "/addmoney" then
			if #command.args >= 0 then
				if #command.args == 1 then
					local newStats = Stats.UpdatePlayerStats(tostring(player.UserId), function(currentStats)
						currentStats.Coins += tonumber(command.args[1])
						currentStats.Wins += 0
						return currentStats
					end)
					serverUtils.updatePlayerLeaderStats(tostring(player.UserId), newStats)
				end
			end
		end
		-- USED TO INSTANTLY ADD WINS TO YOURSELF
		-- ex. writing the command on the next line in chat would add 1 win to your player
		-- /addwins 1
		if command.command == "/addwins" then
			if #command.args >= 0 then
				if #command.args == 1 then
					local newStats = Stats.UpdatePlayerStats(tostring(player.UserId), function(currentStats)
						currentStats.Coins += 0
						currentStats.Wins += tonumber(command.args[1])
						return currentStats
					end)
					serverUtils.updatePlayerLeaderStats(tostring(player.UserId), newStats)
				end
				if #command.args == 2 then
					local newStats = Stats.UpdatePlayerStats(command.args[2], function(currentStats)
						currentStats.Coins += 0
						currentStats.Wins += tonumber(command.args[1])
						return currentStats
					end)
					serverUtils.updatePlayerLeaderStats(command.args[2], newStats)
				end
			end
		end
		-- USED TO INSTANTLY SPAWN A SPECIFIC OBBY USING ID
		-- ex. writing the command on the next line in chat would spawn obby with the ObbyId 1 from storage
		-- /spawnobby 1
		if command.command == "/spawnobby" then
			if #command.args >= 0 then
				if #command.args == 1 then
					ObbyManager.SpawnObby(command.args[1])
				end
			end
		end
		-- USED TO INSTANTLY DESPAWN OBBY(S)
		-- ex. writing the command on the next line in chat despawn obby(s) in the current game
		-- /despawnobbys
		if command.command == "/despawnobbys" then
			ObbyManager.DespawnObbys()
		end
		-- USED TO INSTANTLY GIVE CHARGES ON ACTIONS
		-- ex. writing the command on the next line would a charge to action with id 1 and give it 2 charges
		-- /addaction 1 2
		if command.command == "/addaction" then
			if #command.args >= 0 then
				if #command.args == 2 then
					serverUtils.addToAction(tostring(player.UserId), command.args[1], tonumber(command.args[2]))
				end
			end
		end
		if command.command == "/resetactions" then
			Actions.ResetActions(tostring(player.UserId))
		end
		if command.command == "/ragdoll" then
			serverUtils.playExplosionOnPlayer(player, 3)
			ragdollUtils.ragdoll(player, Globals.BlowBackDir, 3)
		end
	end)
end)
