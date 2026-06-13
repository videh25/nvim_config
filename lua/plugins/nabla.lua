return {
  "jbyuki/nabla.nvim",
  -- markdown included so nabla loads for .md too — it renders math in `$…$` /
  -- `$$…$$` via the latex Treesitter injection (see lua/plugins/treesitter.lua).
  ft = { "tex", "latex", "plaintex", "markdown" },
  config = function()
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = vim.api.nvim_create_augroup("NablaPopup", { clear = true }),
      pattern = { "*.tex", "*.latex", "*.md", "*.markdown" },
      callback = vim.schedule_wrap(function()
        pcall(function()
          require("nabla").popup()
        end)
      end),
    })
  end,
}
