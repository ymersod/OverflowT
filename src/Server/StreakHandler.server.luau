local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local streakFolder = ServerStorage:WaitForChild("Streaks"):GetChildren()

local function Cleanup(char: Model, head, torso)
	local aura = torso:FindFirstChildOfClass("Part")
	if aura then
		aura:Destroy()
	end

	local bb = head:FindFirstChildOfClass("BillboardGui")
	if bb then
		bb:Destroy()
	end
end

local function SetupAura(aura: Part, torso: MeshPart)
	local weld = Instance.new("WeldConstraint")

	aura.Position = torso.Position

	weld.Part0 = torso
	weld.Part1 = aura
	weld.Parent = aura

	for _, desc in ipairs(aura:GetDescendants()) do
		if desc:IsA("BasePart") then
			local nestedWeld = Instance.new("WeldConstraint")

			desc.Position = aura.Position
			nestedWeld.Part0 = aura
			nestedWeld.Part1 = desc

			nestedWeld.Parent = desc
		end
	end

	aura.Parent = torso
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

local function BBHandler(winStreakVal: number, player: Player)
	local char = player.Character :: Model?
	local head = char and char:FindFirstChild("Head") :: MeshPart?
	local torso = char and char:FindFirstChild("UpperTorso") :: MeshPart?

	if head and char and torso then
		local curStreak = torso:FindFirstChildOfClass("Part")

		local streakFound
		local curWinsReq = -1
		for _, streak in ipairs(streakFolder) do
			local winsReq: number? = streak:GetAttribute("WinStreakReq")
			if winsReq and winStreakVal >= winsReq and winsReq > curWinsReq then
				streakFound = streak
				curWinsReq = winsReq
			end
		end
		local auraPrefab = streakFound and streakFound:FindFirstChildOfClass("Part")

		if curStreak and curStreak.Name == auraPrefab.Name then
			print("Streak already on")
			return
		end

		Cleanup(char, head, torso)

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
			if not auraPrefab then
				if curWinsReq > 0 then
					warn("NO BB FOUND")
				end
				return
			end

			local auraClone = auraPrefab:Clone()
			SetupAura(auraClone, torso)
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
