local Player = game:GetService("Players").LocalPlayer

-- UI Elements
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local parent = ScreenGUI:WaitForChild("LikeAndJoin")
local likeAndJoinFrame: Frame = parent:WaitForChild("Like")
local PremiumFrame: Frame = parent:WaitForChild("Premium")

local CD = 30
task.spawn(function()
	while true do
		likeAndJoinFrame.Visible = not likeAndJoinFrame.Visible
		PremiumFrame.Visible = not PremiumFrame.Visible
		task.wait(CD)
	end
end)
