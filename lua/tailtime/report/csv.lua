local M = {}

local function escape_csv(val)
	if type(val) ~= "string" then
		return tostring(val or "")
	end
	if val:match('[,\n"]') then
		return '"' .. val:gsub('"', '""') .. '"'
	end
	return val
end

function M.export(tasks, opts)
	opts = opts or {}
	local sep = opts.separator or ","
	local lines = {
		table.concat({ "id", "project", "title", "priority", "start", "end", "duration_min", "git_files", "git_added", "git_removed" }, sep),
	}
	for _, t in ipairs(tasks) do
		local start = t.start_ts and os.date("%H:%M:%S", t.start_ts) or ""
		local ending = t.end_ts and os.date("%H:%M:%S", t.end_ts) or ""
		local duration = t.duration_sec and math.floor(t.duration_sec / 60) or ""
		local git_files = t.git_stats and t.git_stats.files or ""
		local git_added = t.git_stats and t.git_stats.added or ""
		local git_removed = t.git_stats and t.git_stats.removed or ""
		local row = {
			t.id,
			escape_csv(t.project),
			escape_csv(t.title),
			t.priority,
			start,
			ending,
			duration,
			git_files,
			git_added,
			git_removed,
		}
		table.insert(lines, table.concat(row, sep))
	end
	return table.concat(lines, "\n")
end

return M
