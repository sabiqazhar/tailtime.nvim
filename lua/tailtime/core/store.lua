local M = {}
local config = require("tailtime.config")

local function today_path()
	return vim.fn.expand(config.data_dir) .. "/" .. os.date("%Y-%m-%d") .. ".json"
end

local function load_session()
	local path = today_path()
	local f = io.open(path, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local ok, data = pcall(vim.json.decode, content)
		if ok and data then
			return data
		end
	end
	return {
		date = os.date("%Y-%m-%d"),
		created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		tasks = {},
		next_id = 1,
	}
end

local save_timer = nil
function M.save_session(session)
	if save_timer then
		save_timer:stop()
		save_timer:close()
	end
	save_timer = vim.uv.new_timer()
	save_timer:start(2000, 0, function()
		vim.schedule(function()
			local path = today_path()
			local ok, encoded = pcall(vim.json.encode, session)
			if ok then
				local f = io.open(path, "w")
				if f then
					f:write(encoded)
					f:close()
				end
			end
		end)
	end)
end

function M.parse_raw_input(raw)
	raw = raw or ""
	local project, title = raw:match("^%s*(.-)%s*:%s*(.*)$")
	if not project or vim.trim(project) == "" then
		return "general", vim.trim(raw)
	end
	return vim.trim(project), vim.trim(title)
end

function M.add_task(raw_input, priority)
	local project, title = M.parse_raw_input(raw_input)
	local session = load_session()
	local task = {
		id = session.next_id,
		project = project,
		title = title,
		priority = priority or "medium",
		start_ts = nil,
		end_ts = nil,
		duration_sec = nil,
		status = "pending",
		created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	table.insert(session.tasks, task)
	session.next_id = session.next_id + 1
	M.save_session(session)
	return task.id, project, title
end

function M.get_tasks()
	return load_session().tasks
end

function M.update_task(id, updates)
	local session = load_session()
	for _, t in ipairs(session.tasks) do
		if t.id == id then
			for k, v in pairs(updates) do
				t[k] = v
			end
			break
		end
	end
	M.save_session(session)
end

return M
