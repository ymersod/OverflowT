local Player = game:GetService("Players").LocalPlayer

local LeaderStats = Player:WaitForChild("LeaderStats")
local money: IntValue? = LeaderStats:WaitForChild("Money")
local wins: IntValue? = LeaderStats:WaitForChild("Wins")

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local leaderStatsFrame = ScreenGUI:WaitForChild("LeaderStats")
local winsText = leaderStatsFrame:WaitForChild("Wins"):FindFirstChildOfClass("TextLabel")
local moneyText = leaderStatsFrame:WaitForChild("Money"):FindFirstChildOfClass("TextLabel")

function Observe()
	if money then
		moneyText.Text = "$ " .. money.Value
		money.Changed:Connect(function(newVal)
			moneyText.Text = "$ " .. newVal
		end)
	else
		warn("Didnt find the leaderstat money")
	end

	if wins then
		winsText.Text = wins.Value
		wins.Changed:Connect(function(newVal)
			winsText.Text = newVal
		end)
	else
		warn("Didnt find the leaderstat wins")
	end
end
Observe()
