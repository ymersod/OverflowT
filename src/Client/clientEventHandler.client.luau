local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ClientEvents")
local TopBarUpdate = clientEvents:WaitForChild("TopBarUpdate")
local EndGameScreen = clientEvents:WaitForChild("EndGameScreen")
local GameCancelledEvent = clientEvents:WaitForChild("GameCancelled")
local RespawnToObbyEvent = clientEvents:WaitForChild("RespawnToObby")
local WinObbyEvent = clientEvents:WaitForChild("ObbyWin")
local PlayTimeRewardEvent = clientEvents:WaitForChild("PlaytimeReward")
local afkWarningEvent = clientEvents:WaitForChild("AfkWarning")
local UpdateStatsEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("StatsEvents")
	:WaitForChild("UpdateStats")

local SoundEffectHandler = require(script.Parent.SoundEffectHandler)
local clientUtils = require(ReplicatedStorage.Shared.clientUitls)

-- UI Elements
local actionsRefs = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("Actions")

local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")

local afkWarning = ScreenGUI:WaitForChild("KickedFrame") :: Frame
local timeLabel: TextLabel = afkWarning:WaitForChild("TextParent"):WaitForChild("Time")

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

local playTimeRewardsFrame = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("PlayTimeRewards")
local ELASTIC_DUR = 0.4
local FADEOUT_TIME = 4
local whyTextArr = {
	"Here’s a little something for you!",
	"Appreciate you playing!",
	"You deserve this!",
	"Enjoy your reward!",
	"Thanks for spending time with us!",
	"A little gift for you!",
	"Here you go!",
	"Keep enjoying yourself!",
}

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
	local playTimeRewardsFrameClone = playTimeRewardsFrame:Clone() :: Frame
	local recievedText: TextLabel = playTimeRewardsFrameClone:WaitForChild("RecievedText")
	local whyText: TextLabel = playTimeRewardsFrameClone:WaitForChild("WhyText")
	playTimeRewardsFrameClone.Parent = ScreenGUI
	playTimeRewardsFrameClone.ZIndex = os.time()

	local color = Color3.fromRGB(255, 255, 255)
	local text = "???"
	for _, action in ipairs(actionsRefs:GetChildren()) do
		local actionRefId = action:GetAttribute("ActionId")
		if actionRefId and tonumber(actionRefId) == tonumber(actionId) then
			local textButton = action:FindFirstChildOfClass("TextButton")
			local textLabel = textButton and textButton:FindFirstChildOfClass("TextLabel")

			if textButton and textLabel then
				color = textButton.BackgroundColor3
				text = textLabel.Text
				break
			end
		end
	end

	local function colorToHex(c)
		local r = math.floor(c.R * 255 + 0.5)
		local g = math.floor(c.G * 255 + 0.5)
		local b = math.floor(c.B * 255 + 0.5)
		return string.format("#%02X%02X%02X", r, g, b)
	end

	local function escapeRichText(s)
		if not s then
			return ""
		end
		return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	end
	local function fitTextToLabel(label)
		local maxWidth = label.AbsoluteSize.X
		local maxHeight = label.AbsoluteSize.Y

		local size = label.TextSize

		while (label.TextBounds.X > maxWidth or label.TextBounds.Y > maxHeight) and size > 8 do
			size -= 1
			label.TextSize = size
		end
	end
	local hex = colorToHex(color)

	recievedText.Text = "You got 1x [" .. '<font color="' .. hex .. '">' .. escapeRichText(text) .. "</font>" .. "]"
	whyText.Text = whyTextArr[math.random(1, #whyTextArr)]
	fitTextToLabel(recievedText)
	fitTextToLabel(whyText)
	local fadeout = clientUtils.PopFrameElastic(
		playTimeRewardsFrameClone,
		playTimeRewardsFrameClone.Size,
		ELASTIC_DUR,
		FADEOUT_TIME,
		true
	)
	SoundEffectHandler.Play("PopUp")
	task.delay(3, function()
		fadeout()
	end)
end)

-- afk warning
afkWarningEvent.OnClientEvent:Connect(function(setWarning: boolean, timeUntilKick: number?)
	if timeUntilKick then
		timeLabel.Text = tostring(timeUntilKick)
	end
	afkWarning.Visible = setWarning
end)

task.spawn(function()
	clientUtils.RainbowIfyText(gradient)
end)
