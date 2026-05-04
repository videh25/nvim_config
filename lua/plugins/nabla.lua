return {
  "jbyuki/nabla.nvim",
  event = "VeryLazy",
  config = function()
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = vim.api.nvim_create_augroup("NablaPopup", { clear = true }),
      callback = vim.schedule_wrap(function()
        pcall(function()
          require("nabla").popup()
        end)
      end),
    })
  end,
}
