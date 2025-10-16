local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local humanoidUtils = require(ReplicatedStorage.Shared.humanoidUtils)
local tags = require(ReplicatedStorage.Shared.tags)
local LineArray = require(script.Parent.LineArray)
local noobBotPrefab = ServerStorage:WaitForChild("NoobBot")

local spots = CollectionService:GetTagged(tags.SPOT_TAG)
local toilet = CollectionService:GetTagged(tags.GOLDEN_TOILET)

local noobBot = {}
noobBot.NoobBotVals = {
	noobBotClone = nil,
	NoobBotsTurn = false,
	ID = -999,
	playerMock = { UserId = -999, Name = "NoobBot" },
}

function noobBot.SetupNoobBot()
	noobBot.NoobBotVals.noobBotClone = noobBotPrefab:Clone()
	noobBot.NoobBotVals.noobBotClone.Parent = workspace

	return noobBot.NoobBotVals.playerMock
end

local function placeInLine(lineNr)
	local hum = noobBot.NoobBotVals.noobBotClone and noobBot.NoobBotVals.noobBotClone:FindFirstChildOfClass("Humanoid")
	local hrp = noobBot.NoobBotVals.noobBotClone and noobBot.NoobBotVals.noobBotClone.PrimaryPart

	if not hum and not hrp then
		return
	end

	hum.WalkSpeed = 32
	local spot
	for _, lilSpot in ipairs(spots) do
		if lilSpot:GetAttribute("ArrayIndex") == lineNr then
			spot = lilSpot
			break
		end
	end

	if not spot then
		warn("Spot not found yikers")
		return
	end
	hrp.CFrame = CFrame.new(spot.Position + Vector3.new(0, 3, 0))
end

local prevMover = nil
local function moveInLine(lineNr)
	local hum = noobBot.NoobBotVals.noobBotClone and noobBot.NoobBotVals.noobBotClone:FindFirstChildOfClass("Humanoid")
	local anim = hum and hum:WaitForChild("Animation") :: Animation
	local track = hum and hum:LoadAnimation(anim)
	local hrp = noobBot.NoobBotVals.noobBotClone and noobBot.NoobBotVals.noobBotClone.PrimaryPart
	if prevMover then
		prevMover.Cancel()
	end

	local spot
	for _, lilSpot in ipairs(spots) do
		if lilSpot:GetAttribute("ArrayIndex") == lineNr then
			spot = lilSpot
			break
		end
	end

	if not spot then
		warn("Spot not found yikers")
		return
	end

	track.Looped = true
	track:Play()
	prevMover = humanoidUtils.MoveTo(hum, spot.Position, function()
		track:Stop()
		hrp.CFrame = CFrame.new(Vector3.new(spot.Position.X, hrp.Position.Y, spot.Position.Z))
		local targetPart = toilet[1].PrimaryPart
		hrp:PivotTo(CFrame.lookAt(hrp.Position, targetPart.Position))
	end)
end

local placedInLine = false
local settingTurn = false
local lastIndex
RunService.Heartbeat:Connect(function()
	if not noobBot.NoobBotVals.noobBotClone then
		return
	end

	local index = LineArray:GetIndex(-999)
	if not placedInLine then
		placeInLine(index)
		placedInLine = true
	elseif lastIndex and lastIndex ~= index then
		moveInLine(index)
	end

	if index == 1 and not settingTurn then
		settingTurn = true
		task.wait(0.5)
		noobBot.NoobBotVals.NoobBotsTurn = true
	else
		settingTurn = false
		noobBot.NoobBotVals.NoobBotsTurn = false
	end

	lastIndex = index
end)

function noobBot.Stop()
	noobBot.NoobBotVals.noobBotClone:Destroy()
	noobBot.NoobBotVals.noobBotClone = nil
	placedInLine = false
	settingTurn = false
	noobBot.NoobBotVals.NoobBotsTurn = false
	print("Stop")
end

return noobBot
