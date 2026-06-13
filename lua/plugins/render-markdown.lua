--[[
  In-buffer rendering for Markdown — headings, code blocks, lists, callouts,
  and (the reason it's here) pipe tables.

  Why we need it: LazyVim sets conceallevel=2, so the markdown_inline
  Treesitter parser conceals the backticks around inline code. Our tables are
  space-aligned in the raw file, but concealing those backticks shrinks every
  cell that contains inline code, so the trailing `|` borders drift left on
  non-cursor lines. render-markdown redraws the table borders accounting for
  the concealed widths, keeping them aligned while preserving the pretty
  inline-code/heading rendering. Both catppuccin and tokyonight already ship
  render-markdown highlight integrations.
]]
return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- Reuses the markdown / markdown_inline parsers already in treesitter.lua;
  -- mini.icons is LazyVim's default icon provider.
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
  ft = { "markdown" },
  opts = {
    pipe_table = {
      -- preset 'round' swaps the ASCII pipes for rounded box-drawing borders.
      -- cell 'padded' pads each cell to the column's *visual* width, which is
      -- what actually realigns the borders once backticks are concealed.
      preset = "round",
      cell = "padded",
    },
  },
}
