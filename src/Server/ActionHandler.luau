local actionHandler = {}
actionHandler.Queue = {}

function actionHandler:Enqueue(fn: () -> nil)
	table.insert(self.Queue, fn)
end

function actionHandler:Process()
	local currentSize = #actionHandler.Queue
	for i = 1, currentSize do
		local current = table.remove(self.Queue, 1)
		if current then
			current()
		end
	end
end

return actionHandler
