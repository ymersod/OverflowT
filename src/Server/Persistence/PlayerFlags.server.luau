local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local enums = require(ReplicatedStorage.Shared.enums)
local funnelEvents = require(ServerScriptService.Server.funnelEvents)

local playerFlags = DataStoreService:GetDataStore("PlayerFlags")

local PREFIX = "Onboarded_"

Players.PlayerAdded:Connect(function(player)
	local success, hasOnboarded = pcall(function()
		return playerFlags:GetAsync(PREFIX .. player.UserId)
	end)

	if not success then
		warn("Error reading onboarding flag for", player.Name)
		return
	end

	funnelEvents.playerFlagsCache[tostring(player.UserId)] = hasOnboarded or false -- hasOnboarded or false
	print(funnelEvents.playerFlagsCache)
	task.defer(function()
		funnelEvents.OnboardPlayersPlayer({ player }, enums.Analytics.Onboarding.Joined.Name)
	end)

	print(funnelEvents.playerFlagsCache)
	if not hasOnboarded then
		local success2, err = pcall(function()
			playerFlags:SetAsync(PREFIX .. player.UserId, true)
		end)

		if not success2 then
			warn("Failed to set onboarding flag:", err)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	funnelEvents.playerFlagsCache[tostring(player.UserId)] = nil
end)
