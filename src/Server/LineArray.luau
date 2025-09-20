local LineManager = {}
LineManager.Line = {}
LineManager.Queue = {}

LineManager.OperationType = {
	Next = "Next",
	SkipAhead = "SkipAhead",
	CutAll = "CutAll",
	Remove = "Remove",
}

function LineManager:Fill(players)
	self.Line = {}
	for _, player in ipairs(players) do
		table.insert(self.Line, player.UserId)
	end
end

function LineManager:Enqueue(op, userId)
	local index = self:GetIndex(userId)
	if index then
		return
	end
	table.insert(self.Queue, { op = op, userId = userId })
end

function LineManager:ProcessNext()
	local req = table.remove(self.Queue, 1)
	if not req then
		return
	end

	local op = req.op
	local index = self:GetIndex(req.userId)

	if not index then
		return
	end

	if op == self.OperationType.Next then
		if #self.Line > 0 then
			local first = table.remove(self.Line, 1)
			table.insert(self.Line, first)
		end
	elseif op == self.OperationType.SkipAhead then
		if index > 1 and index <= #self.Line then
			self.Line[index], self.Line[index - 1] = self.Line[index - 1], self.Line[index]
		end
	elseif op == self.OperationType.CutAll then
		if index > 1 and index <= #self.Line then
			local mover = table.remove(self.Line, index)
			table.insert(self.Line, 1, mover)
		end
	elseif op == self.OperationType.Remove then
		if #self.Line > 0 then
			table.remove(self.Line, index)
		end
	end
end

function LineManager:GetLine()
	return self.Line
end

function LineManager:GetIndex(userId)
	for i, id in ipairs(self.Line) do
		if id == userId then
			return i
		end
	end
	return nil
end

return LineManager
