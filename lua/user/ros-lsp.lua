-- lua/user/lsp.lua (LazyVim LSP configuration for ROS)

local lspconfig = require("lspconfig")

-- Configure clangd for C++ (ROS)
lspconfig.clangd.setup({
  init_options = {
    -- compilationDatabaseDirectory = "build", -- Set to the directory containing compile_commands.json
    extraArgs = {
      "-I/usr/include", -- System include path
      "-I/opt/ros/noetic/include", -- ROS 1 (Noetic) include path
      "-I/opt/ros/foxy/include", -- ROS 2 (Foxy) include path
    },
  },
})

-- Configure pyright for Python (ROS)
lspconfig.pyright.setup({
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic", -- Set to "strict" for more thorough checks
        diagnosticMode = "workspace",
      },
    },
  },
})

-- -- Configure ROS Language Server (rosls) for ROS-specific files
-- lspconfig.rosls.setup({
--   cmd = { "ros-language-server" }, -- Ensure ros-language-server is installed globally
--   root_dir = lspconfig.util.root_pattern("package.xml", ".git"), -- ROS workspace root
--   init_options = {
--     rosVersion = "noetic", -- Change to "foxy" for ROS 2
--     workspaceFolders = { vim.fn.getcwd() }, -- Set the current working directory as the workspace
--   },
-- })
