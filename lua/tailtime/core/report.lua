local M = {}
local config = require("tailtime.config")

local function fmt_hm(sec)
	if not sec then
		return "0m"
	end
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	if h > 0 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%dm", m)
end

local function fmt_time(ts)
	if not ts then
		return "--:--"
	end
	return os.date("%H:%M", ts)
end

local function get_priority_icon(prio)
	return config.priority.icons[prio] or "⚪"
end

function M.generate()
	local data_dir = "./tailtask"
	local files = vim.fn.globpath(data_dir, "*.json", true, true)

	if #files == 0 then
		return "🦫 TAILTIME REPORT\n\nNo data found in ./tailtask"
	end

	-- Load all tasks
	local all_tasks = {}
	for _, f in ipairs(files) do
		local content = table.concat(vim.fn.readfile(f, "b"), "")
		local ok, data = pcall(vim.json.decode, content)
		if ok and data and data.tasks then
			for _, t in ipairs(data.tasks) do
				table.insert(all_tasks, t)
			end
		end
	end

	-- Group by project
	local projects = {}
	for _, t in ipairs(all_tasks) do
		local proj = t.project or "Unknown"
		if not projects[proj] then
			projects[proj] = {
				name = proj,
				tasks = {},
				total_sec = 0,
				done_count = 0,
				pending_count = 0,
			}
		end
		table.insert(projects[proj].tasks, t)
		if t.status == "done" and t.duration_sec then
			projects[proj].total_sec = projects[proj].total_sec + t.duration_sec
			projects[proj].done_count = projects[proj].done_count + 1
		else
			projects[proj].pending_count = projects[proj].pending_count + 1
		end
	end

	-- Calculate peak hours
	local hour_counts = {}
	for _, t in ipairs(all_tasks) do
		if t.start_ts and t.duration_sec then
			local hour = tonumber(os.date("%H", t.start_ts))
			hour_counts[hour] = (hour_counts[hour] or 0) + t.duration_sec
		end
	end
	local peak_hour = nil
	local peak_sec = 0
	for hour, sec in pairs(hour_counts) do
		if sec > peak_sec then
			peak_sec = sec
			peak_hour = hour
		end
	end

	-- Sort projects by total time
	local sorted = {}
	for _, p in pairs(projects) do
		table.insert(sorted, p)
	end
	table.sort(sorted, function(a, b)
		return a.total_sec > b.total_sec
	end)

	-- Build report
	local lines = {}
	local title = #sorted == 1 and sorted[1].name or ("All Projects (" .. #sorted .. ")")
	table.insert(lines, "🦫 TAILTIME REPORT — " .. title)
	table.insert(lines, string.rep("━", 50))

	-- Peak hours
	if peak_hour then
		local next_hour = (peak_hour + 1) % 24
		table.insert(lines, string.format("⏰ Peak Hour     : %02d - %02d (%s)", peak_hour, next_hour, fmt_hm(peak_sec)))
	end

	local grand_total = 0
	local total_done = 0
	local total_pending = 0

	for _, proj in ipairs(sorted) do
		grand_total = grand_total + proj.total_sec
		total_done = total_done + proj.done_count
		total_pending = total_pending + proj.pending_count

		table.insert(lines, "")
		table.insert(lines, string.format("📁 %s", proj.name))
		table.insert(lines, string.format("   ⏱️  %s | ✅ %d | ⏳ %d", fmt_hm(proj.total_sec), proj.done_count, proj.pending_count))

		-- List tasks under project
		for _, t in ipairs(proj.tasks) do
			local status_icon = t.status == "done" and "✅" or "⏳"
			local priority = get_priority_icon(t.priority)
			local duration = t.duration_sec and (" (" .. fmt_hm(t.duration_sec) .. ")") or ""
			local start = fmt_time(t.start_ts)
			local ending = fmt_time(t.end_ts)
			table.insert(lines, string.format("   %s %s [%s-%s] %s%s", status_icon, priority, start, ending, t.title, duration))
		end
	end

	table.insert(lines, "")
	table.insert(lines, string.rep("━", 50))
	table.insert(lines, string.format("📊 TOTAL: %s | %d done / %d pending", fmt_hm(grand_total), total_done, total_pending))
	table.insert(lines, "")
	table.insert(lines, "Press <q> to close • <e> export markdown")

	return table.concat(lines, "\n")
end

return M
