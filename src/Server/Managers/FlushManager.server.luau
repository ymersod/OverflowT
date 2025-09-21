local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)

local GameEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("GameEvents")
local StartFlushEvent = GameEvents:WaitForChild("StartFlush")
local FinishFlushEvent = GameEvents:WaitForChild("FinishFlush")

local Rumble = require(game.ServerScriptService.Server.Toilet.RumbleAnimation)
local CollectionService = game:GetService("CollectionService")

local ServerStorage = game:GetService("ServerStorage")
local LineArray = require(ServerScriptService.Server.LineArray)
local tags = require(ReplicatedStorage.Shared.tags)
local toiletLid = CollectionService:GetTagged(tags.TOILET_LID)[1]
local toiletSeat = CollectionService:GetTagged(tags.TOILET_SEAT)[1]
local toiletBody = CollectionService:GetTagged(tags.TOILET_BODY)[1]
local mainToilet = CollectionService:GetTagged(tags.GOLDEN_TOILET)[1]
local particleBase: Part = CollectionService:GetTagged(tags.TOILET_PARTICLE_BASE)[1]
local particlesNormalSetting = {}
local waterParticles = {}

local Sound = require(game.ServerScriptService.Server.Toilet.ToiletSoundHandler)

local bubbleTypes: { Part } = ServerStorage:WaitForChild("BubbleTypes"):GetChildren()
local curBubbles = bubbleTypes[1]

for _, particle in ipairs(curBubbles:GetDescendants()) do
	if particle:IsA("ParticleEmitter") then
		table.insert(waterParticles, particle)
		table.insert(particlesNormalSetting, particle.Rate) --<- Index isn't the same anymore
	end
end

local toiletLidMaxAmp = 50
local toiletLidSpeed = 0.1
local toiletBodyMaxAmp = 12
local toiletBodySpeed = 0.1
local toiletSeatMaxAmp = 30
local toiletSeatSpeed = 0.2

local lastTimeIteration = 0
local flushStarted = false
local currentHolder = nil

for _, particle in ipairs(curBubbles:GetDescendants()) do
	if particle:IsA("ParticleEmitter") then
		table.insert(particlesNormalSetting, particle.Rate)
	end
end

local function getPercentageFull(): number
	local curCap = FlushHandler.curCap
	local timeHeld = FlushHandler.totalTimeHeld
	if curCap == 0 or timeHeld == 0 then
		return 0
	end
	return timeHeld / curCap
end

local function getIntensity(maxAmp, standardPercent: number?): number
	standardPercent = standardPercent or 0.1
	local standard = maxAmp * standardPercent
	local timeHeld = FlushHandler.totalTimeHeld
	local curCap = FlushHandler.curCap
	if timeHeld == 0 or curCap == 0 then
		return standard
	end
	local animationCap = timeHeld / (curCap * 0.9)
	if animationCap >= 1 then
		return maxAmp
	end

	local curvedCap = animationCap ^ 2

	return standard + ((maxAmp - standard) * curvedCap)
end

local function SetParticlesEnabled(enabled: boolean)
	for i, descendant in ipairs(waterParticles) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Rate = getIntensity(particlesNormalSetting[i])
			descendant.Enabled = enabled
		end
	end
end

local function turnOnRumbleAnimation()
	Rumble.Vertical(toiletLid, getIntensity(toiletLidMaxAmp), toiletLidSpeed)
	Rumble.Vertical(toiletBody, getIntensity(toiletBodyMaxAmp), toiletBodySpeed)
	Rumble.Horizontal(toiletSeat, getIntensity(toiletSeatMaxAmp), toiletSeatSpeed)
end

local function updateRumbleAnimation()
	Rumble.SetAngle(toiletLid, getIntensity(toiletLidMaxAmp))
	Rumble.SetAngle(toiletBody, getIntensity(toiletBodyMaxAmp))
	Rumble.SetAngle(toiletSeat, getIntensity(toiletSeatMaxAmp))
end

local function turnOfRumbleAnimation()
	Rumble.Stop(toiletLid)
	Rumble.Stop(toiletSeat)
	Rumble.Stop(toiletBody)
end

local function CleanupPreviousParticleObjects(obj: Instance)
	print("Cleaning up old particles...")

	local remaining = 0

	local function markDone()
		remaining -= 1
		if remaining <= 0 then
			print("Old particles cleaned up!")
			obj:Destroy()
		end
	end

	for _, child in ipairs(obj:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
			remaining += 1
			task.delay(child.Lifetime.Max, function()
				markDone()
			end)
		end
	end

	-- if nothing to wait for, destroy immediately
	if remaining == 0 then
		print("No particles/sounds active, destroying immediately")
		obj:Destroy()
	end
end

local function SetupPlayerBubbleType(player: Player): Part
	local localstats = player:FindFirstChild("localstats")
	local equippedBubbles: IntValue? = localstats and localstats:FindFirstChild("EquippedShopItem")
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
				print("doing t")
				CleanupPreviousParticleObjects(child)
			end)
		end
	end

	local clone = selectedBubble:Clone()
	clone.Parent = mainToilet
	clone.CFrame = particleBase.CFrame
	clone.Size = particleBase.Size
	print("New bubbles!: ", clone)
	return clone
end

StartFlushEvent.OnServerEvent:Connect(function(player: Player)
	currentHolder = player
	lastTimeIteration = os.clock()
	flushStarted = true

	curBubbles = SetupPlayerBubbleType(player)
	table.clear(particlesNormalSetting)
	table.clear(waterParticles)
	for _, particle in ipairs(curBubbles:GetDescendants()) do
		if particle:IsA("ParticleEmitter") then
			table.insert(waterParticles, particle)
			table.insert(particlesNormalSetting, particle.Rate) --<- Index isn't the same anymore
		end
	end
	table.clear(particlesNormalSetting)
	for _, particle in ipairs(curBubbles:GetDescendants()) do
		if particle:IsA("ParticleEmitter") then
			table.insert(particlesNormalSetting, particle.Rate)
		end
	end
	Sound.FillSounds()
	turnOnRumbleAnimation()
	SetParticlesEnabled(true)
	Sound.Update(getPercentageFull())
end)

local function stopFlushing()
	flushStarted = false

	turnOfRumbleAnimation()
	SetParticlesEnabled(false)
	Sound.Stop()
end

RunService.Heartbeat:Connect(function()
	local line = LineArray:GetLine()
	if #line > 0 and line[1] and currentHolder then
		if currentHolder.UserId ~= line[1] then
			stopFlushing()
		end
	end

	if not flushStarted then
		return
	end

	updateRumbleAnimation()
	SetParticlesEnabled(true)
	Sound.Update(getPercentageFull())
	local currentTime = os.clock()
	local clockedTime = currentTime - lastTimeIteration
	lastTimeIteration = currentTime
	FlushHandler.AddFlushedTime(clockedTime, currentHolder)

	if not FlushHandler.gameOnGoing then
		stopFlushing()
	end
end)
