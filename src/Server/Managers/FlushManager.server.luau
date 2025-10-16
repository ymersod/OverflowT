local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlushHandler = require(ServerScriptService.Server.FlushHandler)
local ActionHandler = require(ServerScriptService.Server.ActionHandler)
local serverUtils = require(ServerScriptService.Server.serverUtils)

local GameEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("GameEvents")
local StartFlushEvent = GameEvents:WaitForChild("StartFlush")
local ResetFlushEvent = GameEvents:WaitForChild("ResetToilet")
local OverflowToiletEvent = GameEvents:WaitForChild("OverflowToilet")
local FreezeToiletEvent = GameEvents:WaitForChild("FreezeToilet")
local JamFlushEvent = GameEvents:WaitForChild("Jamflush")

local Rumble = require(game.ServerScriptService.Server.Toilet.RumbleAnimation)
local ServerStorage = game:GetService("ServerStorage")
local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local enums = require(ReplicatedStorage.Shared.enums)
local Globals = require(ServerScriptService.Server.Globals)

local LineArray = require(ServerScriptService.Server.LineArray)
local MonetizationHandler = require(ServerScriptService.Server.MonetizationHandler)
local NoobBot = require(ServerScriptService.Server.NoobBot)
local flushUtils = require(ServerScriptService.Server.flushUtils)
local funnelEvents = require(ServerScriptService.Server.funnelEvents)
local tags = require(ReplicatedStorage.Shared.tags)
local ServerEnums = require(ServerScriptService.Server.ServerEnums)

local Sound = require(game.ServerScriptService.Server.Toilet.ToiletSoundHandler)

local overflowExplosion: Explosion = ServerStorage:WaitForChild("ExplosionPrefab")

local curBubbles = flushUtils.curBubbles

local isFreezed: BoolValue = CollectionService:GetTagged(tags.IS_FREEZED)[1]
local isJammed: BoolValue = CollectionService:GetTagged(tags.IS_JAMMED)[1]
local freezeTimer = nil
local jamTimer = nil

type Particle = {
	Emitter: ParticleEmitter,
	Rate: number,
}
local waterParticles: { Particle } = {}
local explParticles: { Particle } = {}

local CLICK_EXPL_LENGTH = 0.2

-- SETTINGS
local TIME_FROZEN = 10
local TIME_JAMMED = 5

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

local function SetupForFlush()
	curBubbles = flushUtils.curBubbles
	updateParticleTables(curBubbles)
	Sound.FillSounds(curBubbles)
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

local function UsedAction(player: Player, actionId: string)
	if not LineArray:GetIndex(player.UserId) then
		MonetizationHandler.PromptRobuxPurchase(player, ServerEnums.DevProducts.Action.Name, actionId)
		return false
	end
	local playerId = tostring(player.UserId)
	local usableAction = serverUtils.getActionIfUsable(playerId, actionId)
	if not usableAction then
		MonetizationHandler.PromptRobuxPurchase(player, ServerEnums.DevProducts.Action.Name, actionId)
		return false
	end
	if Globals.isInOverflow then
		return false
	end
	serverUtils.updateActionDB(playerId, usableAction)
	return true
end

ResetFlushEvent.OnServerEvent:Connect(function(player: Player, actionId: string)
	ActionHandler:Enqueue(function()
		if not UsedAction(player, actionId) then
			return
		end
		FlushHandler.ResetTimeHeld()
		flushUtils.CleanToilet()
	end)
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
OverflowToiletEvent.OnServerEvent:Connect(function(player: Player, actionId: string)
	ActionHandler:Enqueue(function()
		if Globals.isInOverflow then
			return
		end
		if not UsedAction(player, actionId) then
			return
		end
		Globals.isInOverflow = true
		SetupForFlush()
		local overflowExplosionClone = overflowExplosion:Clone()
		overflowExplosionClone.Parent = flushUtils.toiletBody -- Doesnt really matter what parent is, position is already set
		SoundEffectHandler.Play("Explosion")
		task.delay(OVERFLOW_DUR * 2, function()
			overflowExplosionClone:Destroy()
		end)

		playOnClickExplosionSplash(OVERFLOW_DUR, 2, 100, function()
			task.delay(OVERFLOW_DUR, function()
				FlushHandler.Overflow()
				Globals.isInOverflow = false
			end)
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
	if not isJammed.Value then
		Globals.flushStarted = false
		stopToiletAnimation()
	end
end

local function startFlush(playerCall, line: {})
	FlushHandler.AddFlushedTime(0.3, playerCall, line)
	currentHolder = playerCall
	lastTimeIteration = os.clock()
	Globals.flushStarted = true

	SetupForFlush()
	if isFreezed.Value then
		return
	end

	startToiletAnimation()
end

StartFlushEvent.OnServerEvent:Connect(function(playerCall: Player)
	if not isJammed.Value or Globals.isInOverflow then
		ActionHandler:Enqueue(function()
			if LineArray:GetIndex(playerCall.UserId) ~= 1 then
				return
			end
			funnelEvents.LogStepPlayers(
				{ playerCall },
				enums.Analytics.Game.FlushedToilet.Name,
				enums.Analytics.Game.SessionName,
				false,
				true
			)
			startFlush(playerCall, LineArray:GetLine())
		end)
	end
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

FreezeToiletEvent.OnServerEvent:Connect(function(player: Player, actionId: string)
	ActionHandler:Enqueue(function()
		if not UsedAction(player, actionId) then
			return
		end

		if freezeTimer then
			task.cancel(freezeTimer)
			freezeTimer = nil
		end

		isFreezed.Value = true

		freezeTimer = task.delay(TIME_FROZEN, function()
			isFreezed.Value = false
			freezeTimer = nil
		end)
	end)
end)

isJammed:GetPropertyChangedSignal("Value"):Connect(function()
	local newVal = isJammed.Value
	if newVal then
		Globals.flushStarted = true
		flushUtils.JamToilet(true)
	elseif not newVal then
		Globals.flushStarted = false
		flushUtils.JamToilet(false)
	end
end)

local checkTaskConnection
JamFlushEvent.OnServerEvent:Connect(function(player: Player, actionId: string)
	-- print(actionId)
	-- local playerId = tostring(player.UserId)
	-- local check = serverUtils.getActionIfUsable(playerId, actionId)
	-- if not check then
	-- 	return
	-- end
	ActionHandler:Enqueue(function()
		if not UsedAction(player, actionId) then
			MonetizationHandler.PromptRobuxPurchase(player, ServerEnums.DevProducts.Action.Name, actionId)
			return
		end
		if jamTimer then
			task.cancel(jamTimer)
			jamTimer = nil
		end

		isJammed.Value = true
		jamTimer = task.delay(TIME_JAMMED, function()
			isJammed.Value = false
			jamTimer = nil

			if checkTaskConnection then
				checkTaskConnection:Disconnect()
				checkTaskConnection = nil
				stopToiletAnimation()
			end
		end)

		if checkTaskConnection then
			checkTaskConnection:Disconnect()
		end

		local prevJammedPlayer
		checkTaskConnection = RunService.Heartbeat:Connect(function()
			local line = LineArray:GetLine()
			local newHolderId = (line[1] or nil)
			local curJammedPlayer = newHolderId

			if newHolderId and curJammedPlayer ~= prevJammedPlayer then
				print("Setting new player!")
				local player = Players:GetPlayerByUserId(newHolderId)
				startFlush(player, LineArray:GetLine())
			end

			prevJammedPlayer = curJammedPlayer
		end)
	end)
end)

local lastHolderId = nil
local noobBotHeldTime = 0
local noobBotCap = math.random(1.5, 3)
local resatNoobBotsTurn = false
RunService.Heartbeat:Connect(function()
	local line = LineArray:GetLine()
	local newHolderId = (line[1] or nil)
	local currentTime = os.clock()

	if NoobBot.NoobBotVals.NoobBotsTurn then
		resatNoobBotsTurn = false

		if not isFreezed.Value then
			if noobBotHeldTime == 0 then
				turnOnRumbleAnimation()
				local clockedTime = currentTime - lastTimeIteration
				noobBotHeldTime += clockedTime
				lastTimeIteration = currentTime
			else
				updateRumbleAnimation()
				SetParticlesEnabled(true, tags.HOLD_PARTICLES, waterParticles)
				Sound.Update(getPercentageFull())
				local clockedTime = currentTime - lastTimeIteration
				noobBotHeldTime += clockedTime
				lastTimeIteration = currentTime

				FlushHandler.AddFlushedTime(clockedTime, currentHolder)
			end
		end

		if noobBotHeldTime > noobBotCap then
			noobBotHeldTime = 0
			noobBotCap = math.random(1, 2)
			LineArray:Next()
		end

		return
	elseif not NoobBot.NoobBotVals.NoobBotsTurn and not resatNoobBotsTurn then
		resatNoobBotsTurn = true
		stopFlushing()
	end

	if currentHolder and newHolderId then
		if currentHolder.UserId ~= newHolderId and lastHolderId ~= newHolderId then
			stopFlushing()
		end
	end

	lastHolderId = newHolderId

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
