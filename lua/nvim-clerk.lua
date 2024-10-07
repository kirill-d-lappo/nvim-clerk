local log_level = require("log-level")
local factory = require("factory")

local mergeKvTable = require("utils").mergeKvTable
local M = {
	factory = factory,
	levels = log_level,
	config = {
		min_level = log_level.INFO,
	},
	writer = nil,
}

function M.log(level, message)
	if M.writer == nil then
		return
	end

	local info = debug.getinfo(2, "Sl")
	local event_parameters = {
		timestamp = os.date("*t"),
		file = info.source,
		line_number = info.currentline,
	}

	M.writer(level, message, event_parameters)
end

function M.info(message)
	M.log(log_level.INFO, message)
end

function M.warn(message)
	M.log(log_level.WARN, message)
end

function M.error(message)
	M.log(log_level.ERROR, message)
end

function M.debug(message)
	M.log(log_level.DEBUG, message)
end

function M.trace(message)
	M.log(log_level.TRACE, message)
end

function M.setup(parameters)
	local config = parameters.config
	if config then
		M.config = mergeKvTable(M.config, config)
	end

	local create_writer = parameters.create_writer
	if create_writer then
		local writer = create_writer(factory)
		if writer then
			if type(writer) == "table" then
				writer = factory.create_aggregate_writer(writer)
			end

			if config.min_level then
				writer = factory.create_min_level_writer(config.min_level, writer)
			end

			M.writer = writer
		end
	end
end

return M
