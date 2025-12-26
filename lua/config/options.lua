-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable LazyVim's default autoformat on save (which uses conform.nvim)
vim.g.autoformat = false
vim.g.root_spec = { { ".git", "lua" }, "cwd", "lsp" }
