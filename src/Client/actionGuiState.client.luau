local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tags = require(ReplicatedStorage.Shared.tags)

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")

-- UI Elements
local shadePrefab: Frame = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("Shade")

local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local actionMenu = ScreenGUI:WaitForChild("ActionMenu") :: Frame
local flushFrame: Frame = actionMenu:WaitForChild("Flush")

local contextActionMenu1 = actionMenu:WaitForChild("ActionMenu1")
local contextActionMenu2 = actionMenu:WaitForChild("ActionMenu2")

local function shade(frames: { Frame }, modification: "Add" | "Remove")
	if modification == "Add" then
		for _, frame in ipairs(frames) do
			local shadeClone = shadePrefab:Clone()
			shadeClone.Name = "ShadeClone"
			shadeClone.Parent = frame

			local actionButton = frame:FindFirstChildOfClass("TextButton")
			actionButton.Interactable = false
		end
	elseif modification == "Remove" then
		for _, frame in ipairs(frames) do
			local shadeClones = frame:GetChildren()

			for _, shadeClonk in ipairs(shadeClones) do
				if shadeClonk:IsA("Frame") and shadeClonk.Name == "ShadeClone" then
					shadeClonk:Destroy()
				end
			end

			local actionButton = frame:FindFirstChildOfClass("TextButton")
			actionButton.Interactable = true
		end
	end
end

local function findActions(tag: string): { Frame }
	local actionsFound: { Frame } = {}

	for _, action in ipairs(contextActionMenu1:GetChildren()) do
		if action:IsA("Frame") and action:HasTag(tag) then
			table.insert(actionsFound, action)
		end
	end

	for _, action in ipairs(contextActionMenu2:GetChildren()) do
		if action:IsA("Frame") and action:HasTag(tag) then
			table.insert(actionsFound, action)
		end
	end

	return actionsFound
end

function firstInLineState()
	actionMenu.Visible = true

	flushFrame.Visible = true

	local notFirstActions = findActions(tags.NOT_FIRST_TAG)
	local onlyFirstActions = findActions(tags.ONLY_FIRST_TAG)

	shade(notFirstActions, "Add")
	shade(onlyFirstActions, "Remove")
end

function inLineState()
	actionMenu.Visible = true

	flushFrame.Visible = false

	local notFirstActions = findActions(tags.NOT_FIRST_TAG)
	local onlyFirstActions = findActions(tags.ONLY_FIRST_TAG)

	shade(notFirstActions, "Remove")
	shade(onlyFirstActions, "Add")
end

function notInLineState()
	actionMenu.Visible = false
end

function updateGUI(linePositionValue: number)
	if linePositionValue == 1 then
		firstInLineState()
	elseif linePositionValue > 1 then
		inLineState()
	elseif linePositionValue == 0 then
		notInLineState()
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
