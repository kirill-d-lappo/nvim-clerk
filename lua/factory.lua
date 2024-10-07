local log_level = require("log-level")

local level_short_display_name = {
	[log_level.TRACE] = "TRAC",
	[log_level.DEBUG] = "DEBG",
	[log_level.INFO] = "INFO",
	[log_level.WARN] = "WARN",
	[log_level.ERROR] = "ERRO",
}

local factory = {}

function factory.create_nvim_plugin_file_writer(plugin_name)
	local outfile = string.format("%s/%s.log", vim.api.nvim_call_function("stdpath", { "state" }), plugin_name)
	return factory.create_file_writer(outfile)
end

function factory.create_file_writer(file_path)
	return function(level, message, event_parameters)
		local timestamp = os.date("%H:%M:%S", os.time(event_parameters.timestamp))
		local level_name = level_short_display_name[level] or level_short_display_name[log_level.TRACE]
		local file = event_parameters.file
		local line_number = event_parameters.line_number

		local str = string.format("[%s %+4s] <%s:%s> %s", timestamp, level_name, file, line_number, message)

		local fp = io.open(file_path, "a")
		if fp then
			fp:write(str)
			fp:write("\n")
			fp:close()
		end
	end
end

-- taken from https://github.com/tjdevries/vlog.nvim
function factory.create_nvim_console_writer(plugin_name, use_highlight)
	local highlight_types = {
		[log_level.TRACE] = "Comment",
		[log_level.DEBUG] = "Comment",
		[log_level.INFO] = "None",
		[log_level.WARN] = "WarningMsg",
		[log_level.ERROR] = "ErrorMsg",
	}
	return function(level, message, event_parameters)
		local timestamp = os.date("%H:%M:%S", os.time(event_parameters.timestamp))
		local level_upper = level_short_display_name[level] or level_short_display_name[log_level.TRACE]

		local console_string = string.format("[%s %+4s] %s ", timestamp, level_upper, message)

		local highlight_type = highlight_types[level]
		if use_highlight and highlight_type then
			vim.cmd(string.format("echohl %s", highlight_type))
		end

		local split_console = vim.split(console_string, "\n")
		for _, v in ipairs(split_console) do
			vim.cmd(string.format([[echom "[%s] %s"]], plugin_name, vim.fn.escape(v, '"')))
		end

		if use_highlight and highlight_type then
			vim.cmd("echohl NONE")
		end
	end
end

function factory.create_min_level_writer(min_level, inner_writer)
	return function(level, message, event_parameters)
		if min_level > level then
			return
		end

		inner_writer(level, message, event_parameters)
	end
end

function factory.create_aggregate_writer(inner_writers)
	return function(level, message, event_parameters)
		for _, inner_writer in pairs(inner_writers) do
			inner_writer(level, message, event_parameters)
		end
	end
end

return factory

