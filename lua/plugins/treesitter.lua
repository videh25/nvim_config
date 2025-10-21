--[[
  Provides a modern, high-performance syntax parser and code understanding layer
  based on Tree-sitter — a parser generator tool that builds incremental parse trees
  for code in various languages.

  nvim-treesitter replaces traditional regex-based syntax highlighting with a structural, language-aware approach.
]]
return {
  "nvim-treesitter/nvim-treesitter",
  opts_extend = {}, -- overriding lazyvim's default config to extend the ensure_installed
  opts = {
    -- List ONLY the parsers you want installed and maintained
    ensure_installed = {
      "bash",
      "c", -- C
      "cpp", -- C++ (Essential for your ROS/robotics work)
      "cmake",
      "diff",
      "dockerfile", -- Dockerfile
      "dtd", -- Document Type Definition, needed for XML
      "json",
      "lua", -- Neovim config
      "vim", -- Vimscript/Neovim config
      "python",
      "markdown",
      "markdown_inline",
      "rust",
      "toml",
      "query", -- Tree-sitter query files
      "xml",
      "yaml",
    }, -- You must also re-enable the core modules you want:
    highlight = { enable = true },
    indent = { enable = true },
    folds = { enable = true },
  },
}
