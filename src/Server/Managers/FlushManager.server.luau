local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)

local GameEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("GameEvents")
local StartFlushEvent = GameEvents:WaitForChild("StartFlush")
local ResetFlushEvent = GameEvents:WaitForChild("ResetToilet")

local Rumble = require(game.ServerScriptService.Server.Toilet.RumbleAnimation)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local LineArray = require(ServerScriptService.Server.LineArray)
local flushUtils = require(ServerScriptService.Server.flushUtils)
local tags = require(ReplicatedStorage.Shared.tags)

local Sound = require(game.ServerScriptService.Server.Toilet.ToiletSoundHandler)

local curBubbles = flushUtils.curBubbles

type Particle = {
	Emitter: ParticleEmitter,
	Rate: number,
}
local waterParticles: { Particle } = {}
local explParticles: { Particle } = {}

local CLICK_EXPL_LENGTH = 0.2

local function updateParticleTables(particleParent)
	table.clear(waterParticles)
	table.clear(explParticles)
	for _, particle: Instance in ipairs(particleParent:GetDescendants()) do
		if particle:IsA("ParticleEmitter") and particle:HasTag(tags.HOLD_PARTICLES) then
			table.insert(waterParticles, {
				Emitter = particle,
				Rate = particle.Rate,
			})
		elseif particle:IsA("ParticleEmitter") and particle:HasTag(tags.CLICK_PARTICLES) then
			table.insert(explParticles, {
				Emitter = particle,
				Rate = particle.Rate,
			})
		end
	end
end
updateParticleTables(curBubbles)

local toiletLidMaxAmp = 50
local toiletLidSpeed = 0.1
local toiletBodyMaxAmp = 12
local toiletBodySpeed = 0.1
local toiletSeatMaxAmp = 30
local toiletSeatSpeed = 0.2

local lastTimeIteration = 0
local flushStarted = false
local currentHolder = nil

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

local function SetParticlesEnabled(enabled: boolean, tag: string, particleArr: { Particle })
	for _, descendant in ipairs(particleArr) do
		if descendant.Emitter:IsA("ParticleEmitter") and descendant.Emitter:HasTag(tag) then
			descendant.Emitter.Rate = getIntensity(descendant.Rate)
			descendant.Emitter.Enabled = enabled
		end
	end
end

local function turnOnRumbleAnimation()
	Rumble.Vertical(flushUtils.toiletLid, getIntensity(toiletLidMaxAmp), toiletLidSpeed)
	Rumble.Vertical(flushUtils.toiletBody, getIntensity(toiletBodyMaxAmp), toiletBodySpeed)
	Rumble.Horizontal(flushUtils.toiletSeat, getIntensity(toiletSeatMaxAmp), toiletSeatSpeed)
end

local function updateRumbleAnimation()
	Rumble.SetAngle(flushUtils.toiletLid, getIntensity(toiletLidMaxAmp))
	Rumble.SetAngle(flushUtils.toiletBody, getIntensity(toiletBodyMaxAmp))
	Rumble.SetAngle(flushUtils.toiletSeat, getIntensity(toiletSeatMaxAmp))
end

local function turnOfRumbleAnimation()
	Rumble.Stop(flushUtils.toiletLid)
	Rumble.Stop(flushUtils.toiletSeat)
	Rumble.Stop(flushUtils.toiletBody)
end

ResetFlushEvent.OnServerEvent:Connect(function()
	FlushHandler.ResetTimeHeld()
end)

StartFlushEvent.OnServerEvent:Connect(function(player: Player)
	currentHolder = player
	lastTimeIteration = os.clock()
	flushStarted = true

	curBubbles = flushUtils.curBubbles
	updateParticleTables(curBubbles)

	Sound.FillSounds(curBubbles)
	turnOnRumbleAnimation()
	SetParticlesEnabled(true, tags.HOLD_PARTICLES, waterParticles)

	SetParticlesEnabled(true, tags.CLICK_PARTICLES, explParticles)
	Sound.PlayClickExpl(getPercentageFull() + 1)
	task.delay(CLICK_EXPL_LENGTH, function()
		SetParticlesEnabled(false, tags.CLICK_PARTICLES, explParticles)
	end)

	Sound.Update(getPercentageFull())
end)

local function stopFlushing()
	flushStarted = false

	turnOfRumbleAnimation()
	SetParticlesEnabled(false, tags.HOLD_PARTICLES, waterParticles)
	Sound.Stop()
end

local lastHolderId = nil
RunService.Heartbeat:Connect(function()
	local line = LineArray:GetLine()
	local newHolderId = (line[1] or nil)

	if currentHolder and newHolderId then
		if currentHolder.UserId ~= newHolderId and lastHolderId ~= newHolderId then
			local player = Players:GetPlayerByUserId(newHolderId)

			if player then
				task.spawn(function()
					flushUtils.SetupPlayerBubbleType(player)
					flushUtils.SetPlayerToilet(player)
				end)
			end
			stopFlushing()
		end
	end

	lastHolderId = newHolderId

	if not flushStarted then
		return
	end

	updateRumbleAnimation()
	SetParticlesEnabled(true, tags.HOLD_PARTICLES, waterParticles)
	Sound.Update(getPercentageFull())

	local currentTime = os.clock()
	local clockedTime = currentTime - lastTimeIteration
	lastTimeIteration = currentTime
	FlushHandler.AddFlushedTime(clockedTime, currentHolder)

	if not FlushHandler.gameOnGoing then
		stopFlushing()
	end
end)
