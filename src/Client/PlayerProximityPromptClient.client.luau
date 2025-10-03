local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local trollEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("GameEvents")
	:WaitForChild("TrollEvent")
local player = Players.LocalPlayer

local function setupPrompt(playerSetup: Player, prox: ProximityPrompt)
	if not prox or not prox:IsA("ProximityPrompt") then
		return
	end

	if playerSetup.UserId == player.UserId then
		task.spawn(function()
			RunService.Heartbeat:Connect(function()
				prox.Enabled = false
			end)
		end)
	else
		if not prox:GetAttribute("Connected") then
			prox:SetAttribute("Connected", true)
			prox.Triggered:Connect(function()
				local char = prox.Parent
				local playerFound = char and Players:GetPlayerFromCharacter(char)
				if playerFound then
					trollEvent:FireServer(playerFound)
				else
					warn("Couldnt find player :/")
				end
			end)
		end
	end
end

trollEvent.OnClientEvent:Connect(setupPrompt)

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		for _, obj in ipairs(plr.Character:GetChildren()) do
			if obj:IsA("ProximityPrompt") then
				setupPrompt(plr, obj)
			end
		end
	end
end
