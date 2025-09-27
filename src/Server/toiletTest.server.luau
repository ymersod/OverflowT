local part = script.Parent
local t = 1

if not part or not part:IsA("Part") then
	return
end

while task.wait() do
	local hue = tick() % (10 / t) / (10 / t)
	local color = Color3.fromHSV(hue, 1, 1)
	part.Color = color
end
