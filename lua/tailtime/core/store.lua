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
	local parsed_prio = nil

	raw = raw:gsub("%s*@(%a+)%s*$", function(p)
		local map =
			{ h = "high", l = "low", m = "medium", med = "medium", high = "high", low = "low", medium = "medium" }
		parsed_prio = map[p:lower()] or p:lower()
		return ""
	end)

	local project, title = raw:match("^%s*(.-)%s*:%s*(.*)$")
	if not project or vim.trim(project) == "" then
		return "general", vim.trim(raw), parsed_prio
	end
	return vim.trim(project), vim.trim(title), parsed_prio
end

function M.add_task(raw_input, priority)
	local project, title, parsed_prio = M.parse_raw_input(raw_input)
	local final_prio = priority or parsed_prio or "medium"

	local session = load_session()
	local task = {
		id = session.next_id,
		project = project,
		title = title,
		priority = final_prio,
		start_ts = nil,
		end_ts = nil,
		duration_sec = nil,
		status = "pending",
		created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	table.insert(session.tasks, task)
	session.next_id = session.next_id + 1
	M.save_session(session)
	return task.id
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
