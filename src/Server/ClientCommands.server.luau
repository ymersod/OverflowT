local players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local dataStoreDevManagement = require(script.Parent.dataStoreDevManagement)
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
			end
		end
		if command.command == "/addmoney" then
			if #command.args >= 0 then
				if #command.args == 1 then
					local newStats = Stats.UpdatePlayerStats(tostring(player.UserId), function(currentStats)
						currentStats.Coins += command.args[1]
						currentStats.Wins += 0
						return currentStats
					end)
					serverUtils.updatePlayerLeaderStats(tostring(player.UserId), newStats)
				end
			end
		end
	end)
end)
