local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local TopBarUpdate = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("TopBarUpdate")
local EndGameScreen = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("EndGameScreen")
local uiConstants = require(ReplicatedStorage.Shared.uiConstants)

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")

local InfoBar = ScreenGUI:WaitForChild("InfoBar")
local infoText = InfoBar:WaitForChild("Frame"):FindFirstChildOfClass("TextLabel")
local rainbowText = InfoBar:FindFirstChildOfClass("TextLabel")
local gradient = rainbowText:FindFirstChildOfClass("UIGradient")

local GameEndFrames = ScreenGUI:WaitForChild("GameEndFrames")
local LoseFrame: Frame = GameEndFrames:WaitForChild("LoseFrame")
local WinFrame = GameEndFrames:WaitForChild("WinFrame") :: Frame
local MoneyText = WinFrame:WaitForChild("TextParent"):WaitForChild("MoneyLabel")

-- Top bar GUI
TopBarUpdate.OnClientEvent:Connect(function(text: string, mode: "Ongoing" | "Intermission")
	infoText.Text = mode == "Ongoing" and text .. " is now ready to fill!" or "Intermission: " .. text
end)

-- End game screens
EndGameScreen.OnClientEvent:Connect(function(didWin: boolean, money: number?)
	local frame: Frame
	if didWin then
		if money then
			MoneyText = "+$" .. money
		end
		WinFrame.Visible = true
		frame = WinFrame
	else
		LoseFrame.Visible = true
		frame = LoseFrame
	end

	task.delay(5, function()
		frame.Visible = false
	end)
end)

task.spawn(function()
	gradient.Color = uiConstants.rainbowColorGradient
	while true do
		local tween =
			tweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) })
		tween:Play()
		task.wait(2)
		gradient.Offset = Vector2.new(1, 0)
		local tween2 =
			tweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Linear), { Offset = Vector2.new(0, 0) })
		tween2:Play()
		task.wait(2)
	end
end)
