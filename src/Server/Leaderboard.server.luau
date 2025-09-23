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
local firstPlaceAvatar: Model = leaderboard:WaitForChild("First Place Avatar")
local firstPlaceRig = firstPlaceAvatar:FindFirstChildOfClass("Model")
local firstPlaceCFrame = firstPlaceRig.PrimaryPart.CFrame

local LEADERBOARD_UPDATE = 100
local curTime = 0

local function UpdateLeaderboardWorldData(top10Arr: { key: string, value: number }?)
	if not top10Arr then
		warn("Error in fetching data")
		return
	end

	for i, topPlayer in ipairs(top10Arr) do
		local playerId = tonumber(topPlayer.key)
		local player = Players:GetPlayerByUserId(playerId)

		for _, leaderboardName in ipairs(leaderboardNames) do
			if leaderboardName.Name == "Name" .. i then
				leaderboardName.Text = player and player.Name or "Player " .. playerId
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

		if i == 1 then

			-- model:PivotTo(firstPlaceCFrame)
			-- https://www.youtube.com/watch?v=aznei-44QJo tommroow
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
