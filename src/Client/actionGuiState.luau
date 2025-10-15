local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local tags = require(ReplicatedStorage.Shared.tags)

local actionGuiState = {}

-- UI Elements
local shadePrefab: Frame = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("Shade")
local actionFolder: Folder = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("Actions")

local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local actionMenu = ScreenGUI:WaitForChild("ActionMenu") :: Frame
local flushFrame: Frame = actionMenu:WaitForChild("Flush")

local contextActionMenu1 = actionMenu:WaitForChild("ActionMenu1")
local contextActionMenu2 = actionMenu:WaitForChild("ActionMenu2")

local function SetupContextActionMenus(contextActionMenu: Instance)
	local actionIds = contextActionMenu:GetAttribute("ActionIds")
	local idArr: { string } = actionIds and string.split(actionIds, ",") or {}

	for _, id in ipairs(idArr) do
		for _, action in ipairs(actionFolder:GetChildren()) do
			local actionId = action:GetAttribute("ActionId")
			if tostring(actionId) == tostring(id) then
				local actionClone = action:Clone()
				actionClone.Parent = contextActionMenu
			end
		end
	end
end
SetupContextActionMenus(contextActionMenu1)
SetupContextActionMenus(contextActionMenu2)

local function shade(frames: { Frame }, modification: "Add" | "Remove")
	if modification == "Add" then
		for _, frame in ipairs(frames) do
			-- Check if a shade already exists
			if not frame:FindFirstChild("ShadeClone") then
				local shadeClone = shadePrefab:Clone()
				shadeClone.Name = "ShadeClone"
				shadeClone.Parent = frame

				local actionButton = frame:FindFirstChildOfClass("TextButton")
				if actionButton then
					actionButton.Interactable = false
				end
			end
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
	flushFrame.Visible = false

	local notFirstActions = findActions(tags.NOT_FIRST_TAG)
	local onlyFirstActions = findActions(tags.ONLY_FIRST_TAG)

	shade(notFirstActions, "Remove")
	shade(onlyFirstActions, "Add")
end

function notInLineState()
	flushFrame.Visible = false

	local notFirstActions = findActions(tags.NOT_FIRST_TAG)
	local onlyFirstActions = findActions(tags.ONLY_FIRST_TAG)
	shade(notFirstActions, "Remove")
	shade(onlyFirstActions, "Remove")
end

function actionGuiState.updateGUI(linePositionValue: number)
	if linePositionValue == 1 then
		firstInLineState()
	elseif linePositionValue > 1 then
		inLineState()
	elseif linePositionValue == 0 then
		notInLineState()
	end
end

task.spawn(function() --TODO: I DO NOT LIKE THIS :>>>>>>>>>>
	local States = Player:WaitForChild("States")
	local linePositionValue: IntValue = States:WaitForChild("LinePosition")

	while true do
		if linePositionValue.Value == 0 then
			notInLineState()
		end

		task.wait(1)
	end
end)

return actionGuiState
