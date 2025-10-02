local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local clientUitls = require(ReplicatedStorage.Shared.clientUitls)
local Player = game:GetService("Players").LocalPlayer

local LeaderStats = Player:WaitForChild("leaderstats")
local money: IntValue? = LeaderStats:WaitForChild("Money")
local wins: IntValue? = LeaderStats:WaitForChild("Wins")

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local leaderStatsFrame = ScreenGUI:WaitForChild("LeaderStats")
local winsText = leaderStatsFrame:WaitForChild("Wins"):FindFirstChildOfClass("TextLabel")
local moneyText = leaderStatsFrame:WaitForChild("Money"):FindFirstChildOfClass("TextLabel")
local moneyToAdd = leaderStatsFrame:WaitForChild("MoneyToAdd") :: Frame
local moneyToAddText = moneyToAdd:FindFirstChildOfClass("TextLabel")

local COUNTING_MONEY_DUR = SoundEffectHandler.GetSound("CountingMoney").TimeLength
local PULSE_SIZE = 1.4
local PULSE_DUR = 0.1

local ELASTIC_DUR = 0.4
local FADEOUT_TIME = 3
function Observe()
	if money then
		moneyText.Text = "$ " .. money.Value
		money.Changed:Connect(function(newVal)
			SoundEffectHandler.Play("CountingMoney")
			local oldValString = moneyText.Text
			local oldVal = tonumber(oldValString:match("%d+"))
			local diff = money.Value - oldVal
			if diff < 0 then
				moneyToAddText.Text = "- $" .. math.abs(diff)
			else
				moneyToAddText.Text = "+ $" .. diff
			end
			clientUitls.CountUpNumberLabel(
				moneyText,
				"$ ",
				oldVal,
				newVal,
				COUNTING_MONEY_DUR,
				true,
				PULSE_SIZE,
				PULSE_DUR,
				PULSE_DUR,
				function()
					local fadeOut =
						clientUitls.PopFrameElastic(moneyToAdd, moneyToAdd.Size, ELASTIC_DUR, FADEOUT_TIME, false)
					SoundEffectHandler.Play("Kaching")
					fadeOut()
				end
			)
		end)
	else
		warn("Didnt find the leaderstat money")
	end

	if wins then
		winsText.Text = "👑 " .. wins.Value
		wins.Changed:Connect(function(newVal)
			local oldValString = winsText.Text
			local oldVal = tonumber(oldValString:match("%d+"))
			clientUitls.CountUpNumberLabel(
				winsText,
				"👑 ",
				oldVal,
				newVal,
				COUNTING_MONEY_DUR,
				true,
				PULSE_SIZE,
				PULSE_DUR,
				PULSE_DUR
			)
		end)
	else
		warn("Didnt find the leaderstat wins")
	end
end
Observe()
