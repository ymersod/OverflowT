local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local tags = require(ReplicatedStorage.Shared.tags)

local leaderboard = CollectionService:GetTagged(tags.LEADERBOARD)[1]
local leaderboardTimer =
	leaderboard:WaitForChild("UpdateBoardTimer"):FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
local leaderboardSpots = leaderboard:WaitForChild("ScoreBlock"):WaitForChild("Leaderboard")
local leaderboardNames: { TextLabel } = leaderboardSpots:WaitForChild("Names"):GetChildren()
local leaderboardPhotos: { ImageLabel } = leaderboardSpots:WaitForChild("Photos"):GetChildren()
local leaderboardScores: { TextLabel } = leaderboardSpots:WaitForChild("Score"):GetChildren()
local topPlayers = CollectionService:GetTagged(tags.TOP_PLAYERS)[1]

local LEADERBOARD_UPDATE = 60
local curTime = 0

local function SetTopModel(userId: string, wins: number, i: number)
	local spot = topPlayers:FindFirstChild(i)

	if spot then
		local statue: Model? = spot:FindFirstChild("Statue")
		local hum: Humanoid? = statue and statue:FindFirstChildOfClass("Humanoid")
		local animator: Animator? = hum and hum:FindFirstChildOfClass("Animator")
		local animation: Animation? = statue and statue:FindFirstChildOfClass("Animation")

		if hum and animator and animation then
			if tonumber(userId) > 0 then
				hum:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(tonumber(userId)))
			end
			local anim
			pcall(function()
				anim = animator:LoadAnimation(animation)
			end)
			anim:Play()
		end

		local statsHolder = spot and spot:FindFirstChild("Stats") :: Part?
		local bb = statsHolder and statsHolder:FindFirstChildOfClass("BillboardGui")
		local frame = bb and bb:FindFirstChildOfClass("Frame")
		local winsText: TextLabel? = frame and frame:FindFirstChild("MoneyAmount")
		local playerName: TextLabel? = frame and frame:FindFirstChild("PlayerName")

		if winsText and playerName then
			winsText.Text = "WINS: " .. wins
			if tonumber(userId) > 0 then
				playerName.Text = "#" .. i .. " " .. Players:GetNameFromUserIdAsync(userId)
			else
				playerName.Text = "#" .. i .. " " .. "Player " .. userId
			end
		end
	end
end

local function UpdateLeaderboardWorldData(top10Arr: { key: string, value: number }?)
	if not top10Arr then
		warn("Error in fetching data")
		return
	end

	for i, topPlayer in ipairs(top10Arr) do
		local playerId = tonumber(topPlayer.key)
		local name
		if playerId > 0 then
			name = Players:GetNameFromUserIdAsync(playerId)
		else
			name = "Player " .. playerId
		end

		for _, leaderboardName in ipairs(leaderboardNames) do
			if leaderboardName.Name == "Name" .. i then
				leaderboardName.Text = name and name or "Player " .. playerId
			end
		end
		for _, leaderboardScore in ipairs(leaderboardScores) do
			if leaderboardScore.Name == "Score" .. i then
				leaderboardScore.Text = topPlayer.value
			end
		end
		for _, leaderboardPhoto in ipairs(leaderboardPhotos) do
			if leaderboardPhoto.Name == "Photo" .. i then
				if tonumber(topPlayer.key) > 0 then
					local successThumb, thumbnailUrl = pcall(function()
						local thumbType = Enum.ThumbnailType.HeadShot
						local thumbSize = Enum.ThumbnailSize.Size48x48
						return Players:GetUserThumbnailAsync(playerId, thumbType, thumbSize)
					end)
					if successThumb then
						leaderboardPhoto.Image = thumbnailUrl
					end
				end
			end
		end

		if i <= 3 then
			SetTopModel(topPlayer.key, topPlayer.value, i)
		end
	end
end

RunService.Heartbeat:Connect(function()
	local timeDiff = os.clock() - curTime
	if timeDiff >= LEADERBOARD_UPDATE then
		curTime = os.clock()
		UpdateLeaderboardWorldData(Stats.GetTopPlayers(10))
		-- updateleaderboard
	end

	leaderboardTimer.Text = "Update the leaderboard in " .. LEADERBOARD_UPDATE - math.round(timeDiff) .. " seconds"
end)
