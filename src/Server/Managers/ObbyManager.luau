local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Stats = require(ServerScriptService.Server.Persistence.Stats)
local serverUtils = require(ServerScriptService.Server.serverUtils)
local tags = require(ReplicatedStorage.Shared.tags)
local uiConstants = require(ReplicatedStorage.Shared.uiConstants)
local clientRespawnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ClientEvents")
	:WaitForChild("RespawnToObby")
local UpdateStatsEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("StatsEvents")
	:WaitForChild("UpdateStats")
local clientWinEvent =
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ClientEvents"):WaitForChild("ObbyWin")

-- Tagged objects
local runtimeObbyFolder: Folder = ReplicatedStorage:WaitForChild("ObbyRuntimeStorage")
local obbySignText: TextLabel = CollectionService:GetTagged(tags.OBBY_STATE_TEXT)[1]
local obbyLevelText: TextLabel = CollectionService:GetTagged(tags.OBBY_LEVEL_TEXT)[1]
local resetFallBlock: Part = CollectionService:GetTagged(tags.FALL_RESET_BLOCK)[1]
local respawnPos: Part = CollectionService:GetTagged(tags.RESPAWN_POS)[1]

local obbyWorkSpaceFolder: Folder = CollectionService:GetTagged(tags.OBBY_FOLDER)[1]

local OBBY_ACTIVE_TIME_CAP = 120
local curTimeAlive = 0
local lastOsCheck = os.clock()

local obbyManager = {}

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

local function SetupConnection(part: BasePart, mode: "Kill" | "Win", winPrize: number?)
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
			local winningPrize = winPrize and winPrize or 10
			clientWinEvent:FireClient(player, winningPrize)
		end

		task.delay(0.5, function()
			playerDebounce[player] = nil
		end)
	end)
end
local rainbowLoopRunning = false
function obbyManager.SpawnObby(obbyId: number)
	local obby
	for _, runtimeObby in ipairs(runtimeObbyFolder:GetChildren()) do
		local obbyAtrrId = runtimeObby:GetAttribute("ObbyId")

		if obbyAtrrId and tostring(obbyAtrrId) == tostring(obbyId) then
			obby = runtimeObby
		end
	end

	if obby then
		local difficulity: "EASY" | "MEDIUM" | "HARD" | "OP"? = obby:GetAttribute("ObbyDifficulity")
		local winPrize: number? = obby:GetAttribute("WinPrize")
		local color: Color3? = difficulity and uiConstants.difficultyColors[difficulity]
			or uiConstants.difficultyColors.FALLBACK
		local obbyClone = obby:Clone() :: Instance
		obbyClone.Parent = obbyWorkSpaceFolder

		for _, desc in ipairs(obbyClone:GetDescendants()) do
			if desc:IsA("BasePart") and desc:HasTag(tags.RESET_BLOCK) and difficulity then
				SetupConnection(desc, "Kill")
			elseif desc:IsA("BasePart") and desc:HasTag(tags.TROPHY_COL) and difficulity then
				SetupConnection(desc, "Win", winPrize)
			end
		end

		rainbowLoopRunning = false
		if difficulity and color then
			local hex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
			obbyLevelText.RichText = true
			obbyLevelText.Text = string.format('Level [<font color="%s">%s</font>]', hex, difficulity)

			if difficulity == "OP" then
				rainbowLoopRunning = true
				task.spawn(function()
					local i = 1
					while rainbowLoopRunning do
						local gColor = uiConstants.rainbowColor[i]
						local gHex = string.format("#%02X%02X%02X", gColor.R * 255, gColor.G * 255, gColor.B * 255)

						obbyLevelText.RichText = true
						obbyLevelText.Text = string.format('Level [<font color="%s">%s</font>]', gHex, difficulity)

						i = (i % #uiConstants.rainbowColor) + 1
						task.wait(0.2)
					end
				end)
			end
		end
	else
		warn("No obbys found in folder!!")
	end
end
function obbyManager.DespawnObbys()
	local curObbyLevel: { Instance } = {}
	for _, obj in ipairs(obbyWorkSpaceFolder:GetChildren()) do
		if obj:HasTag(tags.OBBY_LEVEL) then
			table.insert(curObbyLevel, obj)
		end
	end
	if curObbyLevel and #curObbyLevel > 0 then
		for _, obby in curObbyLevel do
			obby:Destroy()
		end
	else
		warn("Didnt find obby(s) to despawn??")
	end
end

UpdateStatsEvent.OnServerEvent:Connect(function(player, toAdd: number)
	serverUtils.modifyPlayerLeaderStats(tostring(player.UserId), "Money", toAdd)
	task.spawn(function()
		Stats.UpdatePlayerStats(tostring(player.UserId), function(currentStats)
			currentStats.Coins += toAdd
			currentStats.Wins += 0
			return currentStats
		end)
	end)
end)

local function Start()
	SetupConnection(resetFallBlock, "Kill")

	RunService.Heartbeat:Connect(function()
		curTimeAlive += os.clock() - lastOsCheck
		lastOsCheck = os.clock()

		if curTimeAlive >= OBBY_ACTIVE_TIME_CAP then
			curTimeAlive = 0

			obbyManager.DespawnObbys()
			local obbysCount = #runtimeObbyFolder:GetChildren()
			if obbysCount and obbysCount > 0 then
				obbyManager.SpawnObby(math.random(1, obbysCount))
			else
				warn("Didnt find any obbys in storage")
			end
		end
		obbySignText.Text = "Next obby spawning in: " .. math.floor(OBBY_ACTIVE_TIME_CAP - curTimeAlive)
	end)
end
obbyManager.SpawnObby(2)
Start()

return obbyManager
