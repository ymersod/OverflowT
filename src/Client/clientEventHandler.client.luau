local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ClientEvents")
local TopBarUpdate = clientEvents:WaitForChild("TopBarUpdate")
local EndGameScreen = clientEvents:WaitForChild("EndGameScreen")
local GameCancelledEvent = clientEvents:WaitForChild("GameCancelled")
local RespawnToObbyEvent = clientEvents:WaitForChild("RespawnToObby")
local WinObbyEvent = clientEvents:WaitForChild("ObbyWin")
local PlayTimeRewardEvent = clientEvents:WaitForChild("PlaytimeReward")
local UpdateStatsEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("StatsEvents")
	:WaitForChild("UpdateStats")

local SoundEffectHandler = require(script.Parent.SoundEffectHandler)
local clientUtils = require(ReplicatedStorage.Shared.clientUitls)

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")

local InfoBar = ScreenGUI:WaitForChild("InfoBar"):WaitForChild("ParentFrame")
local infoText = InfoBar:WaitForChild("Frame"):FindFirstChildOfClass("TextLabel")
local rainbowText = InfoBar:FindFirstChildOfClass("TextLabel")
local gradient = rainbowText:FindFirstChildOfClass("UIGradient")

local GameEndFrames = ScreenGUI:WaitForChild("GameEndFrames")
local LoseFrame: Frame = GameEndFrames:WaitForChild("LoseFrame")
local WinFrame = GameEndFrames:WaitForChild("WinFrame") :: Frame
local MoneyText: TextLabel = WinFrame:WaitForChild("TextParent"):WaitForChild("MoneyLabel")

local ObbyWinFrame: Frame = ScreenGUI:WaitForChild("ObbyWinFrame")
local baseObbyWinFrameSize = ObbyWinFrame.Size
local baseObbyWinFrameEndPos = ObbyWinFrame.Position
local TWEEN_LENGTH = 0.5
local FADEOUT_LENGTH = 2

local textParent = ObbyWinFrame:WaitForChild("WinFrame"):WaitForChild("TextParent")
local _: TextLabel = textParent:WaitForChild("WinText")
local moneyText: TextLabel = textParent:WaitForChild("MoneyLabel")
local earnedText: TextLabel = textParent:WaitForChild("EarnedLabel")
local TYPE_WRITER_EARNED = 0.1
local TYPE_WRITER_MONEY = 0.175

local playTimeRewardsFrame = ScreenGUI:WaitForChild("PlayTimeRewards") :: Frame
local ELASTIC_DUR = 0.4
local FADEOUT_TIME = 4
local recievedText: TextLabel = playTimeRewardsFrame:WaitForChild("RecievedText")
local whyText: TextLabel = playTimeRewardsFrame:WaitForChild("WhyText")

-- Top bar GUI
TopBarUpdate.OnClientEvent:Connect(function(text: string, mode: "Ongoing" | "Intermission")
	infoText.Text = mode == "Ongoing" and text .. " is now ready to fill!" or "Intermission: " .. text
end)

-- End game screens
EndGameScreen.OnClientInvoke = function(didWin: boolean, money: number?): number
	local soundLength, frame: Frame
	if didWin then
		if money then
			MoneyText.Text = "+$" .. money
		end
		SoundEffectHandler.Play("WinRound")
		WinFrame.Visible = true
		frame = WinFrame
		soundLength = SoundEffectHandler.GetSound("WinRound").TimeLength
	else
		SoundEffectHandler.Play("LoseRound")
		LoseFrame.Visible = true
		frame = LoseFrame
		soundLength = SoundEffectHandler.GetSound("LoseRound").TimeLength
	end

	task.delay(soundLength, function()
		frame.Visible = false
	end)

	return soundLength
end

-- Game cancelled event
GameCancelledEvent.OnClientEvent:Connect(function(msg: string)
	clientUtils.showWarning(msg)
end)

-- Teleport player event
RespawnToObbyEvent.OnClientEvent:Connect(function(pos: Vector3)
	if pos then
		local character = Player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local hrp = character.HumanoidRootPart

			local rotation = CFrame.Angles(0, math.rad(-90), 0)
			hrp.CFrame = CFrame.new(pos) * rotation
		end
	end
end)

-- Obby win event
WinObbyEvent.OnClientEvent:Connect(function(money: number)
	SoundEffectHandler.Play("WinObby")
	local fadeFunc = clientUtils.PopFrame(
		ObbyWinFrame,
		baseObbyWinFrameEndPos + UDim2.new(0, 0, 0.75, 0),
		baseObbyWinFrameSize,
		baseObbyWinFrameEndPos,
		TWEEN_LENGTH,
		FADEOUT_LENGTH,
		function()
			moneyText.Visible = false
			earnedText.Visible = false
		end
	)
	task.wait(TWEEN_LENGTH * 2)
	task.spawn(function()
		SoundEffectHandler.Play("TypeWriter")
		clientUtils.TypewriterLabel(earnedText, "You Earned:", TYPE_WRITER_EARNED, function()
			clientUtils.TypewriterLabel(moneyText, "+$" .. tostring(money), TYPE_WRITER_MONEY, function()
				SoundEffectHandler.Stop("TypeWriter")
				SoundEffectHandler.Play("Kaching")
				task.delay(2, function()
					UpdateStatsEvent:FireServer(money)
					fadeFunc()
				end)
			end)
		end)
	end)
end)

-- Playtime reward event
PlayTimeRewardEvent.OnClientEvent:Connect(function(actionId: string)
	print("rewarding", actionId)
	local fadeout =
		clientUtils.PopFrameElastic(playTimeRewardsFrame, playTimeRewardsFrame.Size, ELASTIC_DUR, FADEOUT_TIME)
	task.delay(2, function()
		fadeout()
	end)
end)

task.spawn(function()
	clientUtils.RainbowIfyText(gradient)
end)
