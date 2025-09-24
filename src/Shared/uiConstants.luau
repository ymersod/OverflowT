local uiUtils = {
	rainbowColorGradient = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.111, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.222, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.333, Color3.fromRGB(127, 255, 0)), -- Yellow-Green
		ColorSequenceKeypoint.new(0.444, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.555, Color3.fromRGB(0, 255, 127)), -- Aqua-Green
		ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.777, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.888, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)), -- Red again
	}),
	rainbowColor = {
		Color3.fromRGB(255, 0, 0), -- Red
		Color3.fromRGB(255, 127, 0), -- Orange
		Color3.fromRGB(255, 255, 0), -- Yellow
		Color3.fromRGB(0, 255, 0), -- Green
		Color3.fromRGB(0, 0, 255), -- Blue
		Color3.fromRGB(75, 0, 130), -- Indigo
		Color3.fromRGB(148, 0, 211), -- Violet
	},
	difficultyColors = {
		EASY = Color3.fromRGB(0, 255, 0), -- Green
		MEDIUM = Color3.fromRGB(255, 255, 0), -- Yellow
		HARD = Color3.fromRGB(255, 0, 0), -- Red
		OP = Color3.fromRGB(0, 0, 0), -- Black
		FALLBACK = Color3.fromRGB(128, 128, 128),
	},
}

return uiUtils
