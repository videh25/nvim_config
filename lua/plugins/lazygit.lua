return {
  'kdheepak/lazygit.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open Lazygit" },
  },
  config = function()
    vim.g.lazygit_floating_window_winblend = 0 -- transparency
    vim.g.lazygit_floating_window_scaling_factor = 0.9
  end,
}

