local M = {}
local config = require("tailtime.config")

local function fmt_hm(sec)
	return string.format("%dh %dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60))
end

function M.generate(range)
	local data_dir = vim.fn.expand(config.data_dir)
	local files = vim.fn.globpath(data_dir, "*.json", true, true)
	local tasks = {}
	local now = os.time()

	for _, f in ipairs(files) do
		local date_str = f:match("(%d%d%d%d%-%d%d%-%d%d)%.json$")
		if not date_str then
			goto continue
		end

		local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
		local file_time =
			os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 })
		local days_diff = math.floor((now - file_time) / 86400)

		local valid = false
		if range == "today" and days_diff == 0 then
			valid = true
		elseif range == "week" and days_diff >= 0 and days_diff < 7 then
			valid = true
		elseif range == date_str then
			valid = true
		end

		if valid then
			local ok, data = pcall(vim.json.decode, vim.fn.readfile(f, "b"):table_concat())
			if ok and data.tasks then
				for _, t in ipairs(data.tasks) do
					table.insert(tasks, t)
				end
			end
		end
		::continue::
	end

	-- Aggregation
	local total_sec = 0
	local by_project = {}
	local by_priority = {}
	local done_count = 0
	local pending_count = 0

	for _, t in ipairs(tasks) do
		if t.status == "done" and t.duration_sec then
			total_sec = total_sec + t.duration_sec
			done_count = done_count + 1

			by_project[t.project] = (by_project[t.project] or 0) + t.duration_sec
			by_priority[t.priority] = (by_priority[t.priority] or 0) + t.duration_sec
		else
			pending_count = pending_count + 1
		end
	end

	-- Sort projects by time desc
	local sorted_proj = {}
	for p, s in pairs(by_project) do
		table.insert(sorted_proj, { name = p, sec = s })
	end
	table.sort(sorted_proj, function(a, b)
		return a.sec > b.sec
	end)

	local lines = {}
	table.insert(lines, "🦫 TAILTIME REPORT — " .. (range == "today" and os.date("%Y-%m-%d") or range))
	table.insert(lines, string.rep("━", 40))
	table.insert(lines, string.format("⏱️  Total Tracked : %s", fmt_hm(total_sec)))
	table.insert(lines, string.format("📦 Projects       : %d active", #sorted_proj))
	for _, p in ipairs(sorted_proj) do
		local pct = total_sec > 0 and math.floor(p.sec / total_sec * 100) or 0
		table.insert(lines, string.format("   • %-15s %s (%d%%)", p.name, fmt_hm(p.sec), pct))
	end
	table.insert(lines, string.format("🎯 Priority Break:"))
	for prio, sec in pairs(by_priority) do
		local icon = config.priority.icons[prio] or "⚪"
		table.insert(lines, string.format("   %s %-5s: %s", icon, prio, fmt_hm(sec)))
	end
	table.insert(lines, string.format("✅ Tasks          : %d done / %d pending", done_count, pending_count))
	if done_count > 0 then
		table.insert(lines, string.format("⏱️  Avg/Task      : %s", fmt_hm(total_sec / done_count)))
	end
	table.insert(lines, string.rep("━", 40))
	table.insert(lines, "Press <q> to close • <e> export markdown")

	return table.concat(lines, "\n")
end

return M
