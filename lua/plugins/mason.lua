--[[
  mason.nvim is a package manager for external development tools used by Neovim —
  such as Language Servers (LSPs), DAP servers (debug adapters), linters, and formatters.

  It provides a clean, UI-based, and cross-platform way to install and manage these
  external binaries locally without relying on global system installations or
  manual setup steps.
]]
return {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      -- LSPs:
      "bash-language-server", -- bash
      "clangd", -- C, C++
      "cmake-language-server", -- CMake
      "stylua", -- lua
      "vim-language-server", -- vim
      "pyright", -- python
      "marksman", -- markdown
      "rust-analyzer", -- rust
      "lemminx", -- xml
      "yaml-language-server", -- yaml

      -- Linters:
      "cpplint", -- C, C++
      "ruff", -- python

      -- Formatters:
      "clang-format", -- C++
      "black", -- python
      "yamlfmt", -- yaml
    },
  },
}
