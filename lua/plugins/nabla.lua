return {
  "jbyuki/nabla.nvim",
  ft = { "tex", "latex", "plaintex" },
  config = function()
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = vim.api.nvim_create_augroup("NablaPopup", { clear = true }),
      pattern = { "*.tex", "*.latex" },
      callback = vim.schedule_wrap(function()
        pcall(function()
          require("nabla").popup()
        end)
      end),
    })
  end,
}
