local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local tags = require(ReplicatedStorage.Shared.tags)

-- BubbleTypes
local particles = ServerStorage:WaitForChild("ParticlesAndSounds"):WaitForChild("Particles"):GetChildren()
local sounds = ServerStorage:WaitForChild("ParticlesAndSounds"):WaitForChild("Sounds"):GetChildren()
local bubbleTypes: { Part } = ServerStorage:WaitForChild("ShopItems"):WaitForChild("BubbleTypes"):GetChildren()

local function SetParticleValues(particle: ParticleEmitter, color: Color3, parent: Instance)
	local particleClone = particle:Clone()
	particleClone.Color = ColorSequence.new(color)
	particleClone.Parent = parent
end

print("setting up bubbletypes...")
for _, bubbleType in ipairs(bubbleTypes) do
	if bubbleType:IsA("Part") then
		local particleSettings = bubbleType:FindFirstChildOfClass("IntValue")
		local foamSetting: Color3? = particleSettings and particleSettings:GetAttribute("Foam")
		local water1Setting: Color3? = particleSettings and particleSettings:GetAttribute("Water1")
		local water2Setting: Color3? = particleSettings and particleSettings:GetAttribute("Water2")

		if foamSetting and water1Setting and water2Setting then
			for _, particle in ipairs(particles) do
				if particle:IsA("ParticleEmitter") then
					if particle:HasTag(tags.FOAM_PARTICLE) then
						SetParticleValues(particle, foamSetting, bubbleType)
					elseif particle:HasTag(tags.WATER1_PARTICLE) then
						SetParticleValues(particle, water1Setting, bubbleType)
					elseif particle:HasTag(tags.WATER2_PARTICLE) then
						SetParticleValues(particle, water2Setting, bubbleType)
					end
				end
			end
		end

		for _, sound in ipairs(sounds) do
			if sound:IsA("Sound") then
				local soundClone = sound:Clone()
				soundClone.Parent = bubbleType
			end
		end
	end
end
