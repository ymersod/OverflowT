local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local soundHandler = require(ReplicatedStorage.Shared.SoundEffectHandler)
local tags = require(ReplicatedStorage.Shared.tags)

type SoundName = soundHandler.SoundName
type eventType = "Hover" | "Visible" | "Pressed"

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
	componentList = {}
	insert("UniversalButtonHover", CollectionService:GetTagged(tags.Sound_On_Hover), "Hover")
	insert("UniversalButtonClick", CollectionService:GetTagged(tags.Sound_On_Click), "Pressed")
	insert("WinRound", CollectionService:GetTagged(tags.Sound_On_Visible_Win), "Visible")
	insert("LoseRound", CollectionService:GetTagged(tags.Sound_On_Visible_Lose), "Visible")
	for i = 1, #componentList do
		local soundName = componentList[i].soundName
		local components = componentList[i].components
		local event = componentList[i].event

		print(event)
		for j = 1, #components do
			local current = components[j]

			if event == "Hover" then
				current.MouseEnter:Connect(function()
					soundHandler.Play(soundName)
				end)
			end
			if event == "Pressed" then
				-- print("Setting up event for: ", current)
				current.MouseButton1Down:Connect(function()
					soundHandler.Play(soundName)
				end)
			end
			if event == "Visible" then
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

player.CharacterAdded:Connect(function()
	soundHandler.Play("Teleport")
end)

playerGui.ChildAdded:Connect(function(newGui)
	print("New Gui added:", newGui.Name)
	hookEvents()
end)
