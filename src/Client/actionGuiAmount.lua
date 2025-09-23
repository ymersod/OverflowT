local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local types = require(ReplicatedStorage.Shared.types)

local actionEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ActionsEvents")
local getActions = actionEvents:WaitForChild("GetOwnedActions")
local tryUseActions = actionEvents:WaitForChild("TryUseAction")
local addChargeToAction = actionEvents:WaitForChild("AddChargeToAction")
local updatedActionsFromServer = actionEvents:WaitForChild("UpdateActionsFromServer")

local actionGuiAmount = {}

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local actionMenu = ScreenGUI:WaitForChild("ActionMenu") :: Frame

local contextActionMenu1
local contextActionMenu2

local function updateContextActionMenu(contextActionMenu: Instance, actions: { [string]: types.Action })
	for _, actionFrame in ipairs(contextActionMenu:GetChildren()) do
		local actionFrameId: number? = actionFrame:GetAttribute("ActionId")
		local text = actionFrame:GetAttribute("Text")
		if actionFrame:IsA("Frame") and actionFrameId and text then
			local persistedAction = actions[tostring(actionFrameId)]
			local textLabel = actionFrame:FindFirstChildOfClass("TextButton"):FindFirstChildOfClass("TextLabel")
			if textLabel and persistedAction then
				local owned = tonumber(persistedAction.OwnedAmount)
				textLabel.Text = owned > 0 and text .. " (" .. owned .. ")" or text
			end
		end
	end
end

function actionGuiAmount.updateGui(actions)
	updateContextActionMenu(contextActionMenu1, actions)
	updateContextActionMenu(contextActionMenu2, actions)
end

function actionGuiAmount.setup()
	contextActionMenu1 = actionMenu:WaitForChild("ActionMenu1")
	contextActionMenu2 = actionMenu:WaitForChild("ActionMenu2")

	actionGuiAmount.updateGui(getActions:InvokeServer())
end

updatedActionsFromServer.OnClientInvoke = function(actions)
	print("Actions update! ")
	print(actions)
	actionGuiAmount.updateGui(actions)
end

return actionGuiAmount
