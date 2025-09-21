local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local tags = require(ReplicatedStorage.Shared.tags)

local mainToilet = CollectionService:GetTagged(tags.GOLDEN_TOILET)[1]
local destroyedToilet = CollectionService:GetTagged(tags.BROKEN_TOILET)[1]

local mainParts = CollectionService:GetTagged(tags.GOLDEN_PART)
local brokenParts = CollectionService:GetTagged(tags.BROKEN_PART)

local standardPosition = mainToilet.PrimaryPart and mainToilet.PrimaryPart.Position
	or mainToilet:GetModelCFrame().Position

local ToiletSwitcher = {}

local function setPartsTransparency(parts, transparency)
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			part.Transparency = transparency
		end
	end
end

function ToiletSwitcher.SwitchToilet(toStandard: boolean)
	if toStandard then
		setPartsTransparency(mainParts, 0) -- show main
		setPartsTransparency(brokenParts, 1) -- hide broken
	else
		setPartsTransparency(mainParts, 1) -- hide main
		setPartsTransparency(brokenParts, 0) -- show broken

		-- Visual explosion above original toilet
		local explosion = Instance.new("Explosion")
		explosion.Position = standardPosition + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 10
		explosion.BlastPressure = 0
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = Workspace
	end
end

return ToiletSwitcher
