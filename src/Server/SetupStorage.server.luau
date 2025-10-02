local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local tags = require(ReplicatedStorage.Shared.tags)

-- BubbleTypes
local particles = ServerStorage:WaitForChild("ParticlesAndSounds"):WaitForChild("Particles"):GetChildren()
local sounds = ServerStorage:WaitForChild("ParticlesAndSounds"):WaitForChild("Sounds"):GetChildren()
local bubbleTypes: { Part } = ServerStorage:WaitForChild("ShopItems"):WaitForChild("BubbleTypes"):GetChildren()

local function SetParticleValues(particle: ParticleEmitter, color: ColorSequence, texture: string, parent: Instance)
	local particleClone = particle:Clone()
	particleClone.Texture = texture
	particleClone.Color = color
	particleClone.Parent = parent
end

print("setting up bubbletypes...")
for _, bubbleType in ipairs(bubbleTypes) do
	if bubbleType:IsA("Part") then
		local particleSettings = bubbleType:FindFirstChildOfClass("IntValue")
		local foamSetting: ColorSequence? = particleSettings and particleSettings:GetAttribute("FoamColor")
		local water1Setting: ColorSequence? = particleSettings and particleSettings:GetAttribute("Water1Color")
		local water2Setting: ColorSequence? = particleSettings and particleSettings:GetAttribute("Water2Color")
		local foamTexture: string? = particleSettings and particleSettings:GetAttribute("FoamTexture")
		local water1Texture: string? = particleSettings and particleSettings:GetAttribute("Water1Texture")
		local water2Texture: string? = particleSettings and particleSettings:GetAttribute("Water2Texture")

		if foamSetting and water1Setting and water2Setting and foamTexture and water1Texture and water2Texture then
			for _, particle in ipairs(particles) do
				if particle:IsA("ParticleEmitter") then
					if particle:HasTag(tags.FOAM_PARTICLE) then
						SetParticleValues(particle, foamSetting, foamTexture, bubbleType)
					elseif particle:HasTag(tags.WATER1_PARTICLE) then
						SetParticleValues(particle, water1Setting, water1Texture, bubbleType)
					elseif particle:HasTag(tags.WATER2_PARTICLE) then
						SetParticleValues(particle, water2Setting, water2Texture, bubbleType)
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
