local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ClientUtils = {}

function ClientUtils.showWarning(message)
	-- create a ScreenGui if it doesn't exist
	local warningGui = PlayerGui:FindFirstChild("WarningGui")
	if not warningGui then
		warningGui = Instance.new("ScreenGui")
		warningGui.Name = "WarningGui"
		warningGui.ResetOnSpawn = false
		warningGui.IgnoreGuiInset = true
		warningGui.Parent = PlayerGui
	end

	-- create a frame for the warning
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0.2, 0) -- 50% width, 20% height
	frame.Position = UDim2.new(0.25, 0, 0.4, 0) -- center
	frame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	frame.BackgroundTransparency = 0.1
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Parent = warningGui

	-- round corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- text label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = message or "⚠️ Game Cancelled!"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Parent = frame

	-- optional: fade out after a few seconds
	task.delay(3, function()
		for i = 0, 1, 0.05 do
			frame.BackgroundTransparency = i
			label.TextTransparency = i
			task.wait(0.05)
		end
		frame:Destroy()
	end)
end

return ClientUtils
