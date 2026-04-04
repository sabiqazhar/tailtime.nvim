local M = {}
local config = require("tailtime.config")
local timer = require("tailtime.core.timer")
local store = require("tailtime.core.store")
local csv_export = require("tailtime.report.csv")
local report_gen = require("tailtime.core.report")

function M.setup(opts)
	config.setup(opts)

	-- Lualine integration
	if config.timer.enabled and pcall(require, "lualine") then
		local lualine = require("lualine")
		local sections = lualine.get_config().sections or {}
		local pos = config.timer.position or "lualine_y"
		sections[pos] = sections[pos] or {}
		table.insert(sections[pos], 1, {
			function()
				return timer.get_display()
			end,
			color = config.timer.color,
		})
		lualine.setup({ sections = sections })
	end
end

vim.api.nvim_create_user_command("TailStart", function(opts)
	local raw = opts.args or "Untitled Task"
	local project, title, auto_prio = store.parse_raw_input(raw)

	local function start_with_priority(priority)
		local id = store.add_task(raw, priority)
		local icon = config.priority.icons[priority] or ""
		timer.start(string.format("[%s] %s %s", project, title, icon))
		vim.notify(string.format("🦫 [%s] %s (#%d) [%s]", project, title, id, priority), vim.log.levels.INFO)
	end

	if auto_prio and config.priority.levels[auto_prio] then
		start_with_priority(auto_prio)
	else
		vim.ui.select({ "low", "medium", "high" }, {
			prompt = "Select priority for task:",
			format_item = function(item)
				return string.format("%s %s", config.priority.icons[item] or "", item)
			end,
		}, function(choice)
			if choice then
				start_with_priority(choice)
			end
		end)
	end
end, { nargs = "?" })

vim.api.nvim_create_user_command("TailDone", function()
	if not timer.is_running() then
		vim.notify("⏹️ No active task", vim.log.levels.WARN)
		return
	end
	local elapsed = timer.stop()
	local tasks = store.get_tasks()
	for i = #tasks, 1, -1 do
		local t = tasks[i]
		if t.status == "pending" then
			store.update_task(t.id, {
				status = "done",
				start_ts = t.start_ts or (os.time() - elapsed),
				end_ts = os.time(),
				duration_sec = elapsed,
			})
			vim.notify(
				string.format("✅ [%s] %s (%dm)", t.project, t.title, math.floor(elapsed / 60)),
				vim.log.levels.INFO
			)
			break
		end
	end
end, {})

vim.api.nvim_create_user_command("TailExport", function(opts)
	local fmt = opts.args or config.export.default_format
	local tasks = store.get_tasks()
	local content, ext
	if fmt == "csv" then
		content = csv_export.export(tasks)
		ext = "csv"
	else
		content = vim.json.encode(tasks)
		ext = "json"
	end
	local dir = vim.fn.expand(config.get_data_dir())
	local path = dir .. "/export_" .. os.date("%Y%m%d_%H%M%S") .. "." .. ext
	local f = io.open(path, "w")
	f:write(content)
	f:close()
	vim.notify(string.format("📤 Exported: %s", path), vim.log.levels.INFO)
end, { nargs = "?" })

vim.api.nvim_create_user_command("TailReport", function()
	local content = report_gen.generate()

	vim.cmd("vnew")
	vim.api.nvim_buf_set_option(0, "buftype", "nofile")
	vim.api.nvim_buf_set_option(0, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(0, "modifiable", true)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(content, "\n"))
	vim.api.nvim_buf_set_option(0, "modifiable", false)

	vim.keymap.set("n", "q", "<cmd>q<CR>", { buffer = true })
	vim.keymap.set("n", "e", function()
		local path = "./tailtask/report_" .. os.date("%Y%m%d_%H%M%S") .. ".md"
		local f = io.open(path, "w")
		f:write("```\n" .. content .. "\n```")
		f:close()
		vim.notify("📄 Report exported to " .. path)
	end, { buffer = true })
end, { nargs = "?" })

return M
