local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ToiletSwitcher = require(ServerScriptService.Server.Toilet.ToiletSwitcher)
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local clientUitls = require(ReplicatedStorage.Shared.clientUitls)
local Globals = require(script.Parent.Globals)
local tags = require(ReplicatedStorage.Shared.tags)
local toiletModels: { Model } = ServerStorage:WaitForChild("ShopItems"):WaitForChild("ToiletModels"):GetChildren()
local bubbleTypes: { Part } = ServerStorage:WaitForChild("ShopItems"):WaitForChild("BubbleTypes"):GetChildren()

local mainToilet = CollectionService:GetTagged(tags.GOLDEN_TOILET)[1]
local particleBase: Part = CollectionService:GetTagged(tags.TOILET_PARTICLE_BASE)[1]

local universalParticle = CollectionService:GetTagged(tags.UNIVERSAL_PARTICLES)[1]
local universalEmitter = universalParticle:FindFirstChildOfClass("ParticleEmitter")

local flushUtils = {}

flushUtils.curBubbles = bubbleTypes[1]
flushUtils.toiletLid = CollectionService:GetTagged(tags.TOILET_LID)[1] :: MeshPart
flushUtils.toiletSeat = CollectionService:GetTagged(tags.TOILET_SEAT)[1] :: MeshPart
flushUtils.toiletBody = CollectionService:GetTagged(tags.TOILET_BODY)[1] :: MeshPart

local jammedText: TextLabel = CollectionService:GetTagged(tags.JAMMED_TEXT)[1]
local jammedFrame = jammedText.Parent :: Frame

local function CleanupPreviousParticleObjects(obj: Instance)
	print("Cleaning up old particles and sounds...")

	local remaining = 0
	CollectionService:AddTag(obj, tags.CLEANUP_MARK)

	local function markDone()
		remaining -= 1
		if remaining <= 0 then
			print("Old particles and sounds cleaned up!")
			obj:Destroy()
		end
	end

	for _, child in ipairs(obj:GetChildren()) do
		-- Handle particles
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
			remaining += 1
			task.delay(child.Lifetime.Max, function()
				markDone()
			end)

		-- Handle sounds
		elseif child:IsA("Sound") then
			if child.IsPlaying then
				remaining += 1
				local timeLeft = child.TimeLength - child.TimePosition
				task.delay(timeLeft, function()
					markDone()
				end)
			end
		end
	end

	if remaining == 0 then
		print("No particles/sounds active, destroying immediately")
		obj:Destroy()
	end
end

function flushUtils.SetupPlayerBubbleType(player: Player)
	local localstats = player:FindFirstChild("localstats")
	local equippedBubbles: IntValue? = localstats and localstats:FindFirstChild("EquippedParticles")
	local selectedBubble = bubbleTypes[1]

	if equippedBubbles then
		local id = equippedBubbles.Value
		for _, bubbleItem in ipairs(bubbleTypes) do
			local itemId = bubbleItem:GetAttribute("Id")
			if itemId and itemId == id then
				selectedBubble = bubbleItem
				break
			end
		end
	else
		warn("Player didnt have an equipped item, doing basic bubbles")
	end

	-- Cleanup
	for _, child in ipairs(mainToilet:GetChildren()) do
		if child:HasTag(tags.TOILET_PARTICLE_PARENT) then
			task.spawn(function()
				if not child:HasTag(tags.CLEANUP_MARK) then
					CleanupPreviousParticleObjects(child)
				end
			end)
		end
	end

	local clone = selectedBubble:Clone()
	clone.Parent = mainToilet
	clone.CFrame = particleBase.CFrame
	clone.Size = particleBase.Size
	print("New bubbles!: ", clone)
	flushUtils.curBubbles = clone
end

local curSpecialEffects = {}
local runningEffects: { [Model]: boolean } = {}
local function SetSpecialEffects(selectedToilet: Model)
	if curSpecialEffects and #curSpecialEffects > 0 then
		for _, effect in ipairs(curSpecialEffects) do
			effect:Destroy()
		end
	end
	for model, _ in pairs(runningEffects) do
		runningEffects[model] = false
		if model then
			model:Destroy()
		end
	end
	curSpecialEffects = {}

	for _, effect in ipairs(selectedToilet:GetDescendants()) do
		if effect:IsA("ParticleEmitter") then
			local particleEmitterClone = effect:Clone()
			particleEmitterClone.Parent = flushUtils.toiletBody
			table.insert(curSpecialEffects, particleEmitterClone)
		elseif effect:IsA("Script") then
			local scriptClone = effect:Clone()
			scriptClone.Parent = mainToilet
			scriptClone.Enabled = true
			table.insert(curSpecialEffects, scriptClone)
		elseif effect:IsA("Model") then
			local modelClone = effect:Clone()
			modelClone.Parent = mainToilet
			task.spawn(function()
				runningEffects[modelClone] = true
				local hum = modelClone:FindFirstChildOfClass("Humanoid")
				local animation = modelClone:FindFirstChildOfClass("Animation")
				local animator = hum and hum:FindFirstChildOfClass("Animator")

				if hum and animation and animator then
					local track = animator:LoadAnimation(animation)
					track.Looped = true
					local sound = SoundEffectHandler.GetSound("Skibidi1")
					sound.Looped = true

					while runningEffects[modelClone] and modelClone.Parent do
						if Globals.flushStarted then
							if not sound.IsPlaying then
								sound:Play()
							end
							if not track.IsPlaying then
								track:Play()
							end
						else
							track:Stop()
							sound:Stop()
						end
						task.wait()
					end

					-- cleanup when loop exits
					track:Stop()
					sound:Stop()
					runningEffects[modelClone] = nil
				else
					warn("Didnt find animations")
					runningEffects[modelClone] = nil
				end
			end)
			-- modelClone:PivotTo(particleBaseCframe * CFrame.Angles(0, math.rad(180), 0))
			table.insert(curSpecialEffects, modelClone)
		end
	end
end

local curDecals = {}
local function SetDecals(selectedToiletPart: MeshPart?, toiletPart: MeshPart)
	local decals = selectedToiletPart and selectedToiletPart:GetChildren()

	if decals then
		print("Found some sick decals")

		for _, decal in ipairs(decals) do
			if decal:IsA("Decal") then
				local decalClone = decal:Clone()
				decalClone.Parent = toiletPart
				table.insert(curDecals, decal)
			end
		end
	else
		return
	end
end

local function extractDataFromToiletModel(
	model: Instance,
	mode: "Color" | "Material"
): {
	Lid: Enum.Material | Color3?,
	Body: Enum.Material | Color3?,
	Seat: Enum.Material | Color3?,
}
	local results = {}

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("MeshPart") then
			if mode == "Color" then
				results[child.Name] = child.Color
			else -- mode == "Material"
				results[child.Name] = child.Material
			end
		end
	end

	return results
end

function flushUtils.SetPlayerToilet(player: Player)
	local localstats = player:FindFirstChild("localstats")
	local equippedToilet: IntValue? = localstats and localstats:FindFirstChild("EquippedToilet")
	local selectedToilet = toiletModels[1]
	if equippedToilet then
		local id = equippedToilet.Value
		for _, toiletItem in ipairs(toiletModels) do
			local itemId = toiletItem:GetAttribute("Id")
			if itemId and itemId == id then
				print("Found toilet!")
				selectedToilet = toiletItem
				break
			end
		end
	end

	-- TODO: This should accomadate cooler toilets down the line
	local colors = extractDataFromToiletModel(selectedToilet, "Color")
	local materials = extractDataFromToiletModel(selectedToilet, "Material")
	SetSpecialEffects(selectedToilet)

	if curDecals and #curDecals > 0 then
		for _, decal in ipairs(curDecals) do
			decal:Destroy()
		end
	end
	curDecals = {}
	SetDecals(selectedToilet:FindFirstChild("Lid"), flushUtils.toiletLid)
	SetDecals(selectedToilet:FindFirstChild("Body"), flushUtils.toiletBody)
	SetDecals(selectedToilet:FindFirstChild("Seat"), flushUtils.toiletSeat)

	print(colors)
	print(materials)
	flushUtils.toiletLid.Color = colors.Lid and colors.Lid or flushUtils.toiletLid.Color
	flushUtils.toiletLid.Material = materials.Lid and materials.Lid or flushUtils.toiletLid.Material

	flushUtils.toiletBody.Color = colors.Body and colors.Body or flushUtils.toiletBody.Color
	flushUtils.toiletBody.Material = materials.Body and materials.Body or flushUtils.toiletBody.Material

	flushUtils.toiletSeat.Color = colors.Seat and colors.Seat or flushUtils.toiletSeat.Color
	flushUtils.toiletSeat.Material = materials.Seat and materials.Seat or flushUtils.toiletSeat.Material
end

local CLEAN_DUR = 1
function flushUtils.CleanToilet()
	local activeParts = ToiletSwitcher.ActiveToilet

	SoundEffectHandler.Play("Clean")
	task.spawn(function()
		universalEmitter.Enabled = true
		task.wait(CLEAN_DUR)
		universalEmitter.Enabled = false
	end)

	for _, part in pairs(activeParts) do
		task.spawn(function()
			if part:IsA("BasePart") then
				local originalColor = part.Color

				part.Color = Color3.new(1, 1, 1)

				local flashBackTween = TweenService:Create(
					part,
					TweenInfo.new(CLEAN_DUR, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Color = originalColor }
				)

				flashBackTween:Play()
			end
		end)
	end
end

local JAM_ELASTIC_DUR = 0.7
local PULSE_DUR = 0.6
local tween, ogSize, sound
function flushUtils.JamToilet(toJam: boolean)
	if toJam then
		sound = SoundEffectHandler.GetSound("Rattling")
		sound.Looped = true
		sound.Volume = 1.5
		sound:Play()
		ogSize = jammedFrame.Size
		clientUitls.PopFrameElastic(jammedFrame, jammedFrame.Size, JAM_ELASTIC_DUR, 0)
		task.delay(JAM_ELASTIC_DUR, function()
			ogSize = jammedFrame.Size
			tween = clientUitls.PulseContinuously2(jammedFrame, UDim2.new(1, 0, 1, 0), PULSE_DUR)
		end)
	else
		jammedFrame.Visible = false
		if tween then
			tween:Cancel()
		end
		if ogSize then
			jammedFrame.Size = ogSize
		end
		if sound and sound.IsPlaying then
			sound:Stop()
		end
	end
end
return flushUtils
