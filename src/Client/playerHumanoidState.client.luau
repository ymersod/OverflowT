local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tags = require(ReplicatedStorage.Shared.tags)

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")
local newLinePosition = 0
local prevLinePosition = 0

-- World objects
local spawns = CollectionService:GetTagged(tags.SPAWN_TAG)
if #spawns > 1 then
	warn("Didnt find no spawns")
end
local spots = CollectionService:GetTagged(tags.SPOT_TAG)

function updateHumanoid(newVal: number)
	local char = Player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char.PrimaryPart

	if not char or not hum or not hrp then
		warn("Humanoid or humanoidrootpart doesnt exist")
	end

	-- put them in spawn
	if newVal == 0 then
		if #spawns > 0 then
			local spawnLoc = spawns[1]

			if spawnLoc and spawnLoc:IsA("SpawnLocation") then
				hrp.CFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
			end
		end
	elseif newVal > 0 then
		local spot = spots[newVal]
		if prevLinePosition == 0 or prevLinePosition == 1 then
			hrp.CFrame = spot.CFrame + Vector3.new(0, 5, 0)
		else
			hum.WalkToPart(spots[newVal])
		end
	end
end

function startListen()
	linePosition.Changed:Connect(function()
		prevLinePosition = newLinePosition
		newLinePosition = linePosition.Value
		updateHumanoid(newLinePosition)
	end)
end
startListen()
