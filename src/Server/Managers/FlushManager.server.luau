local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)

local GameEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("GameEvents")
local StartFlushEvent = GameEvents:WaitForChild("StartFlush")
local ResetFlushEvent = GameEvents:WaitForChild("ResetToilet")
local OverflowToiletEvent = GameEvents:WaitForChild("OverflowToilet")
local FreezeToiletEvent = GameEvents:WaitForChild("FreezeToilet")

local Rumble = require(game.ServerScriptService.Server.Toilet.RumbleAnimation)
local ServerStorage = game:GetService("ServerStorage")
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local Globals = require(ServerScriptService.Server.Globals)

local LineArray = require(ServerScriptService.Server.LineArray)
local flushUtils = require(ServerScriptService.Server.flushUtils)
local tags = require(ReplicatedStorage.Shared.tags)

local Sound = require(game.ServerScriptService.Server.Toilet.ToiletSoundHandler)

local overflowExplosion: Explosion = ServerStorage:WaitForChild("OverflowExplosion")

local curBubbles = flushUtils.curBubbles
local freezeTimer = nil
local isFreezed = Instance.new("BoolValue")
isFreezed.Name = "IsFreezed"
isFreezed.Value = false

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

local function SetParticlesEnabled(enabled: boolean, tag: string, particleArr: { Particle }, manualRate: number?)
	for _, descendant in ipairs(particleArr) do
		if descendant.Emitter:IsA("ParticleEmitter") and descendant.Emitter:HasTag(tag) then
			descendant.Emitter.Rate = manualRate and manualRate or getIntensity(descendant.Rate)
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
	flushUtils.CleanToilet()
end)

local function playOnClickExplosionSplash(explDur: number, volume: number, manualRate: number?, callback: () -> ()?)
	SetParticlesEnabled(true, tags.CLICK_PARTICLES, explParticles, manualRate)
	Sound.PlayClickExpl(volume)
	task.delay(explDur, function()
		SetParticlesEnabled(false, tags.CLICK_PARTICLES, explParticles)
		if callback then
			callback()
		end
	end)
end

local OVERFLOW_DUR = 0.7
OverflowToiletEvent.OnServerEvent:Connect(function()
	curBubbles = flushUtils.curBubbles
	updateParticleTables(curBubbles)
	Sound.FillSounds(curBubbles)

	overflowExplosion:Clone()
	overflowExplosion.Parent = flushUtils.toiletBody -- Doesnt really matter what parent is, position is already set
	SoundEffectHandler.Play("Explosion")
	task.delay(OVERFLOW_DUR * 2, function()
		overflowExplosion:Destroy()
	end)

	playOnClickExplosionSplash(OVERFLOW_DUR, 2, 100, function()
		task.delay(OVERFLOW_DUR, function()
			FlushHandler.Overflow()
		end)
	end)
end)

local function startToiletAnimation()
	turnOnRumbleAnimation()
	SetParticlesEnabled(true, tags.HOLD_PARTICLES, waterParticles)
	playOnClickExplosionSplash(CLICK_EXPL_LENGTH, getPercentageFull() + 1)

	Sound.Update(getPercentageFull())
end

local function stopToiletAnimation()
	turnOfRumbleAnimation()
	SetParticlesEnabled(false, tags.HOLD_PARTICLES, waterParticles)
	Sound.Stop()
end

local function stopFlushing()
	Globals.flushStarted = false
	stopToiletAnimation()
end

StartFlushEvent.OnServerEvent:Connect(function(player: Player)
	currentHolder = player
	lastTimeIteration = os.clock()
	Globals.flushStarted = true

	curBubbles = flushUtils.curBubbles
	updateParticleTables(curBubbles)

	Sound.FillSounds(curBubbles)
	if isFreezed.Value then
		return
	end

	startToiletAnimation()
end)

isFreezed:GetPropertyChangedSignal("Value"):Connect(function()
	local newVal = isFreezed.Value
	if newVal and Globals.flushStarted then
		stopToiletAnimation()
	elseif not newVal and Globals.flushStarted then
		startToiletAnimation()
	end
	FlushHandler.SetToFrozen(newVal)
end)

FreezeToiletEvent.OnServerEvent:Connect(function()
	if freezeTimer then
		task.cancel(freezeTimer)
		freezeTimer = nil
	end

	isFreezed.Value = true

	freezeTimer = task.delay(10, function()
		isFreezed.Value = false
		freezeTimer = nil
	end)
end)

local lastHolderId = nil
RunService.Heartbeat:Connect(function()
	local line = LineArray:GetLine()
	local newHolderId = (line[1] or nil)

	if currentHolder and newHolderId then
		if currentHolder.UserId ~= newHolderId and lastHolderId ~= newHolderId then
			stopFlushing()
		end
	end

	lastHolderId = newHolderId

	local currentTime = os.clock()

	if not Globals.flushStarted or isFreezed.Value then
		lastTimeIteration = currentTime
		return
	end

	updateRumbleAnimation()
	SetParticlesEnabled(true, tags.HOLD_PARTICLES, waterParticles)
	Sound.Update(getPercentageFull())

	local clockedTime = currentTime - lastTimeIteration
	lastTimeIteration = currentTime
	FlushHandler.AddFlushedTime(clockedTime, currentHolder)

	if not FlushHandler.gameOnGoing then
		stopFlushing()
	end
end)
