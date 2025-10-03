local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local enums = require(ReplicatedStorage.Shared.enums)

local funnelEvents = {}
funnelEvents.playerFlagsCache = {}
local _playerFlagsCache: { [string]: { onboarded: boolean, stepsCompleted: { number } } } =
	funnelEvents.playerFlagsCache

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
		print("[LOGGING] Player: " .. player.UserId .. " Description: " .. description)
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

function funnelEvents.LogStep(player, step, description, funnelSessionId, funnelName)
	task.spawn(function()
		AnalyticsService:LogFunnelStepEvent(player, funnelName, funnelSessionId, step, description)
	end)
end

return funnelEvents
