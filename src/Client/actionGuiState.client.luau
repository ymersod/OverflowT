local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local actionMenu = ScreenGUI:WaitForChild("ActionMenu")
local flushFrame: Frame = actionMenu:WaitForChild("Flush")
local shadePrefab: Frame = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("Shade")

function firstState()
	flushFrame.Visible = true
end

function otherState()
	flushFrame.Visible = false
end

function updateGUI(linePositionValue: number)
	if linePositionValue == 1 then
		firstState()
	else
		otherState()
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
