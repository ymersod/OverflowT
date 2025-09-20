--local Rumble = require(game.ServerScriptService.Server.Toilet.RumbleAnimation)

local CollectionService = game:GetService("CollectionService")
--local toiletLid = CollectionService:GetTagged("ToiletLid")[1]
--local toiletSeat = CollectionService:GetTagged("ToiletSeat")[1]
--local toiletBody = CollectionService:GetTagged("ToiletBody")[1]
local particles = CollectionService:GetTagged("WaterParticleActive")[1]

local function SetParticlesEnabled(enabled: boolean)
	for _, descendant in ipairs(particles:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = enabled
		end
	end
end

--Rumble.Vertical(toiletLid, 9, 0.1)
--Rumble.Vertical(toiletBody, 0.5, 0.1)
--Rumble.Horizontal(toiletSeat, 7, 0.2)
--SetParticlesEnabled(true)

task.delay(10, function()
	--print("Stopping rumble after 20s")
	--Rumble.Stop(toiletLid)
	--Rumble.Stop(toiletSeat)
	--Rumble.Stop(toiletBody)
	--SetParticlesEnabled(false)
end)
