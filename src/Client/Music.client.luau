local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientUitls = require(ReplicatedStorage.Shared.clientUitls)
local BackGroundMusic = require(script.Parent.BackGroundMusic)
local Player = game:GetService("Players").LocalPlayer

-- UI
local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local StopMusic = ScreenGUI:WaitForChild("StopMusic")
local off: ImageLabel = StopMusic:WaitForChild("Off")
local on: ImageLabel = StopMusic:WaitForChild("On")
local button = StopMusic:FindFirstChildOfClass("ImageButton")

button.MouseButton1Down:Connect(function()
	clientUitls.PulseFrame(
		StopMusic,
		clientUitls.standardPulse.scale,
		clientUitls.standardPulse.durUp,
		clientUitls.standardPulse.waitDur,
		clientUitls.standardPulse.durDown
	)

	on.Visible = not on.Visible
	off.Visible = not off.Visible

	if on.Visible then
		BackGroundMusic.musicEnabled = true
	else
		BackGroundMusic.musicEnabled = false
	end
end)
