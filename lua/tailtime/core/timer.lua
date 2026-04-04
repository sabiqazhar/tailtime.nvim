local M = {}
local config = require("tailtime.config")

local active_task = nil
local start_ts = nil
local uv_timer = nil
local display_cache = ""

local function fmt_duration(sec)
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function refresh()
	if active_task and start_ts then
		local now = math.floor(vim.uv.now() / 1000)
		display_cache = string.format(config.timer.format, active_task, fmt_duration(now - start_ts))
	else
		display_cache = ""
	end
	if vim.api.nvim__redraw then
		vim.api.nvim__redraw({ statusline = true, tabline = true })
	else
		vim.cmd("redrawstatus")
	end
end

function M.start(task_name)
	if uv_timer then
		M.stop()
	end
	active_task = task_name
	start_ts = math.floor(vim.uv.now() / 1000)
	uv_timer = vim.uv.new_timer()
	uv_timer:start(0, 1000, vim.schedule_wrap(refresh))
	refresh()
end

function M.stop()
	local elapsed = 0
	if uv_timer then
		uv_timer:stop()
		uv_timer:close()
		uv_timer = nil
	end
	if active_task and start_ts then
		elapsed = math.floor(vim.uv.now() / 1000) - start_ts
	end
	active_task = nil
	start_ts = nil
	display_cache = ""
	refresh()
	return elapsed
end

function M.get_display()
	return display_cache
end
function M.is_running()
	return active_task ~= nil
end
function M.get_active_task()
	return active_task
end

return M
