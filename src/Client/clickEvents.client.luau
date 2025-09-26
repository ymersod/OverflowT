local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local actionGuiState = require(script.Parent.actionGuiState)

local events = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events")
local lineEvents = events:WaitForChild("LineEvents")
local gameEvents = events:WaitForChild("GameEvents")

local nextEvent = lineEvents:WaitForChild("Next")
local cutAllEvent = lineEvents:WaitForChild("CutAll")
local skipAheadEvent = lineEvents:WaitForChild("SkipAhead")
local startFlushEvent = gameEvents:WaitForChild("StartFlush")

local actionEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ActionsEvents")
local tryUseActions = actionEvents:WaitForChild("TryUseAction")

-- UI
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")

local actionMenu = ScreenGUI:WaitForChild("ActionMenu")
local contextActionMenu1: Frame = actionMenu:WaitForChild("ActionMenu1")
local contextActionMenu2: Frame = actionMenu:WaitForChild("ActionMenu2")

-- Flush button
local flushButton = actionMenu:WaitForChild("Flush"):FindFirstChildOfClass("TextButton")

flushButton.MouseButton1Down:Connect(function()
	startFlushEvent:FireServer()
end)
flushButton.MouseButton1Up:Connect(function()
	nextEvent:FireServer()

	local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")
	linePosition.Changed:Once(function(newVal)
		actionGuiState.updateGUI(newVal)
	end)
end)

-- More less button
local moreLessButton = actionMenu:WaitForChild("MoreLess"):FindFirstChildOfClass("TextButton")
local moreLessText = moreLessButton:FindFirstChildOfClass("TextLabel")
moreLessButton.MouseButton1Down:Connect(function()
	local isMenu1Visible = contextActionMenu1.Visible
	contextActionMenu1.Visible = not isMenu1Visible
	contextActionMenu2.Visible = isMenu1Visible

	if contextActionMenu1.Visible then
		moreLessText.Text = "More"
	else
		moreLessText.Text = "Less"
	end
end)

local function useAction(buttonRef: TextButton)
	local parentFrame = buttonRef.Parent
	local actionId = parentFrame and parentFrame:GetAttribute("ActionId")
	local canUse = tryUseActions:InvokeServer(tostring(actionId))
	return canUse
end

-- Cut button
local cutButton = contextActionMenu1:WaitForChild("Cut"):FindFirstChildOfClass("TextButton")
cutButton.MouseButton1Down:Connect(function()
	if useAction(cutButton) then
		skipAheadEvent:FireServer()
	else
		warn("Not enough charges!!")
	end
end)

-- Cut all button
local cutAllButton = contextActionMenu1:WaitForChild("CutAll"):FindFirstChildOfClass("TextButton")
cutAllButton.MouseButton1Down:Connect(function()
	if useAction(cutAllButton) then
		cutAllEvent:FireServer()
	else
		warn("Not enough charges!!")
	end
end)

-- Skip flush button
local skipFlushButton = contextActionMenu1:WaitForChild("SkipFill"):FindFirstChildOfClass("TextButton")
skipFlushButton.MouseButton1Down:Connect(function()
	if useAction(skipFlushButton) then
		nextEvent:FireServer()
	else
		warn("Not enough charges!!")
	end
end)
