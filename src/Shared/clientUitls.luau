local TweenService = game:GetService("TweenService")
local uiConstants = require(script.Parent.uiConstants)
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("ScreenGui")
local WarningContainer = ScreenGui:WaitForChild("WarningContainer")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundEffectHandler = require(StarterPlayer.StarterPlayerScripts.Client.SoundEffectHandler)
local moneyAnimationEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("StatsEvents")
	:WaitForChild("MoneyAnimation")

local ClientUtils = {}

local function fadeOut(frame: Frame, fadeOutTime: number, Destroy: boolean?, callback: (() -> ())?)
	local fadeInfo = TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local bgTween = TweenService:Create(frame, fadeInfo, { BackgroundTransparency = 1 })
	bgTween:Play()

	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			TweenService:Create(obj, fadeInfo, { TextTransparency = 1 }):Play()
		elseif obj:IsA("UIStroke") then
			TweenService:Create(obj, fadeInfo, { Transparency = 1 }):Play()
		end
	end

	bgTween.Completed:Wait()

	if Destroy then
		frame:Destroy()
	else
		frame.Visible = false
		for _, obj in ipairs(frame:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				obj.TextTransparency = 0
			elseif obj:IsA("UIStroke") then
				obj.Transparency = 0
			end
		end
	end
	if callback then
		callback()
	end
end
function ClientUtils.showWarning(message)
	if not WarningContainer then
		warn("Warning container not found")
		return
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	frame.BackgroundTransparency = 0.1
	frame.ZIndex = 0
	frame.Parent = WarningContainer

	-- round corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = frame

	-- text label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.9, 0, 0.9, 0) -- padding inside the frame
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.BackgroundTransparency = 1
	label.Text = message or "⚠️ Game Cancelled!"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextWrapped = true
	label.Parent = frame
	SoundEffectHandler.Play("PopUp")

	fadeOut(frame, 3, true)
end

function ClientUtils.RainbowIfyText(gradient: UIGradient)
	gradient.Color = uiConstants.rainbowColorGradient
	while true do
		local tween =
			TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) })
		tween:Play()
		task.wait(2)
		gradient.Offset = Vector2.new(1, 0)
		local tween2 =
			TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Linear), { Offset = Vector2.new(0, 0) })
		tween2:Play()
		task.wait(2)
	end
end

function ClientUtils.PopFrame(
	frame: Frame,
	startPos: UDim2,
	targetSize: UDim2,
	targetPos: UDim2,
	time: number,
	fadeOutTime: number,
	callback: (() -> ())?
)
	frame.Visible = true
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Position = startPos

	local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local goal = { Size = targetSize, Position = targetPos }
	local tween = TweenService:Create(frame, tweenInfo, goal)
	tween:Play()

	return function()
		fadeOut(frame, fadeOutTime, false, callback)
	end
end

function ClientUtils.TypewriterLabel(label: TextLabel, text: string, speed: number, callback: (() -> ())?)
	label.Text = ""
	label.Visible = true
	label.RichText = true

	task.spawn(function()
		for i = 1, #text do
			label.Text = string.sub(text, 1, i)
			task.wait(speed)
		end
		if callback then
			callback()
		end
	end)
end

function ClientUtils.PulseFrame(frame: Frame, pulseScale: number, pulseUp: number, pulseWait: number, pulseDown: number)
	local originalSize = frame.Size

	local upTweenInfo = TweenInfo.new(pulseUp, Enum.EasingStyle.Linear)
	local upGoal = {
		Size = UDim2.new(
			originalSize.X.Scale * pulseScale,
			originalSize.X.Offset,
			originalSize.Y.Scale * pulseScale,
			originalSize.Y.Offset
		),
	}
	local upTween = TweenService:Create(frame, upTweenInfo, upGoal)
	upTween:Play()

	upTween.Completed:Connect(function()
		task.delay(pulseWait, function()
			local downTweenInfo = TweenInfo.new(pulseDown, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local downGoal = { Size = originalSize }
			local downTween = TweenService:Create(frame, downTweenInfo, downGoal)
			downTween:Play()
		end)
	end)
end

function ClientUtils.CountUpNumberLabel(
	label: TextLabel,
	text: string,
	startValue: number,
	endValue: number,
	duration: number,
	doPulse: boolean?,
	pulseScale: number?,
	pulseDownDuration: number?,
	pulseUpDuration: number?
)
	task.spawn(function()
		local difference = endValue - startValue
		if difference == 0 then
			label.Text = text .. endValue
			return
		end

		local steps = 60
		local stepDelay = duration / steps
		local stepAmount = difference / steps
		local current = startValue

		if doPulse and pulseScale and pulseDownDuration and pulseUpDuration then
			pulseScale = pulseScale or 1.3
			pulseDownDuration = pulseDownDuration or 0.3
			local parent = label.Parent
			if parent and parent:IsA("Frame") then
				ClientUtils.PulseFrame(parent, pulseScale, pulseUpDuration, duration, pulseDownDuration)
			end
		end

		-- count the number
		for i = 1, steps do --Mod 10 call server event, money animation
			if i % 6 == 0 then
				print("got here")
				moneyAnimationEvent:FireServer()
			end
			current = current + stepAmount
			label.Text = text .. math.floor(current)
			task.wait(stepDelay)
		end

		label.Text = text .. endValue -- ensure exact final value
	end)
end

function ClientUtils.PopFrameElastic(
	frame: Frame,
	targetSize: UDim2,
	duration: number,
	fadeOutTime: number,
	destroy: boolean?,
	callback: (() -> ())?
)
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Visible = true

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local goal = { Size = targetSize }
	local tween = TweenService:Create(frame, tweenInfo, goal)
	tween:Play()

	return function()
		fadeOut(frame, fadeOutTime, destroy, callback)
	end
end

return ClientUtils
