local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local enums = require(ReplicatedStorage.Shared.enums)

local funnelEvents = {}
funnelEvents.playerFlagsCache = {}
local _playerFlagsCache: { [string]: { onboarded: boolean, stepsCompleted: { number } } } =
	funnelEvents.playerFlagsCache

local function MockFunnel(player: Player, stepName: string, step: number, sessionName: string, sessionId: string?)
	local s = sessionId or "nil"
	print(
		`[LOGGING FUNNEL] Player: {player.UserId} `
			.. `SessionName: {sessionName} `
			.. `StepName: {stepName} `
			.. `Step: {step} `
			.. `SessionId: {s}`
	)
end

-- ONBOARDING
local function OnboardStep(player: Player, step: number, maxSteps: number?): boolean
	local entry = funnelEvents.playerFlagsCache[tostring(player.UserId)]
	if not entry then
		entry = {
			onboarded = false,
			stepsCompleted = {},
		}
		funnelEvents.playerFlagsCache[tostring(player.UserId)] = entry
	end

	if entry.onboarded then
		return true
	end

	local steps = entry.stepsCompleted

	for _, s in ipairs(steps) do
		if s == step then
			return true
		end
	end

	table.insert(steps, step)

	if maxSteps and #steps >= maxSteps then
		entry.onboarded = true
	end

	return false -- step was just completed now
end

local function LogOnboarding(player, step, description: string)
	task.spawn(function()
		MockFunnel(player, description, step, "Onboarding")
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, description)
	end)
end

function funnelEvents.OnboardPlayersPlayer(players: { Player }, stepEnumName: string)
	for _, player in ipairs(players) do
		if
			not OnboardStep(
				player,
				enums.Analytics.Onboarding[stepEnumName].step,
				enums.Analytics.Onboarding.TotalSteps
			)
		then
			LogOnboarding(
				player,
				enums.Analytics.Onboarding[stepEnumName].step,
				enums.Analytics.Onboarding[stepEnumName].stepname
			)
		end
	end
end

function funnelEvents.OnboardPlayersUserId(players: { number }, stepEnumName: string)
	for _, playerId in ipairs(players) do
		local player = Players:GetPlayerByUserId(playerId)
		if not player then
			continue
		end
		if
			not OnboardStep(
				player,
				enums.Analytics.Onboarding[stepEnumName].step,
				enums.Analytics.Onboarding.TotalSteps
			)
		then
			LogOnboarding(
				player,
				enums.Analytics.Onboarding[stepEnumName].step,
				enums.Analytics.Onboarding[stepEnumName].stepname
			)
		end
	end
end

-- STEPS

local sessionIdCache: { [string]: { [string]: { sessionId: string, stepsCompleted: { number } } } } = {}

local function StepCompleted(sessionName: string, stepEnumName: string, stepsCompleted: { number })
	if not stepsCompleted or #stepsCompleted < 1 then
		return false
	end

	for _, step in ipairs(stepsCompleted) do
		local stepFound = enums.Analytics[sessionName][stepEnumName]
		if stepFound and stepFound.step == step then
			return true
		end
	end

	return false
end

local function LogStep(
	players: { Player },
	stepEnumName: string,
	sessionName: string,
	clearSession: boolean?,
	repeatable: boolean?
)
	task.defer(function()
		for _, player in ipairs(players) do
			local userIdStr = tostring(player.UserId)

			sessionIdCache[userIdStr] = sessionIdCache[userIdStr] or {}
			sessionIdCache[userIdStr][sessionName] = sessionIdCache[userIdStr][sessionName]
				or { sessionId = HttpService:GenerateGUID(false), stepsCompleted = {} }

			local session = sessionIdCache[userIdStr][sessionName]

			if StepCompleted(sessionName, stepEnumName, session.stepsCompleted) then
				print(`Step {stepEnumName} already completed for {player.Name}`)
				continue
			end

			local step = enums.Analytics[sessionName][stepEnumName]
			if not step then
				warn(`Invalid stepEnumName {stepEnumName} for session {sessionName}`)
				continue
			end

			local stepIndex = step.step
			local stepName = step.stepname

			if stepIndex and stepName then
				AnalyticsService:LogFunnelStepEvent(player, sessionName, session.sessionId, stepIndex, stepName)
				MockFunnel(player, stepName, step, sessionName, session.sessionId)

				if not repeatable then
					table.insert(session.stepsCompleted, stepIndex)
				end
			else
				warn(`Invalid step data for player {player.UserId} in funnel {sessionName}`)
			end

			if clearSession then
				sessionIdCache[userIdStr][sessionName] = nil
			end
		end
	end)
end

function funnelEvents.LogStepPlayers(
	players: { Player },
	stepEnumName: string,
	sessionName: string,
	clearSession: boolean?,
	repeatable: boolean?
)
	LogStep(players, stepEnumName, sessionName, clearSession or false, repeatable or false)
end

function funnelEvents.LogStepPlayerIds(
	players: { string },
	stepEnumName: string,
	sessionName: string,
	clearSession: boolean?,
	repeatable: boolean?
)
	local foundPlayers: { Player } = {}
	for _, id in ipairs(players) do
		local player = Players:GetPlayerByUserId(id)
		if player then
			table.insert(foundPlayers, player)
		end
	end
	LogStep(foundPlayers, stepEnumName, sessionName, clearSession or false, repeatable or false)
end

Players.PlayerRemoving:Connect(function(player)
	sessionIdCache[tostring(player.UserId)] = nil
end)

return funnelEvents
