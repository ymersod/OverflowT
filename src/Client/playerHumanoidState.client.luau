local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local FREEZE_ACTION = "freezeMovement"

local tags = require(ReplicatedStorage.Shared.tags)

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")
local newLinePosition = 0
local prevLinePosition = 0

-- World objects
local lobbyZone, spots: { BasePart }, toilet: { BasePart }
local function getWorldObjects()
	lobbyZone = CollectionService:GetTagged(tags.LOBBYZONE)
	spots = CollectionService:GetTagged(tags.SPOT_TAG)
	toilet = CollectionService:GetTagged(tags.TOILET)

	CollectionService:GetInstanceAddedSignal(tags.LOBBYZONE):Connect(function(obj)
		table.insert(lobbyZone, obj)
	end)
	CollectionService:GetInstanceAddedSignal(tags.SPOT_TAG):Connect(function(obj)
		table.insert(spots, obj)
	end)
	CollectionService:GetInstanceAddedSignal(tags.TOILET):Connect(function(obj)
		table.insert(toilet, obj)
	end)
end
getWorldObjects()

local function MovePlayersToLobbyCenter()
	local character = Player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart

		hrp.CFrame = CFrame.new(lobbyZone[1].Position)
	end
end

function updateHumanoid()
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
	if newLinePosition == 0 then
		-- Unfreeze player
		ContextActionService:UnbindAction(FREEZE_ACTION)

		hum.WalkSpeed = 16
		if lobbyZone then
			MovePlayersToLobbyCenter()
		end
	elseif newLinePosition > 0 then
		-- Freeze player
		ContextActionService:BindAction(FREEZE_ACTION, function()
			return Enum.ContextActionResult.Sink
		end, false, unpack(Enum.PlayerActions:GetEnumItems()))

		hum.WalkSpeed = 32
		local spot
		for _, lilSpot in ipairs(spots) do
			if lilSpot:GetAttribute("ArrayIndex") == newLinePosition then
				spot = lilSpot
				break
			end
		end

		if not spot then
			warn("Spot not found yikers")
			return
		end
		print("MY NEW SPOT: " .. spot:GetAttribute("ArrayIndex") .. " and newline is:  " .. newLinePosition)

		if prevLinePosition == 0 then
			hrp.CFrame = CFrame.new(spot.Position)
		else
			hum:MoveTo(spot.Position)
			hum.MoveToFinished:Once(function()
				hrp.CFrame = CFrame.new(Vector3.new(spot.Position.X, hrp.Position.Y, spot.Position.Z))
				hrp:PivotTo(CFrame.lookAt(hrp.Position, toilet[1].Position))
			end)
		end
	end
end

function startListen()
	linePosition.Changed:Connect(function()
		prevLinePosition = newLinePosition
		newLinePosition = linePosition.Value
		updateHumanoid()
	end)
end
startListen()
