local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local tags = require(ReplicatedStorage.Shared.tags)
local Actions = require(ServerScriptService.Server.Persistence.Actions)
local Stats = require(ServerScriptService.Server.Persistence.Stats)

local serverUtils = {}

local explosionPrefab: Explosion = ServerStorage:WaitForChild("ExplosionPrefab")
local playerSpots = CollectionService:GetTagged(tags.SPOT_TAG)

function serverUtils.updatePlayerLeaderStats(playerId: string, playerStats: Stats.PlayerStats)
	-- print("do it")
	local player = Players:GetPlayerByUserId(playerId)
	local leaderStats = player:FindFirstChild("leaderstats")

	local money: IntValue? = leaderStats:FindFirstChild("Money")
	local wins: IntValue? = leaderStats:FindFirstChild("Wins")

	if money and money:IsA("IntValue") then
		money.Value = playerStats.Coins
	end
	if wins and wins:IsA("IntValue") then
		wins.Value = playerStats.Wins
	end
end

function serverUtils.modifyPlayerLeaderStats(playerId: string, mode: "Wins" | "Money", amount: number)
	local player = Players:GetPlayerByUserId(playerId)
	local leaderStats = player:FindFirstChild("leaderstats")

	if mode == "Money" then
		local money: IntValue? = leaderStats:FindFirstChild("Money")
		if money then
			money.Value += amount
		end
	end
	if mode == "Wins" then
		local wins: IntValue? = leaderStats:FindFirstChild("Wins")
		if wins then
			wins.Value += amount
		end
	end
end

function serverUtils.useAction(playerId: string, actionId: string)
	local player = Players:GetPlayerByUserId(playerId)
	local localstats = player and player:FindFirstChild("localstats")
	local localstatsactions = localstats and localstats:FindFirstChild("localstatsactions")

	if localstatsactions then
		local currAction
		for _, action in ipairs(localstatsactions:GetChildren()) do
			if action:IsA("IntValue") and action.Name == actionId then
				currAction = action
			end
		end

		if currAction then
			local val = currAction.Value
			if val >= 1 then
				currAction.Value -= 1
				Actions.UpdateCache(playerId, actionId, -1)
				return true
			end
		end
	end

	return false
end

function serverUtils.addToAction(playerId: string, actionId: string, val: number?)
	local player = Players:GetPlayerByUserId(playerId)
	local localstats = player and player:FindFirstChild("localstats")
	local localstatsactions = localstats and localstats:FindFirstChild("localstatsactions")

	if localstatsactions then
		local currAction
		for _, action in ipairs(localstatsactions:GetChildren()) do
			if action:IsA("IntValue") and action.Name == actionId then
				currAction = action
			end
		end

		if currAction then
			currAction.Value += val or 1
			Actions.UpdateCache(playerId, actionId, val or 1)
		end
	end
end

function serverUtils.handlePlayerSpots(toEnable: boolean, lineAmount: number?)
	if not lineAmount then
		lineAmount = 6
	end
	print(lineAmount)
	for _, spot in ipairs(playerSpots) do
		local spotId = spot:GetAttribute("ArrayIndex")
		if spotId and spotId > lineAmount then
			continue
		end

		if spot:IsA("BasePart") then
			spot.Transparency = toEnable and 0 or 1
			for _, el in ipairs(spot:GetDescendants()) do
				if el:IsA("BasePart") or el:IsA("UIStroke") then
					el.Transparency = toEnable and 0 or 1
				end
				if el:IsA("TextLabel") then
					el.TextTransparency = toEnable and 0 or 1
				end
			end
		end
	end
end

function serverUtils.playExplosionOnPlayer(player: Player, delay: number)
	local char = player and player.Character
	local root: Part? = char and char:FindFirstChild("HumanoidRootPart")

	if char and root then
		local explosionClone = explosionPrefab:Clone()
		explosionClone.Position = root.CFrame.Position
		explosionClone.Parent = char

		task.delay(delay, function()
			explosionClone:Destroy()
		end)
	end
end

return serverUtils
