local SoundService = game:GetService("SoundService")

local SoundEffects = {}

export type SoundName =
	| "UniversalButtonHover"
	| "UniversalButtonClick"
	| "WaterPourClick"
	| "DailyPlaytimeNotification"
	| "TimerTicking"
	| "AfkLostSound"
	| "LoseRound"
	| "CoinReward"
	| "WinRound"
	| "Teleport"
	| "DailyPlaytimeCashIn"

local trackList: { [SoundName]: number } = {
	UniversalButtonHover = 6042053626,
	UniversalButtonClick = 6042054037,
	WaterPourClick = 110597779584354,
	DailyPlaytimeNotification = 7381723941,
	TimerTicking = 102798068744743,
	AfkLostSound = 4525880816,
	LoseRound = 4881487887,
	CoinReward = 7772692875,
	WinRound = 748978048,
	Teleport = 93826112721753,
	DailyPlaytimeCashIn = 3120909354,
}

local sounds: { [SoundName]: Sound } = {}

for name, id in pairs(trackList) do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = 1
	sound.Looped = false
	sound.Parent = SoundService
	sounds[name] = sound
end

function SoundEffects.Play(name: SoundName)
	print("Trying to play")
	local sound = sounds[name]
	if sound then
		sound.TimePosition = 0
		sound:Play()
	else
		warn("No sound found with name:", name)
	end
end

function SoundEffects.Stop(name: SoundName)
	local sound = sounds[name]
	if sound then
		sound:Stop()
	end
end

return SoundEffects
