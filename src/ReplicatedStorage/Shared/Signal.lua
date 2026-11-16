local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(callback)
	local connection = { Connected = true }
	table.insert(self._listeners, { Callback = callback, Connection = connection })
	function connection:Disconnect()
		self.Connected = false
	end
	return connection
end

function Signal:Fire(...)
	for _, listener in ipairs(self._listeners) do
		if listener.Connection.Connected then
			task.spawn(listener.Callback, ...)
		end
	end
end

function Signal:Destroy()
	table.clear(self._listeners)
end

return Signal
