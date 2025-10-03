local Player = game:GetService("Players").LocalPlayer

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local actionMenu = ScreenGUI:WaitForChild("ActionMenu") :: Frame

local function UpdateAction(actionId: string, amount: number)
	for _, actionFrame in ipairs(actionMenu:GetDescendants()) do
		local actionFrameId: number? = actionFrame:GetAttribute("ActionId")
		local text = actionFrame:GetAttribute("Text")
		if actionFrame:IsA("Frame") and text and actionFrameId and tostring(actionFrameId) == actionId then
			local textLabel = actionFrame:FindFirstChildOfClass("TextButton"):FindFirstChildOfClass("TextLabel")

			textLabel.Text = amount > 0 and text .. " (" .. amount .. ")" or text
		end
	end
end

function setup()
	local localstats = Player:WaitForChild("localstats")
	local localstatsactions = localstats and localstats:WaitForChild("localstatsactions")

	if localstatsactions then
		for _, action in ipairs(localstatsactions:GetChildren()) do
			if action:IsA("IntValue") then
				action.Changed:Connect(function(val)
					UpdateAction(action.Name, val)
				end)
				UpdateAction(action.Name, action.Value)
			end
		end
	else
		warn("LOCALSTATS ACTIONS NOT FOUND YIKERS")
	end
end
setup()
