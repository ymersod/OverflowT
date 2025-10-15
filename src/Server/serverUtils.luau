local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local tags = require(ReplicatedStorage.Shared.tags)
local Actions = require(ServerScriptService.Server.Persistence.Actions)
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local funnelEvents = require(ServerScriptService.Server.funnelEvents)
local enums = require(ReplicatedStorage.Shared.enums)

local cuttingActions = CollectionService:GetTagged(tags.CUTTING_ACTIONS)[1] :: BillboardGui

local serverUtils = {}

local explosionPrefab: Explosion = ServerStorage:WaitForChild("ExplosionPrefab")
local playerSpots = CollectionService:GetTagged(tags.SPOT_TAG)

function serverUtils.updatePlayerLeaderStats(playerId: string, playerStats: Stats.PlayerStats)
	-- print("do it")
	local player = Players:GetPlayerByUserId(playerId)
	local leaderStats = player:FindFirstChild("leaderstats")

	local money: IntValue? = leaderStats:FindFirstChild("Money")
	local wins: IntValue? = leaderStats:FindFirstChild("Wins")
	local winStreak: IntValue? = leaderStats:FindFirstChild("WinStreak")

	if money and money:IsA("IntValue") then
		money.Value = playerStats.Coins
	end
	if wins and wins:IsA("IntValue") then
		wins.Value = playerStats.Wins
	end
	if winStreak and winStreak:IsA("IntValue") then
		winStreak.Value = playerStats.WinStreak
	end
end

function serverUtils.modifyPlayerLeaderStats(playerId: string, mode: "Wins" | "Money" | "WinStreak", amount: number)
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
	if mode == "WinStreak" then
		local winStreak: IntValue? = leaderStats:FindFirstChild("WinStreak")
		if winStreak then
			if amount >= 0 then
				winStreak.Value += amount
			else
				winStreak.Value = 0
			end
		end
	end
end

function serverUtils.GetLeaderStatVal(playerId: string, mode: "Wins" | "Money" | "WinStreak"): number?
	local player = Players:GetPlayerByUserId(playerId)
	local leaderStats = player:FindFirstChild("leaderstats")

	if mode == "Money" then
		local money: IntValue? = leaderStats:FindFirstChild("Money")
		if money then
			return money.Value
		end
	end
	if mode == "Wins" then
		local wins: IntValue? = leaderStats:FindFirstChild("Wins")
		if wins then
			return wins.Value
		end
	end
	if mode == "WinStreak" then
		local winStreak: IntValue? = leaderStats:FindFirstChild("WinStreak")
		if winStreak then
			return winStreak.Value
		end
	end

	return nil
end

function PromptRobuxPurchase(player, actionId)
	task.defer(function()
		funnelEvents.LogStepPlayers(
			{ player },
			enums.Analytics.Game.TryUseAction.Name,
			enums.Analytics.Game.SessionName,
			false,
			true
		)
	end)
end

function serverUtils.getActionIfUsable(playerId: string, actionId: string): IntValue?
	local player = Players:GetPlayerByUserId(playerId)
	local localstats = player and player:FindFirstChild("localstats")
	local localstatsactions = localstats and localstats:FindFirstChild("localstatsactions")
	if not localstatsactions then
		return nil
	end
	for _, action in ipairs(localstatsactions:GetChildren()) do
		if action:IsA("IntValue") and action.Name == actionId then
			if action.Value > 0 then
				PromptRobuxPurchase(player, actionId)
				return action
			else
				return nil
			end
		end
	end
	return nil
end

function serverUtils.updateActionDB(playerId: string, action: IntValue)
	local val = action.Value
	if val >= 1 then
		action.Value -= 1
		Actions.UpdateCache(playerId, action.Name, -1)
		funnelEvents.LogStepPlayerIds(
			{ playerId },
			enums.Analytics.Game.UsedActon.Name,
			enums.Analytics.Game.SessionName,
			false,
			true
		)
		return true
	end
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

function serverUtils.ActionOnPlayer(player: Player)
	local sound = SoundEffectHandler.GetSound("CutSound")
	local soundClone = sound:Clone()
	soundClone.Parent = player
	soundClone:Play()
	soundClone.Ended:Once(function()
		soundClone:Destroy()
	end)

	local char = player.Character
	local head = char and char:FindFirstChild("Head")

	if not (char and head) then
		return
	end

	local bbClone = cuttingActions:Clone()
	local frame = bbClone:FindFirstChildOfClass("Frame")
	local imgLabel = frame and frame:FindFirstChildOfClass("ImageLabel")

	if not (frame and imgLabel) then
		return
	end

	bbClone.Parent = head

	frame.Size = UDim2.fromScale(0, 0)
	frame.BackgroundTransparency = 1
	imgLabel.ImageTransparency = 1

	local popUpTween =
		TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1, 1),
		})

	local fadeInImage =
		TweenService:Create(imgLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0,
		})

	local fadeOutTween =
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromScale(0, 0),
		})

	local fadeOutImage =
		TweenService:Create(imgLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			ImageTransparency = 1,
		})

	popUpTween:Play()
	fadeInImage:Play()

	task.delay(1.5, function()
		fadeOutTween:Play()
		fadeOutImage:Play()

		fadeOutImage.Completed:Once(function()
			bbClone:Destroy()
		end)
	end)
end

return serverUtils
