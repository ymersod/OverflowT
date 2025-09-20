local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local nextEvent =
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("LineEvents"):WaitForChild("Next")

-- UI
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")

local actionMenu = ScreenGUI:WaitForChild("ActionMenu")
local flushFrame = actionMenu:WaitForChild("Flush")
local flushButton = flushFrame:FindFirstChildOfClass("TextButton")

flushButton.MouseButton1Down:Connect(function()
	print("Start flushing")
end)

flushButton.MouseButton1Up:Connect(function()
	print("Stop flushing")
	nextEvent:InvokeServer()
end)
