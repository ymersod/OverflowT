local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local TopBarUpdate = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("TopBarUpdate")
local uiConstants = require(ReplicatedStorage.Shared.uiConstants)

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local InfoBar = ScreenGUI:WaitForChild("InfoBar")
local infoText = InfoBar:FindFirstChild("Frame"):FindFirstChildOfClass("TextLabel")
local rainbowText = InfoBar:FindFirstChildOfClass("TextLabel")
local gradient = rainbowText:FindFirstChildOfClass("UIGradient")

TopBarUpdate.OnClientEvent:Connect(function(text: string, mode: "Ongoing" | "Intermission")
	infoText.Text = mode == "Ongoing" and text .. " is now ready to fill!" or "Intermission: " .. text
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
