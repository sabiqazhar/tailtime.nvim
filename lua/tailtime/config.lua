local M = {
	data_dir = nil, -- Set dynamically
	timer = {
		enabled = true,
		position = "lualine_y",
		format = "🦫 %s | %s",
		color = { fg = "#a6e3a1" },
	},
	export = {
		default_format = "csv",
		separator = ",",
	},
	priority = {
		levels = { low = 1, medium = 2, high = 3 },
		icons = { low = "🟢", medium = "🟡", high = "🔴" },
	},
}

function M.get_data_dir()
	-- Return user-configured path, or fallback to ./tailtask
	return M.data_dir or "./tailtask"
end

function M.setup(opts)
	M = vim.tbl_deep_extend("force", M, opts or {})
	-- Auto-create dir
	local dir = vim.fn.expand(M.get_data_dir())
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
end

return M
