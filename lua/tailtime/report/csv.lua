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
		table.concat({ "id", "project", "title", "priority", "start", "end", "duration_min" }, sep),
	}
	for _, t in ipairs(tasks) do
		local start = t.start_ts and os.date("%H:%M:%S", t.start_ts) or ""
		local ending = t.end_ts and os.date("%H:%M:%S", t.end_ts) or ""
		local duration = t.duration_sec and math.floor(t.duration_sec / 60) or ""
		local row = {
			t.id,
			escape_csv(t.project),
			escape_csv(t.title),
			t.priority,
			start,
			ending,
			duration,
		}
		table.insert(lines, table.concat(row, sep))
	end
	return table.concat(lines, "\n")
end

return M
