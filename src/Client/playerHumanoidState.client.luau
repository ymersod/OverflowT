local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local FREEZE_ACTION = "freezeMovement"

local humanoidUtils = require(ReplicatedStorage.Shared.humanoidUtils)
local tags = require(ReplicatedStorage.Shared.tags)

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")
local newLinePosition = 0
local prevLinePosition = 0

-- World objects
local lobbyZone, spots: { BasePart }, toilet: { Model }
local function getWorldObjects()
	lobbyZone = CollectionService:GetTagged(tags.LOBBYZONE)
	spots = CollectionService:GetTagged(tags.SPOT_TAG)
	toilet = CollectionService:GetTagged(tags.GOLDEN_TOILET)

	CollectionService:GetInstanceAddedSignal(tags.LOBBYZONE):Connect(function(obj)
		table.insert(lobbyZone, obj)
	end)
	CollectionService:GetInstanceAddedSignal(tags.SPOT_TAG):Connect(function(obj)
		table.insert(spots, obj)
	end)
	CollectionService:GetInstanceAddedSignal(tags.GOLDEN_TOILET):Connect(function(obj)
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

function updateHumanoid(newval: number)
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
	if newval == 0 then
		-- Unfreeze player
		ContextActionService:UnbindAction(FREEZE_ACTION)

		hum.WalkSpeed = 16
		if lobbyZone then
			MovePlayersToLobbyCenter()
		end
	elseif newval > 0 then
		-- Freeze player
		ContextActionService:BindAction(FREEZE_ACTION, function()
			return Enum.ContextActionResult.Sink
		end, false, unpack(Enum.PlayerActions:GetEnumItems()))

		hum.WalkSpeed = 32
		local spot
		for _, lilSpot in ipairs(spots) do
			if lilSpot:GetAttribute("ArrayIndex") == newval then
				spot = lilSpot
				break
			end
		end

		if not spot then
			warn("Spot not found yikers")
			return
		end
		print("MY NEW SPOT: " .. spot:GetAttribute("ArrayIndex") .. " and newline is:  " .. newval)

		if prevLinePosition == 0 then
			hrp.CFrame = CFrame.new(spot.Position)
		else
			humanoidUtils.MoveTo(hum, spot.Position, function()
				hrp.CFrame = CFrame.new(Vector3.new(spot.Position.X, hrp.Position.Y, spot.Position.Z))
				local targetPart = toilet[1].PrimaryPart
				hrp:PivotTo(CFrame.lookAt(hrp.Position, targetPart.Position))
			end)
		end
	end
end

function startListen()
	linePosition.Changed:Connect(function(val)
		prevLinePosition = newLinePosition
		newLinePosition = linePosition.Value
		updateHumanoid(val)
	end)
end
startListen()
