return {
  "folke/snacks.nvim",
  opts = {
    -- We are extending the existing snacks config
    terminal = {
      -- You can define custom terminal layouts here if you want
    },
  },
  keys = {
    {
      "<leader>a/",
      function()
        -- This calls the toggle function directly within the plugin spec
        require("snacks").terminal.toggle("gemini", {
          win = {
            position = "right",
            width = 0.4,
            wo = {
              winbar = " Gemini AI ",
            },
          },
        })
      end,
      desc = "Gemini CLI (Right Split)",
    },
  },
}
