-- In your snacks.nvim config file:
return {
  "folke/snacks.nvim",
  opts = {
    image = { enabled = false },  -- I do not want to view images in editor
    notifier = {
      timeout = 5000, -- Make notifications last for 5 secs
    },
  }
}
