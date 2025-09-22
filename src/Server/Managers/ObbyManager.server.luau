local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local tags = require(ReplicatedStorage.Shared.tags)
local clientRespawnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("RespawnToObby")

-- Tagged objects
local runtimeObbyFolder: Folder = ReplicatedStorage:WaitForChild("ObbyRuntimeStorage")
local obbySignText: TextLabel = CollectionService:GetTagged(tags.OBBY_STATE_TEXT)[1]
local resetFallBlock: Part = CollectionService:GetTagged(tags.FALL_RESET_BLOCK)[1]
local respawnPos: Part = CollectionService:GetTagged(tags.RESPAWN_POS)[1]
local obbyLevels: { Folder } = CollectionService:GetTagged(tags.OBBY_LEVEL)
for _, obbyLevel in ipairs(obbyLevels) do
	obbyLevel.Parent = runtimeObbyFolder
end

local obbyWorkSpaceFolder: Folder = CollectionService:GetTagged(tags.OBBY_FOLDER)[1]
-- runtimeObbyFolder = ReplicatedStorage:WaitForChild("ObbyRuntimeStorage") -- I think we have to it again to update reference

local OBBY_ACTIVE_TIME_CAP = 10
local curTimeAlive = 0
local lastOsCheck = os.clock()

local function CheckForPlayer(hit): Player?
	if hit and hit.Parent and hit.Parent:IsA("Model") then
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			return player
		end
	end
	return nil
end

local function TelePortPlayer(player: Player)
	clientRespawnEvent:FireClient(player, respawnPos.Position)
end

local function SetupConnection(part: BasePart, mode: "Kill" | "Win")
	local playerDebounce = {}

	part.Touched:Connect(function(hit)
		local player = CheckForPlayer(hit)
		if not player then
			return
		end

		if playerDebounce[player] then
			return
		end
		playerDebounce[player] = true

		TelePortPlayer(player)
		if mode == "Win" then
			print(player.Name .. " won!")
		end

		task.delay(0.5, function()
			playerDebounce[player] = nil
		end)
	end)
end

local function SpawnObby()
	local obby = #runtimeObbyFolder:GetChildren() > 0 and runtimeObbyFolder:GetChildren()[1]

	if obby then
		local obbyClone = obby:Clone() :: Instance
		obbyClone.Parent = obbyWorkSpaceFolder

		local obbyDescendants = obbyClone:GetDescendants()

		for _, desc in ipairs(obbyDescendants) do
			if desc:IsA("BasePart") and desc:HasTag(tags.RESET_BLOCK) then
				SetupConnection(desc, "Kill")
			elseif desc:IsA("BasePart") and desc:HasTag(tags.TROPHY_COL) then
				SetupConnection(desc, "Win")
			end
		end
	else
		warn("No obbys found in folder!!")
	end
end

local function DespawnObby(obby: Instance)
	obby:Destroy()
end

local function Start()
	SpawnObby()
	SetupConnection(resetFallBlock, "Kill")

	RunService.Heartbeat:Connect(function()
		curTimeAlive += os.clock() - lastOsCheck
		lastOsCheck = os.clock()

		if curTimeAlive >= OBBY_ACTIVE_TIME_CAP then
			curTimeAlive = 0

			local curObbyLevel
			for _, obj in ipairs(obbyWorkSpaceFolder:GetChildren()) do
				if obj:HasTag(tags.OBBY_LEVEL) then
					curObbyLevel = obj
				end
			end
			if curObbyLevel then
				DespawnObby(curObbyLevel)
				SpawnObby()
			else
				warn("Didnt find obby to despawn??")
			end
		end
		obbySignText.Text = "Next obby spawning in: " .. math.floor(OBBY_ACTIVE_TIME_CAP - curTimeAlive)
	end)
end
Start()
