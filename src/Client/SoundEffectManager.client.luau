local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local tags = require(ReplicatedStorage.Shared.tags)
local soundHandler = require(StarterPlayer.StarterPlayerScripts.Client.SoundEffectHandler)

type SoundName = soundHandler.SoundName
type eventType = "Click" | "Hover" | "Visible" | "Pressed"

type componentListType = {
	soundName: SoundName,
	components: { Instance },
	event: eventType,
}

local componentList: { componentListType } = {}

local function insert(soundName: SoundName, components: { Instance }, eventType: eventType)
	table.insert(componentList, { soundName = soundName, components = components, event = eventType })
end

local processedComponents = {}

local function hookEvents()
	componentList = {}

	insert("UniversalButtonHover", CollectionService:GetTagged(tags.Sound_On_Hover), "Hover")
	insert("UniversalButtonClick", CollectionService:GetTagged(tags.Sound_On_Click), "Click")
	insert("WinRound", CollectionService:GetTagged(tags.Sound_On_Visible_Win), "Visible")
	insert("LoseRound", CollectionService:GetTagged(tags.Sound_On_Visible_Lose), "Visible")

	for i = 1, #componentList do
		local soundName = componentList[i].soundName
		local components = componentList[i].components
		local event = componentList[i].event

		for j = 1, #components do
			local current = components[j]

			if processedComponents[current] then
				continue
			end
			processedComponents[current] = true

			if event == "Click" then
				current.MouseButton1Click:Connect(function()
					soundHandler.Play(soundName)
				end)
			elseif event == "Hover" then
				current.MouseEnter:Connect(function()
					soundHandler.Play(soundName)
				end)
			elseif event == "Pressed" then
				current.MouseButton1Down:Connect(function()
					soundHandler.Play(soundName)
				end)
			elseif event == "Visible" then
				current:GetPropertyChangedSignal("Visible"):Connect(function()
					if current.Visible then
						soundHandler.Play(soundName)
					end
				end)
			end
		end
	end
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

playerGui.ChildAdded:Connect(function(newGui)
	print("New Gui added:", newGui.Name)
	hookEvents()
end)
