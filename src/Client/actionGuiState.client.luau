local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local actionMenu = ScreenGUI:WaitForChild("ActionMenu")
local flushFrame: Frame = actionMenu:WaitForChild("Flush")

function updateGUI(linePositionValue: number)
	if linePositionValue == 1 then
		flushFrame.Visible = true
	else
		flushFrame.Visible = false
	end
end

function startListen()
	local newVal = linePosition.Value
	updateGUI(newVal)

	linePosition.Changed:Connect(function()
		newVal = linePosition.Value
		updateGUI(newVal)
	end)
end
startListen()
