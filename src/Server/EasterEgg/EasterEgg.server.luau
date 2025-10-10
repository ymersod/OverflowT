local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local shopHandler = require(ServerScriptService.Server.shopHandler)
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local tags = require(ReplicatedStorage.Shared.tags)

local processPurchaseEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("MonetizationEvents")
	:WaitForChild("ProcessPurchase")

local Lever = CollectionService:GetTagged(tags.EASTER_EGG_LEVER)[1]
local Chest = CollectionService:GetTagged(tags.EASTER_EGG_CHEST)[1]
local chestPart = Chest:FindFirstChild("Part") :: Part
local chestPartChildren = chestPart:GetDescendants()
local chestProx = chestPart:FindFirstChildOfClass("ProximityPrompt")
local Stick = Lever:FindFirstChild("Stick") :: Part
local prox = Stick:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt

local OriginalCFrame = Stick.CFrame
local Offset = CFrame.new(-1.74798584, -1.748016357, 0, 0, -0.999999881, 0, 0.999999881, 0, 0, 0, 0, 1)

chestProx.Triggered:Connect(function(player)
	shopHandler.BuyItem(player, -100, "Model")
	processPurchaseEvent:FireClient(player, -100, "Model")
end)

local function OpenChest()
	for _, desc in ipairs(chestPartChildren) do
		if desc:IsA("Decal") then
			desc.Transparency = desc.Transparency == 0 and 0.7 or 0
		elseif desc:IsA("ProximityPrompt") or desc:IsA("ParticleEmitter") then
			desc.Enabled = not desc.Enabled
		end
	end
end

local function Switch()
	local ValueAtt = Lever:GetAttribute("Value")

	if ValueAtt == true then
		Lever:SetAttribute("Value", false)
		Stick.CFrame = Stick.CFrame:ToWorldSpace(Offset)
		OpenChest()
	else
		Lever:SetAttribute("Value", true)
		Stick.CFrame = OriginalCFrame
		OpenChest()
	end
end

local cap = 40
local canSwitch = true
prox.Triggered:Connect(function()
	if canSwitch then
		canSwitch = false
		local lever = SoundEffectHandler.GetSound("Lever")
		lever:Play()
		lever.Ended:Once(function()
			Switch()
			SoundEffectHandler.Play("WoodGroan")
		end)

		task.delay(cap, function()
			Switch()
			canSwitch = true
			SoundEffectHandler.Play("Lever")
		end)
	end
end)
