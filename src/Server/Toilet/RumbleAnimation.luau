local TweenService = game:GetService("TweenService")

local Rumble = {}
local activeRumbles = {}

local function rumble(obj: BasePart, axis: "X" | "Y", angle: number, speed: number)
	Rumble.Stop(obj)

	local state = {
		angle = angle,
		speed = speed,
		stopFlag = false,
		tween = nil,
	}

	activeRumbles[obj] = state

	local originalCF = obj.CFrame

	task.spawn(function()
		while not state.stopFlag do
			local rotOffset = (axis == "X" and CFrame.Angles(math.rad(state.angle), 0, 0))
				or CFrame.Angles(0, math.rad(state.angle), 0)

			local tween1 = TweenService:Create(
				obj,
				TweenInfo.new(state.speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = originalCF * rotOffset }
			)
			state.tween = tween1
			tween1:Play()
			tween1.Completed:Wait()
			if state.stopFlag then
				break
			end

			local tween2 = TweenService:Create(
				obj,
				TweenInfo.new(state.speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = originalCF }
			)
			state.tween = tween2
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
		activeRumbles[obj].stopFlag = true
		activeRumbles[obj].tween:Cancel()
	end
end

function Rumble.SetAngle(obj: BasePart, newAngle: number)
	if activeRumbles[obj] then
		activeRumbles[obj].angle = newAngle
	end
end

function Rumble.SetSpeed(obj: BasePart, newSpeed: number)
	if activeRumbles[obj] then
		activeRumbles[obj].speed = newSpeed
	end
end

return Rumble
