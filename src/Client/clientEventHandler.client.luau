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
local updatePlaytimeRewards = clientEvents:WaitForChild("UpdatePlaytimeRewards")
local UpdateStatsEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("StatsEvents")
	:WaitForChild("UpdateStats")
local GiveRewardsEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("GameEvents")
	:WaitForChild("GiveReward")
local ragDollClientEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("RagdollClient")

local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local clientUtils = require(ReplicatedStorage.Shared.clientUitls)
local enums = require(ReplicatedStorage.Shared.enums)

-- UI Elements
local actionsRefs = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("Actions")

local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")

local WarningContainer = ScreenGUI:WaitForChild("WarningContainer")

local afkWarning = ScreenGUI:WaitForChild("KickedFrame") :: Frame
local timeLabel: TextLabel = afkWarning:WaitForChild("TextParent"):WaitForChild("Time")

local InfoBar = ScreenGUI:WaitForChild("InfoBar"):WaitForChild("ParentFrame")
local infoText = InfoBar:WaitForChild("Frame"):FindFirstChildOfClass("TextLabel")
local rainbowText = InfoBar:FindFirstChildOfClass("TextLabel")
local gradient = rainbowText:FindFirstChildOfClass("UIGradient")

local GameEndFrames = ScreenGUI:WaitForChild("GameEndFrames")
local LoseFrame: Frame = GameEndFrames:WaitForChild("LoseFrame")
local WinFrame = GameEndFrames:WaitForChild("WinFrame") :: Frame
local afkFrame: Frame = GameEndFrames:WaitForChild("AfkFrame")
local trolledFrame: Frame = GameEndFrames:WaitForChild("TrolledFrame")
local winText: TextLabel = WinFrame:WaitForChild("TextParent"):WaitForChild("WinLabel")
local MoneyText: TextLabel = WinFrame:WaitForChild("TextParent"):WaitForChild("MoneyLabel")

local PlayTimeRewardsFrame = ScreenGUI:WaitForChild("PlaytimeRewards")
local timer: TextLabel = PlayTimeRewardsFrame:WaitForChild("Timer")
local parentFrame = PlayTimeRewardsFrame:WaitForChild("Frame")
local clipFrame: Frame = parentFrame:WaitForChild("Clip")

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
local randomGiftArr = {
	"You recieved a gift from the devs!",
	"A gift for being a great player!",
	"Thank you for playing!",
	"The devs gave you a gift!",
}
local playTimeRewardsArr = {
	"A gift for playing 15 minutes",
}

-- Top bar GUI
TopBarUpdate.OnClientEvent:Connect(function(text: string, mode: "Ongoing" | "Intermission")
	infoText.Text = mode == "Ongoing" and text .. " is now ready to fill!" or "Intermission: " .. text
end)

-- End game screens
EndGameScreen.OnClientInvoke = function(endType: string, money: number?, wins: number?): number
	local soundLength, frame: Frame
	if endType == enums.EndGameScreen.Win then
		if money then
			MoneyText.Text = "+$" .. money
		end
		if wins then
			winText.Text = "+" .. wins .. " Wins"
		end
		SoundEffectHandler.Play("WinRound")
		WinFrame.Visible = true
		frame = WinFrame
		soundLength = SoundEffectHandler.GetSound("WinRound").TimeLength
	elseif endType == enums.EndGameScreen.Lose then
		SoundEffectHandler.Play("LoseRound")
		LoseFrame.Visible = true
		frame = LoseFrame
		soundLength = SoundEffectHandler.GetSound("LoseRound").TimeLength
	elseif endType == enums.EndGameScreen.Afk then
		SoundEffectHandler.Play("LoseRound")
		afkFrame.Visible = true
		frame = afkFrame
		soundLength = SoundEffectHandler.GetSound("LoseRound").TimeLength
	elseif endType == enums.EndGameScreen.Trolled then
		SoundEffectHandler.Play("LoseRound")
		trolledFrame.Visible = true
		frame = trolledFrame
		soundLength = SoundEffectHandler.GetSound("LoseRound").TimeLength
	else
		warn("No endtype found, frame cant be set")
		return 0
	end

	task.delay(soundLength, function()
		frame.Visible = false
	end)

	return soundLength
end

-- Game cancelled event
GameCancelledEvent.OnClientEvent:Connect(function(msg: string)
	if not WarningContainer then
		warn("Warning container not found")
		return
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	frame.BackgroundTransparency = 0.1
	frame.ZIndex = 0
	frame.Parent = WarningContainer

	-- round corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = frame

	-- text label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.9, 0, 0.9, 0) -- padding inside the frame
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.BackgroundTransparency = 1
	label.Text = msg or "⚠️ Game Cancelled!"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextWrapped = true
	label.Parent = frame
	SoundEffectHandler.Play("PopUp")

	clientUtils.fadeOut(frame, 3, true)
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
				task.delay(2, function()
					UpdateStatsEvent:FireServer(money)
					fadeFunc()
				end)
			end)
		end)
	end)
end)

-- Playtime reward event
PlayTimeRewardEvent.OnClientEvent:Connect(function(actionId: string, amount: number, type: "Random" | "Playtime")
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

	recievedText.Text = "You got "
		.. amount
		.. "x ["
		.. '<font color="'
		.. hex
		.. '">'
		.. escapeRichText(text)
		.. "</font>"
		.. "]"
	if type == "Random" then
		whyText.Text = randomGiftArr[math.random(1, #randomGiftArr)]
	else -- type == "Playtime"
		whyText.Text = playTimeRewardsArr[math.random(1, #playTimeRewardsArr)]
	end
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

local SCALE_SIZE = 1.2
local DUR = 0.6
updatePlaytimeRewards.OnClientEvent:Connect(function(totalTime: number, cap: number, rewardToEnable: number?)
	local minutes = math.floor(totalTime / 60)
	local seconds = totalTime % 60
	timer.Text = string.format("%02d:%02d", minutes, seconds)

	if cap >= totalTime then
		clipFrame.Size =
			UDim2.new(clipFrame.Size.X.Scale, clipFrame.Size.X.Scale, totalTime / cap, clipFrame.Size.Y.Offset)
	end

	if rewardToEnable then
		local rewardButton = parentFrame:WaitForChild(rewardToEnable) :: ImageButton?
		local checkMark: ImageLabel = rewardButton and rewardButton:WaitForChild("Checkmark")
		local img: ImageLabel = rewardButton and rewardButton:WaitForChild("Img")

		if rewardButton and checkMark and img then
			local ogSize = img.Size
			rewardButton.Interactable = true
			local tween = clientUtils.PulseContinuously(img, SCALE_SIZE, DUR)
			rewardButton.MouseButton1Down:Once(function()
				if tween then
					tween:Cancel()
					img.Size = ogSize
				end
				rewardButton.Interactable = false
				checkMark.Visible = true
				SoundEffectHandler.Play("PlaytimeCashin")
				GiveRewardsEvent:FireServer(rewardToEnable)
			end)
		else
			warn("Didnt find the reward")
		end
	end
end)

-- afk warning
afkWarningEvent.OnClientEvent:Connect(function(setWarning: boolean, timeUntilKick: number?)
	if timeUntilKick then
		timeLabel.Text = tostring(timeUntilKick)
	end
	afkWarning.Visible = setWarning
end)

-- ragdoll client
ragDollClientEvent.OnClientEvent:Connect(function(toRagdoll: boolean)
	local player = game.Players.LocalPlayer
	local char = player and player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")

	if toRagdoll then
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	else
		if humanoid:GetState() == Enum.HumanoidStateType.Dead then
			return
		end
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end)

task.spawn(function()
	clientUtils.RainbowIfyText(gradient)
end)
