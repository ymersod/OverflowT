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

local function SetParticlesEnabled(enabled: boolean)
	for _, descendant in ipairs(particles:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = enabled
		end
	end
end

local toiletLidMaxAmp = 9
local toiletLidSpeed = 0.1
local toiletBodyMaxAmp = 0.5
local toiletBodySpeed = 0.1
local toiletSeatMaxAmp = 7
local toiletSeatSpeed = 0.2

local lastTimeIteration = 0
local inactive = true
local currentHolder = nil

local function turnOnRumbleAnimation()
	Rumble.Vertical(toiletLid, toiletLidMaxAmp, toiletLidSpeed)
	Rumble.Vertical(toiletBody, toiletBodyMaxAmp, toiletBodySpeed)
	Rumble.Horizontal(toiletSeat, toiletSeatMaxAmp, toiletSeatSpeed)
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
end)

FinishFlushEvent.OnServerInvoke = function(_: Player)
	if inactive then
		return false --This is to say, there has happened an overflow
	end
	inactive = true
	turnOfRumbleAnimation()
	SetParticlesEnabled(false)
	return true
end

RunService.Heartbeat:Connect(function()
	if inactive then
		return
	end
	local currentTime = os.clock()
	local clockedTime = currentTime - lastTimeIteration
	lastTimeIteration = currentTime
	local isStillRunning = FlushHandler.AddFlushedTime(clockedTime, currentHolder)
	if not isStillRunning then
		inactive = true
		turnOfRumbleAnimation()
		SetParticlesEnabled(false)
	end
end)
