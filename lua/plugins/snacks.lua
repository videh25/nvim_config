--[[
  snacks.nvim is a utility library + plugin suite designed to enhance developer
  productivity and make Neovim configuration simpler, cleaner, and more declarative.

  It **bundles** together a collection of high-quality small utilities ("snacks")
  like better notifications, terminal integration, scratch buffers, UI helpers,
  and async helpers — all written in Lua and designed for composability.
]]
return {
  "folke/snacks.nvim",
  opts = {
    image = { enabled = true },
    notifier = {
      timeout = 5000, -- Make notifications last for 5 secs
    },
    picker = {
      sources = {
        explorer = {
          hidden = true,
        },
      },
    },
  },
}
