local humanoidUtils = {}

function humanoidUtils.MoveTo(humanoid, targetPoint, andThen)
	local targetReached = false
	local canceled = false

	local connection
	connection = humanoid.MoveToFinished:Connect(function(reached)
		if canceled then
			return
		end
		targetReached = true
		connection:Disconnect()
		connection = nil
		if andThen then
			andThen(reached)
		end
	end)

	humanoid:MoveTo(targetPoint)

	task.spawn(function()
		while not targetReached and not canceled do
			if not (humanoid and humanoid.Parent) then
				break
			end
			if humanoid.WalkToPoint ~= targetPoint then
				break
			end
			humanoid:MoveTo(targetPoint)
			task.wait(6)
		end

		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)

	return {
		Cancel = function()
			canceled = true
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end,
	}
end

return humanoidUtils
