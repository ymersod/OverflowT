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

function LineManager:Next(): boolean
	if #self.Line > 0 then
		local first = table.remove(self.Line, 1)
		table.insert(self.Line, first)
		return true
	end
	return false
end

function LineManager:SkipAhead(userId): boolean
	local index = self:GetIndex(userId)
	if index and index > 1 and index <= #self.Line then
		self.Line[index], self.Line[index - 1] = self.Line[index - 1], self.Line[index]
		return true
	end
	return false
end

function LineManager:CutAll(userId): boolean
	local index = self:GetIndex(userId)
	if index and index > 1 and index <= #self.Line then
		local mover = table.remove(self.Line, index)
		table.insert(self.Line, 1, mover)
		return true
	end
	return false
end

function LineManager:Remove(userId): boolean
	local index = self:GetIndex(userId)
	if index then
		table.remove(self.Line, index)
		return true
	end
	return false
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

function LineManager:ResetLine()
	self.Line = {}
end

return LineManager
