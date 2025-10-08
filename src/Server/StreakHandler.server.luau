local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local streakFolder = ServerStorage:WaitForChild("Streaks"):GetChildren()

local cleanupCache: { [string]: { Instance } } = {}
local function Cleanup(userId: string, head: Model)
	local bb = head:FindFirstChildOfClass("BillboardGui")
	if bb then
		bb:Destroy()
	end

	local localCache = cleanupCache[userId]
	if localCache then
		for _, item in ipairs(localCache) do
			item:Destroy()
		end
	end
	cleanupCache[userId] = {}
end

local function SetCorrToR16(r6Name: string, item: Instance, char: Model, setPos: boolean?, useSubParts: boolean?)
	local newParents = {}

	if r6Name == "Head" then
		newParents = { char:FindFirstChild("Head") }
	elseif r6Name == "HumanoidRootPart" then
		newParents = { char:FindFirstChild("HumanoidRootPart") }
	elseif r6Name == "Left Arm" then
		if useSubParts then
			newParents = {
				char:FindFirstChild("LeftUpperArm"),
				char:FindFirstChild("LeftLowerArm"),
				char:FindFirstChild("LeftHand"),
			}
		else
			newParents = { char:FindFirstChild("LeftUpperArm") }
		end
	elseif r6Name == "Right Arm" then
		if useSubParts then
			newParents = {
				char:FindFirstChild("RightUpperArm"),
				char:FindFirstChild("RightLowerArm"),
				char:FindFirstChild("RightHand"),
			}
		else
			newParents = { char:FindFirstChild("RightUpperArm") }
		end
	elseif r6Name == "Left Leg" then
		if useSubParts then
			newParents = {
				char:FindFirstChild("LeftUpperLeg"),
				char:FindFirstChild("LeftLowerLeg"),
				char:FindFirstChild("LeftFoot"),
			}
		else
			newParents = { char:FindFirstChild("LeftUpperLeg") }
		end
	elseif r6Name == "Right Leg" then
		if useSubParts then
			newParents = {
				char:FindFirstChild("RightUpperLeg"),
				char:FindFirstChild("RightLowerLeg"),
				char:FindFirstChild("RightFoot"),
			}
		else
			newParents = { char:FindFirstChild("RightUpperLeg") }
		end
	elseif r6Name == "Torso" then
		if useSubParts then
			newParents = {
				char:FindFirstChild("UpperTorso"),
				char:FindFirstChild("LowerTorso"),
			}
		else
			newParents = { char:FindFirstChild("UpperTorso") }
		end
	end

	for _, newParent in ipairs(newParents) do
		if newParent then
			local clone = item:Clone()
			clone.Parent = newParent

			if setPos and clone:IsA("BasePart") then
				clone.Position = newParent.Position

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = newParent
				weld.Part1 = clone
				weld.Parent = clone
			end
		else
			warn("Could not find R15 subpart for R6 part:", r6Name)
		end
	end
end

local function SetupAura(aura: Model, char: Model, userId: string, useSubParts: boolean?)
	cleanupCache[userId] = cleanupCache[userId] or {}

	for _, auraDesc in ipairs(aura:GetDescendants()) do
		if
			(auraDesc:IsA("ParticleEmitter") or auraDesc:IsA("Attachment") or auraDesc:IsA("Beam"))
			and auraDesc.Parent
			and auraDesc.Parent:IsA("Part")
		then
			SetCorrToR16(auraDesc.Parent.Name, auraDesc, char, false, useSubParts)
			for _, p in ipairs(char:GetDescendants()) do
				if p.Name == auraDesc.Name and not table.find(cleanupCache[userId], p) then
					table.insert(cleanupCache[userId], p)
				end
			end
		elseif auraDesc:IsA("Part") and auraDesc.Parent and auraDesc.Parent:IsA("Part") then
			SetCorrToR16(auraDesc.Parent.Name, auraDesc, char, true, useSubParts)
			for _, p in ipairs(char:GetDescendants()) do
				if p.Name == auraDesc.Name and not table.find(cleanupCache[userId], p) then
					table.insert(cleanupCache[userId], p)
				end
			end
		end
	end
end

local function SetBBProperties(bbClone: BillboardGui, winStreakVal: number)
	local streakFrame = bbClone:FindFirstChild("StreakFrame")
	local streakText: TextLabel? = streakFrame and streakFrame:FindFirstChild("StreakText")

	local streakName = bbClone:FindFirstChild("StreakName")
	local streakNameText: TextLabel? = streakName and streakName:FindFirstChild("StreakNameText")
	local streakNameGradient: UIGradient? = streakNameText and streakNameText:FindFirstChildOfClass("UIGradient")

	if not streakText or not streakNameText or not streakNameGradient then
		warn("BB Children not found")
		return
	end

	streakText.Text = `Winstreak: {winStreakVal}`
end

local activeAura: { [string]: { Aura: number } } = {}
local function BBHandler(winStreakVal: number, player: Player)
	local char = player.Character :: Model?
	local head = char and char:FindFirstChild("Head") :: MeshPart?
	local torso = char and char:FindFirstChild("UpperTorso") :: MeshPart?

	if head and char and torso then
		local streakFound
		local curWinsReq = -1
		for _, streak in ipairs(streakFolder) do
			local winsReq: number? = streak:GetAttribute("WinStreakReq")
			if winsReq and winStreakVal >= winsReq and winsReq > curWinsReq then
				streakFound = streak
				curWinsReq = winsReq
			end
		end

		if activeAura[tostring(player.UserId)] and activeAura[tostring(player.UserId)].Aura == curWinsReq then
			print("Streak already on")
			return
		end
		activeAura[tostring(player.UserId)] = { Aura = curWinsReq }

		Cleanup(tostring(player.UserId), head)

		if not streakFound then
			warn("STREAK IN SERVERSTORAGE NOT FOUND")
			return
		end

		-- BB Stuff
		task.spawn(function()
			local bbPrefab = streakFound:FindFirstChildOfClass("BillboardGui")

			if not bbPrefab then
				warn("NO BB FOUND")
				return
			end

			local bbClone = bbPrefab:Clone()
			SetBBProperties(bbClone, winStreakVal)
			bbClone.Parent = head
			bbClone.Adornee = head
		end)

		-- Aura stuff
		task.spawn(function()
			local auraPrefab = streakFound and streakFound:FindFirstChildOfClass("Model")
			if not auraPrefab then
				if curWinsReq > 0 then
					warn("NO BB FOUND")
				end
				return
			end

			SetupAura(auraPrefab, char, tostring(player.UserId), streakFound:GetAttribute("useSubParts"))
		end)
	else
		warn("Could not find model or head")
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local winStreakIntValue: IntValue? = player:WaitForChild("leaderstats"):WaitForChild("WinStreak")
		local curValue = winStreakIntValue and winStreakIntValue.Value

		if curValue and winStreakIntValue then
			BBHandler(curValue, player)

			winStreakIntValue.Changed:Connect(function(newVal)
				BBHandler(newVal, player)
			end)
		else
			warn("Didnt find winstreak intvalue")
		end
	end)
end)
