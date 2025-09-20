local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local localStats = Instance.new("Folder")
	localStats.Name = "LocalStats"
	localStats.Parent = player

	local states = Instance.new("Folder")
	states.Name = "States"
	states.Parent = player

	-- Determines position in line for client to observe
	local intVal = Instance.new("IntValue")
	intVal.Value = 0
	intVal.Name = "LinePosition"
	intVal.Parent = states

	local leaderStats = Instance.new("Folder")
	leaderStats.Name = "LeaderStats"
	leaderStats.Parent = player
end)
