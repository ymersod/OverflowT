local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)

local GameEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("GameEvents")
local StartFlushEvent = GameEvents:WaitForChild("StartFlush")
local FinishFlushEvent = GameEvents:WaitForChild("FinishFlush")

local Rumble = require(game.ServerScriptService.Server.Toilet.RumbleAnimation)
local CollectionService = game:GetService("CollectionService")
local toiletLid = CollectionService:GetTagged("ToiletLid")[1]
local toiletSeat = CollectionService:GetTagged("ToiletSeat")[1]
local toiletBody = CollectionService:GetTagged("ToiletBody")[1]
local particles = CollectionService:GetTagged("WaterParticleActive")[1]
local waterParticles = {}
local particlesNormalSetting = {}

local Sound = require(game.ServerScriptService.Server.Toilet.ToiletSoundHandler)

for _, particle in ipairs(particles:GetDescendants()) do
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
local inactive = true
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

StartFlushEvent.OnServerEvent:Connect(function(player: Player)
	currentHolder = player
	lastTimeIteration = os.clock()
	inactive = false
	turnOnRumbleAnimation()
	SetParticlesEnabled(true)
	Sound.Update(getPercentageFull())
end)

FinishFlushEvent.OnServerInvoke = function(_: Player)
	if inactive then
		return false --This is to say, there has happened an overflow
	end
	inactive = true
	turnOfRumbleAnimation()
	SetParticlesEnabled(false)
	Sound.Stop()
	return true
end

RunService.Heartbeat:Connect(function()
	if inactive then
		return
	end
	updateRumbleAnimation()
	SetParticlesEnabled(true)
	Sound.Update(getPercentageFull())
	local currentTime = os.clock()
	local clockedTime = currentTime - lastTimeIteration
	lastTimeIteration = currentTime
	local isStillRunning = FlushHandler.AddFlushedTime(clockedTime, currentHolder)
	if not isStillRunning then
		inactive = true
		turnOfRumbleAnimation()
		SetParticlesEnabled(false)
		Sound.Reset()
	end
end)
