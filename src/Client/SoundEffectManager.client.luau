local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local tags = require(ReplicatedStorage.Shared.tags)
local soundHandler = require(StarterPlayer.StarterPlayerScripts.Client.SoundEffectHandler)

type SoundName = soundHandler.SoundName
type eventType = "Click" | "Hover" | "Visible"

type componentListType = {
	soundName: SoundName,
	components: { Instance },
	event: eventType,
}

local componentList: { componentListType } = {}

local function insert(soundName: SoundName, components: { Instance }, eventType: eventType)
	table.insert(componentList, { soundName = soundName, components = components, event = eventType })
end

local function hookEvents()
	componentList = {} -- reset list before refilling

	insert("UniversalButtonHover", CollectionService:GetTagged(tags.Sound_On_Hover), "Hover")
	insert("UniversalButtonClick", CollectionService:GetTagged(tags.Sound_On_Click), "Click")
	insert("WaterPourClick", CollectionService:GetTagged(tags.Sound_On_Click_Flush), "Click")
	insert("WinRound", CollectionService:GetTagged(tags.Sound_On_Visible_Win), "Visible")
	insert("LoseRound", CollectionService:GetTagged(tags.Sound_On_Visible_Lose), "Visible")

	for i = 1, #componentList do
		local soundName = componentList[i].soundName
		local components = componentList[i].components
		local event = componentList[i].event

		if event == "Click" then
			for j = 1, #components do
				local current = components[j]
				if current:IsA("GuiButton") then
					current.MouseButton1Click:Connect(function()
						soundHandler.Play(soundName)
					end)
				end
			end
		elseif event == "Hover" then
			for j = 1, #components do
				local current = components[j]
				if current:IsA("GuiObject") then
					current.MouseEnter:Connect(function()
						soundHandler.Play(soundName)
					end)
				end
			end
		elseif event == "Visible" then
			for j = 1, #components do
				local current = components[j]
				if current:IsA("GuiObject") then
					current:GetPropertyChangedSignal("Visible"):Connect(function()
						if current.Visible then
							soundHandler.Play(soundName)
						end
					end)
				end
			end
		end
	end
end

-- run once
hookEvents()

-- re-run whenever a new gui gets added
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

playerGui.ChildAdded:Connect(function(newGui)
	print("New Gui added:", newGui.Name)
	hookEvents()
end)
