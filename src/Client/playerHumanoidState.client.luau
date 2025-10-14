local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local StarterPlayer = game:GetService("StarterPlayer")

local FREEZE_ACTION = "freezeMovement"

local SoundEffectHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local actionGuiState = require(script.Parent.actionGuiState)
local humanoidUtils = require(ReplicatedStorage.Shared.humanoidUtils)
local tags = require(ReplicatedStorage.Shared.tags)

local linePosition: IntValue = Player:WaitForChild("States"):WaitForChild("LinePosition")
local ragdolledValue: IntValue = Player:WaitForChild("States"):WaitForChild("Ragdolled")
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

local function MovePlayersToSpawn()
	local character = Player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart

		local spawn = Player.RespawnLocation or workspace:FindFirstChild("SpawnLocation")
		if spawn then
			local targetPos = spawn.Position
			hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))

			task.delay(0.2, function()
				if (hrp.Position - targetPos).Magnitude > 5 then
					hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
				end
			end)
		end
	end
end

local isInLine: boolean = false

local function placeInLine(lineNr)
	local char = Player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char.PrimaryPart

	ContextActionService:BindAction(FREEZE_ACTION, function()
		return Enum.ContextActionResult.Sink
	end, false, unpack(Enum.PlayerActions:GetEnumItems()))

	hum.WalkSpeed = 24
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
	print("MY NEW SPOT: " .. spot:GetAttribute("ArrayIndex") .. " and newline is:  " .. lineNr)
	hrp.CFrame = CFrame.new(spot.Position + Vector3.new(0, 3, 0))
	SoundEffectHandler.Play("Teleport")
	isInLine = true
end

local function removeFromLine(lineNr)
	local char = Player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	print("MY NEW SPOT: " .. lineNr)
	-- Unfreeze player
	ContextActionService:UnbindAction(FREEZE_ACTION)

	hum.WalkSpeed = 16
	task.defer(MovePlayersToSpawn)
	isInLine = false
end

local prevMover = nil

local function moveInLine(lineNr)
	local char = Player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char.PrimaryPart
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

	prevMover = humanoidUtils.MoveTo(hum, spot.Position, function()
		hrp.CFrame = CFrame.new(Vector3.new(spot.Position.X, hrp.Position.Y, spot.Position.Z))
		local targetPart = toilet[1].PrimaryPart
		hrp:PivotTo(CFrame.lookAt(hrp.Position, targetPart.Position))
		task.spawn(function()
			task.wait(0.1)
			actionGuiState.updateGUI(lineNr)
		end)
	end)
end

local pendingValue = nil

function processLineChange(newValue)
	if newValue > 0 and prevLinePosition == 0 and not isInLine then
		placeInLine(newValue)
	elseif newValue == 0 and prevLinePosition > 0 and isInLine then
		removeFromLine(newValue)
	elseif isInLine and newValue ~= 0 and newValue ~= prevLinePosition then
		moveInLine(newValue)
	end
	actionGuiState.updateGUI(newValue)
	prevLinePosition = newValue
end

processLineChange(linePosition.Value)
linePosition:GetPropertyChangedSignal("Value"):Connect(function()
	local newValue = linePosition.Value
	if ragdolledValue.Value then
		pendingValue = newValue
		return
	end
	processLineChange(newValue)
end)

ragdolledValue.Changed:Connect(function(isRagdolled)
	if not isRagdolled and pendingValue ~= nil then
		processLineChange(pendingValue)
		pendingValue = nil
	end
end)
