local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tags = require(ReplicatedStorage.Shared.tags)

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")
local newLinePosition = 0
local prevLinePosition = 0

-- World objects
local lobbyZone, spots
local function getWorldObjects()
	lobbyZone = CollectionService:GetTagged(tags.LOBBYZONE)[1]
	spots = CollectionService:GetTagged(tags.SPOT_TAG)

	CollectionService:GetInstanceAddedSignal(tags.SPOT_TAG):Connect(function(obj)
		table.insert(spots, obj)
	end)
end
getWorldObjects()

local function MovePlayersToLobbyCenter()
	local character = Player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart

		hrp.CFrame = CFrame.new(lobbyZone.Position)
	end
end

function updateHumanoid(newVal: number)
	if #spots ~= 6 then
		warn("Theres not exactly 6 spots only " .. #spots .. " were found")
		return
	end

	local char = Player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char.PrimaryPart

	if not char or not hum or not hrp then
		warn("Humanoid or humanoidrootpart doesnt exist")
	end

	-- put them in spawn
	if newVal == 0 then
		if lobbyZone then
			MovePlayersToLobbyCenter()
		end
	elseif newVal > 0 then
		local spot
		for _, lilSpot in ipairs(spots) do
			if lilSpot:GetAttribute("ArrayIndex") == newVal then
				spot = lilSpot
				break
			end
		end

		if not spot then
			warn("Spot not found yikers")
			return
		end

		if prevLinePosition == 0 or prevLinePosition == 1 then
			hrp.CFrame = CFrame.new(spot.Position)
		else
			hum.WalkToPart(spot)
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
