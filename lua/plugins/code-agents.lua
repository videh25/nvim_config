-- Switch AI CLI agent with :CodeAgent gemini|claude (default: gemini)
local state = { code_agent = "gemini" }

vim.api.nvim_create_user_command("CodeAgent", function(opts)
  state.code_agent = opts.args
end, {
  nargs = 1,
  complete = function()
    return { "gemini", "claude" }
  end,
})

return {
  "folke/snacks.nvim",
  opts = {
    terminal = {},
  },
  keys = {
    {
      "<leader>a/",
      function()
        local agent = state.code_agent
        local labels = { gemini = " Gemini AI ", claude = " Claude AI " }
        require("snacks").terminal.toggle(agent, {
          win = {
            position = "right",
            width = 0.4,
            wo = {
              winbar = labels[agent] or (" " .. agent .. " "),
            },
          },
        })
      end,
      desc = "AI CLI (Right Split)",
    },
  },
}
