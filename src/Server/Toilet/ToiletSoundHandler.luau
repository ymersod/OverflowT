local CollectionService = game:GetService("CollectionService")

local SoundHandler = {}

local MAX_VOLUME = 1
local MIN_VOLUME_FACTOR = 0.1

local ranges = {
	Soft = { min = 0.0, max = 0.25 },
	Medium = { min = 0.25, max = 0.55 },
	High = { min = 0.55, max = 0.95 },
}

local taggedSounds = {}
local soundExpl: Sound

function SoundHandler.FillSounds(curParticleObj: Instance)
	taggedSounds = {
		Soft = {},
		Medium = {},
		High = {},
	}

	for _, tag in ipairs({ "Soft", "Medium", "High", "Expl" }) do
		for _, obj in ipairs(CollectionService:GetTagged(tag)) do
			if obj:IsDescendantOf(curParticleObj) and tag == "Expl" then
				soundExpl = obj
			elseif obj:IsDescendantOf(curParticleObj) then
				table.insert(taggedSounds[tag], obj)
			end
		end
	end
end

local function getVolumeForRange(value, minRange, maxRange)
	local base = MAX_VOLUME * MIN_VOLUME_FACTOR
	if value <= minRange then
		return nil
	elseif value >= maxRange then
		return MAX_VOLUME
	else
		local t = (value - minRange) / (maxRange - minRange)
		return base + (MAX_VOLUME - base) * t
	end
end

function SoundHandler.Update(value: number)
	for name, group in pairs(taggedSounds) do
		local range = ranges[name]
		for _, sound in ipairs(group) do
			local vol = getVolumeForRange(value, range.min, range.max)
			if vol then
				if not sound.IsPlaying then
					sound.Looped = true
					sound:Play()
				end
				sound.Volume = vol
			else
				if sound.IsPlaying then
					sound:Stop()
				end
			end
		end
	end
end

function SoundHandler.Stop()
	for _, group in pairs(taggedSounds) do
		for _, sound in ipairs(group) do
			sound:Stop()
		end
	end
end

function SoundHandler.Reset()
	SoundHandler.Stop()
	for _, group in pairs(taggedSounds) do
		for _, sound in ipairs(group) do
			sound.TimePosition = 0
		end
	end
end

function SoundHandler.PlayClickExpl(value)
	soundExpl.Volume = value
	soundExpl:Play()
end

return SoundHandler
