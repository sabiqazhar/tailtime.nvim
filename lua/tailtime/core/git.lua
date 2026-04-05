local M = {}

local function run_git(cmd)
	local ok, res = pcall(vim.fn.system, { "sh", "-c", cmd })
	if not ok or vim.v.shell_error ~= 0 then
		return nil
	end
	return vim.trim(res)
end

function M.capture_baseline()
	local head = run_git("git rev-parse HEAD 2>/dev/null")
	return head or "__unborn__"
end

function M.get_cumulative_stats(baseline)
	if not baseline or baseline == "__unborn__" then
		return nil
	end

	local output = run_git(string.format("git diff --numstat %s", baseline))
	if not output or output == "" then
		return { files = 0, added = 0, removed = 0 }
	end

	local files, added, removed = 0, 0, 0
	for line in output:gmatch("[^\r\n]+") do
		local a, r = line:match("^(%S+)%s+(%S+)%s")
		if a and r then
			if a ~= "-" and r ~= "-" then
				added = added + (tonumber(a) or 0)
				removed = removed + (tonumber(r) or 0)
				files = files + 1
			end
		end
	end
	return { files = files, added = added, removed = removed }
end

return M
