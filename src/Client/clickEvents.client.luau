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
local resetFlushEvent = gameEvents:WaitForChild("ResetToilet")
local overflowToiletEvent = gameEvents:WaitForChild("OverflowToilet")
local freezeToiletEvent = gameEvents:WaitForChild("FreezeToilet")
local jamFlushEvent = gameEvents:WaitForChild("Jamflush")

local actionEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ActionsEvents")
local tryUseActions = actionEvents:WaitForChild("TryUseAction")

-- UI
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")

local actionMenu = ScreenGUI:WaitForChild("ActionMenu")
local contextActionMenu1: Frame = actionMenu:WaitForChild("ActionMenu1")
local contextActionMenu2: Frame = actionMenu:WaitForChild("ActionMenu2")

-- Button refs
local flushButton = actionMenu:WaitForChild("Flush"):FindFirstChildOfClass("TextButton")
local moreLessButton = actionMenu:WaitForChild("MoreLess"):FindFirstChildOfClass("TextButton")
local cutButton = contextActionMenu1:WaitForChild("Cut"):FindFirstChildOfClass("TextButton")
local cutAllButton = contextActionMenu1:WaitForChild("CutAll"):FindFirstChildOfClass("TextButton")
local skipFlushButton = contextActionMenu1:WaitForChild("SkipFill"):FindFirstChildOfClass("TextButton")
local resetToiletButton = contextActionMenu1:WaitForChild("ResetToilet"):FindFirstChildOfClass("TextButton")

local overflowButton = contextActionMenu2:WaitForChild("Overflow"):FindFirstChildOfClass("TextButton")
local freezeToiletButton = contextActionMenu2:WaitForChild("FreezeWater"):FindFirstChildOfClass("TextButton")
local jamFlushButton = contextActionMenu2:WaitForChild("JamFlush"):FindFirstChildOfClass("TextButton")

local DEBOUNCE_TIME = 0.5
local debounces = {}

local function debounceCheck(button)
	if debounces[button] then
		return false
	end

	debounces[button] = true
	task.delay(DEBOUNCE_TIME, function()
		debounces[button] = false
	end)
	return true
end

-- Flush button
local flushStarted = false
flushButton.MouseButton1Down:Connect(function()
	if debounceCheck(flushButton) then
		flushStarted = true

		local leaveConn, upConn

		local function flushFinishWrapper()
			nextEvent:FireServer("Flush")

			local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")
			linePosition.Changed:Once(function(newVal)
				actionGuiState.updateGUI(newVal)
			end)

			if leaveConn then
				leaveConn:Disconnect()
				leaveConn = nil
			end
			if upConn then
				upConn:Disconnect()
				upConn = nil
			end

			flushStarted = false
		end
		leaveConn = flushButton.MouseLeave:Connect(flushFinishWrapper)
		upConn = flushButton.MouseButton1Up:Connect(flushFinishWrapper)
		startFlushEvent:FireServer()
	end
end)

-- More less button
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

-- Reset toilet
resetToiletButton.MouseButton1Down:Connect(function()
	if debounceCheck(resetToiletButton) then
		if useAction(resetToiletButton) then
			resetFlushEvent:FireServer()
		else
			warn("Not enough charges!!")
		end
	end
end)

-- Overflow
overflowButton.MouseButton1Down:Connect(function()
	if debounceCheck(overflowButton) then
		if useAction(overflowButton) then
			overflowToiletEvent:FireServer()
		else
			warn("Not enough charges!!")
		end
	end
end)

-- Freeze
freezeToiletButton.MouseButton1Down:Connect(function()
	if debounceCheck(freezeToiletButton) then
		if useAction(freezeToiletButton) then
			freezeToiletEvent:FireServer()
		else
			warn("Not enough charges!!")
		end
	end
end)

-- Jam flush
jamFlushButton.MouseButton1Down:Connect(function()
	if debounceCheck(jamFlushButton) then
		if useAction(jamFlushButton) then
			jamFlushEvent:FireServer()
		else
			warn("Not enough charges!!")
		end
	end
end)

-- Cut button
cutButton.MouseButton1Down:Connect(function()
	if not flushStarted and debounceCheck(cutButton) then
		if useAction(cutButton) then
			skipAheadEvent:FireServer()
		else
			warn("Not enough charges!!")
		end
	end
end)

-- Cut all button
cutAllButton.MouseButton1Down:Connect(function()
	if not flushStarted and debounceCheck(cutAllButton) then
		if useAction(cutAllButton) then
			cutAllEvent:FireServer()
		else
			warn("Not enough charges!!")
		end
	end
end)

-- Skip flush button
skipFlushButton.MouseButton1Down:Connect(function()
	if not flushStarted and debounceCheck(skipFlushButton) then
		if useAction(skipFlushButton) then
			nextEvent:FireServer("SkipAhead")
		else
			warn("Not enough charges!!")
		end
	end
end)
