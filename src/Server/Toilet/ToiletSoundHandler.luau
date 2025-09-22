local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tags = require(ReplicatedStorage.Shared.tags)
local CollectionService = game:GetService("CollectionService")

local SoundHandler = {}

local MAX_VOLUME = 1
local MIN_VOLUME_FACTOR = 0.1

local ranges = {
	Soft = { min = 0.0, max = 0.25 },
	Medium = { min = 0.25, max = 0.55 },
	High = { min = 0.55, max = 0.95 },
}

local closeToEndSounds = CollectionService:GetTagged(tags.BREAKING_SOUND)
print(closeToEndSounds)
local stickySounds = {}
local STICKY_MIN, STICKY_MAX = 0.01, 0.98

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

function StickyValueUpdate(value: number) --0 to fade out, should be a bool...
	for _, sound in ipairs(closeToEndSounds) do
		local vol = getVolumeForRange(value, STICKY_MIN, STICKY_MAX)

		if vol then
			-- cancel any ongoing fade
			if stickySounds[sound] then
				stickySounds[sound].token = nil
			else
				stickySounds[sound] = { lastVolume = vol }
			end

			if not sound.IsPlaying then
				sound.Looped = true
				sound:Play()
			end

			sound.Volume = vol
			stickySounds[sound].lastVolume = vol
		else
			if stickySounds[sound] and not stickySounds[sound].token then
				local token = {}
				stickySounds[sound].token = token
				local startVolume = sound.Volume

				task.spawn(function()
					local duration, steps = 0.8, 20
					local waitTime = duration / steps

					for i = 1, steps do
						task.wait(waitTime)
						if stickySounds[sound].token ~= token then
							return -- canceled by new update
						end
						sound.Volume = startVolume * (1 - i / steps)
					end

					if stickySounds[sound].token == token then
						stickySounds[sound].lastVolume = startVolume
						sound:Stop()
						stickySounds[sound] = nil
					end
				end)
			end
		end
	end
end

function SoundHandler.Update(value: number)
	StickyValueUpdate(value)
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
	StickyValueUpdate(0) --0... fate out
	for _, group in pairs(taggedSounds) do
		for _, sound in ipairs(group) do
			sound:Stop()
		end
	end
end

function SoundHandler.Reset()
	StickyValueUpdate(0) --0... fade out
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
