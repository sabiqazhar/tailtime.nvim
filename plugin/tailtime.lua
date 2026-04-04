if vim.g.loaded_tailtime then
	return
end
vim.g.loaded_tailtime = true

vim.keymap.set("n", "<leader>ts", ":TailStart ", { desc = "🦫 Start task" })
vim.keymap.set("n", "<leader>te", ":TailDone", { desc = "🦫 Done task" })
vim.keymap.set("n", "<leader>tx", ":TailExport ", { desc = "🦫 Export" })
vim.keymap.set("n", "<leader>tr", ":TailReport ", { desc = "🦫 Report" })
