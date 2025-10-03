local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local backGroundMusic = {
	musicEnabled = true,
}

local waitingTracks = {
	132290528373653, --Miaw-music-waiting
	9045766074, --Squidgame-game-waiting
}

local roundTracks = {
	1841411483,
	1846458016,
	1843404009,
	1841998974,
	1837196544,
	1847506405,
	1835519330,
	1846368080,
	1837870468,
	1839857296,
	1838674668,
}

local currentSound: Sound?
local linePosition: IntValue = player:WaitForChild("States"):WaitForChild("LinePosition")

local function stopCurrent()
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
		currentSound = nil
	end
end

local function playRandom(trackList)
	stopCurrent()

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. trackList[math.random(1, #trackList)]
	sound.Looped = true
	sound.Volume = 0.05
	sound.Parent = SoundService
	sound:Play()

	currentSound = sound
end

RunService.Heartbeat:Connect(function()
	linePosition = player:WaitForChild("States"):WaitForChild("LinePosition")

	if backGroundMusic.musicEnabled and currentSound then
		currentSound.Volume = 0.05
	elseif currentSound then
		currentSound.Volume = 0
	end

	if linePosition.Value > 0 then
		if not currentSound or not table.find(roundTracks, tonumber(string.match(currentSound.SoundId, "%d+"))) then
			playRandom(roundTracks)
		end
	else
		if not currentSound or not table.find(waitingTracks, tonumber(string.match(currentSound.SoundId, "%d+"))) then
			playRandom(waitingTracks)
		end
	end
end)

return backGroundMusic
