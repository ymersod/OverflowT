local TweenService = game:GetService("TweenService")

local Rumble = {}
local activeRumbles = {}

local function rumble(obj: BasePart, axis: "X" | "Y", angle: number, speed: number)
	Rumble.Stop(obj)

	local stopFlag = false
	activeRumbles[obj] = function()
		stopFlag = true
	end

	local originalCF = obj.CFrame

	task.spawn(function()
		while not stopFlag do
			local rotOffset = (axis == "X" and CFrame.Angles(math.rad(angle), 0, 0))
				or CFrame.Angles(0, math.rad(angle), 0)

			local tween1 = TweenService:Create(
				obj,
				TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = originalCF * rotOffset }
			)
			tween1:Play()
			tween1.Completed:Wait()
			if stopFlag then
				break
			end

			local tween2 = TweenService:Create(
				obj,
				TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = originalCF }
			)
			tween2:Play()
			tween2.Completed:Wait()
		end

		obj.CFrame = originalCF
		activeRumbles[obj] = nil
	end)
end

function Rumble.Horizontal(obj: BasePart, amplitude: number, speed: number)
	rumble(obj, "X", amplitude, speed)
end

function Rumble.Vertical(obj: BasePart, amplitude: number, speed: number)
	rumble(obj, "Y", amplitude, speed)
end

function Rumble.Stop(obj: BasePart)
	if activeRumbles[obj] then
		activeRumbles[obj]()
		activeRumbles[obj] = nil
	end
end

return Rumble
