local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local tags = require(ReplicatedStorage.Shared.tags)

local mainToilet = CollectionService:GetTagged(tags.GOLDEN_TOILET)[1]

local mainParts = CollectionService:GetTagged(tags.GOLDEN_PART)
local brokenParts = CollectionService:GetTagged(tags.BROKEN_PART)
local brokenParticles = CollectionService:GetTagged(tags.BROKEN_PARTICLE)

local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local WoodCrackSound = SoundEffectHandler.GetSound("WoodCrackLooped")
WoodCrackSound.Looped = true

local frozenToiletParts = CollectionService:GetTagged(tags.FROZEN_TOILET_PARTS)
local frozenParticles = CollectionService:GetTagged(tags.FROZEN_PARTICLE)

local standardPosition = mainToilet.PrimaryPart and mainToilet.PrimaryPart.Position
	or mainToilet:GetModelCFrame().Position

local ToiletSwitcher = {
	ActiveToilet = mainParts,
}

local standardToilet = Instance.new("BoolValue")
standardToilet.Name = "StandardToilet"
standardToilet.Value = true

local function enableBrokenToiletParticles(enabled: boolean)
	for _, descendant in ipairs(brokenParticles) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = enabled
		end
	end
end

local function setPartsTransparency(parts, transparency)
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			part.Transparency = transparency
		end
	end
end

function ToiletSwitcher.SwitchToilet(toStandard: boolean)
	standardToilet.Value = toStandard
	if toStandard then
		setPartsTransparency(mainParts, 0) -- show main
		setPartsTransparency(brokenParts, 1) -- hide broken
		enableBrokenToiletParticles(false)
		ToiletSwitcher.ActiveToilet = mainParts
	else
		setPartsTransparency(mainParts, 1) -- hide main
		setPartsTransparency(brokenParts, 0) -- show broken
		enableBrokenToiletParticles(true)
		-- Visual explosion above original toilet
		local explosion = Instance.new("Explosion")
		explosion.Position = standardPosition + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 10
		explosion.BlastPressure = 0
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = Workspace
		ToiletSwitcher.ActiveToilet = brokenParts
	end
end

local function enableFrozen()
	for _, part in ipairs(frozenToiletParts) do
		part.Transparency = 0
	end
	for _, emitter in ipairs(frozenParticles) do
		emitter.Enabled = true
	end
end

local function disableFrozen()
	print("yoyoyo")
	WoodCrackSound:Stop()
	ToiletSwitcher.ActiveToilet = mainParts
	for _, part in ipairs(frozenToiletParts) do
		part.Transparency = 1
	end
	for _, emitter in ipairs(frozenParticles) do
		emitter.Enabled = false
	end
end

function ToiletSwitcher.SwitchToFrozen(switchToFrozen)
	if not standardToilet.Value then
		disableFrozen()
		return
	end
	if switchToFrozen then
		SoundEffectHandler.Play("FreezeIce")
		WoodCrackSound:Play()
		enableFrozen()
		setPartsTransparency(mainParts, 1)
		ToiletSwitcher.ActiveToilet = frozenToiletParts
	else
		setPartsTransparency(mainParts, 0)
		disableFrozen()
	end
end

standardToilet.Changed:Connect(function()
	disableFrozen()
end)

return ToiletSwitcher
