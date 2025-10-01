local ReplicatedStorage = game:GetService("ReplicatedStorage")

local coinTemplate = ReplicatedStorage:WaitForChild("Coin")
local spawnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("StatsEvents")
	:WaitForChild("MoneyAnimation")

local function spawnCoins(player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local coin = coinTemplate:Clone()
	coin.Parent = workspace

	-- Random rotation on spawn
	local randomRotation =
		CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), math.rad(math.random(0, 360)))
	coin.CFrame = root.CFrame * randomRotation

	-- Random horizontal push
	local angle = math.random() * math.pi * 2
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	coin.AssemblyLinearVelocity = direction * 20 + Vector3.new(0, 30, 0)

	-- Counter gravity (fall slower)
	local attachment = Instance.new("Attachment")
	attachment.Parent = coin
	local force = Instance.new("VectorForce")
	force.Force = Vector3.new(0, workspace.Gravity * coin:GetMass() * 0.7, 0)
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.Parent = coin

	-- Spin
	local angularAttachment = Instance.new("Attachment")
	angularAttachment.Parent = coin
	local angular = Instance.new("AngularVelocity")
	angular.Attachment0 = angularAttachment
	angular.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	angular.AngularVelocity = Vector3.new(math.random(-20, 20), math.random(-5, 5), math.random(-20, 20))
	angular.MaxTorque = math.huge
	angular.Parent = coin

	task.delay(1, function()
		coin:Destroy()
	end)
end

-- Listen for the client event
spawnEvent.OnServerEvent:Connect(function(player)
	print("called")
	spawnCoins(player)
end)
