return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate", -- Automatically update Mason's registry
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "clangd",
                    "pyright",
                    "lemminx",
                }, -- Automatically install servers
            })

            local lspconfig = require("lspconfig")
            require("mason-lspconfig").setup_handlers({
                function(server_name)
                    if server_name == "pyright" then
                        lspconfig[server_name].setup({
                            settings = {
                                python = {
                                    analysis = {
                                        pythonPath = "python3.8",
                                    },
                                },
                            },
                        })
                    else
                        -- Default LSP setup for other servers (clangd, lemminx)
                        lspconfig[server_name].setup({})
                    end
                end,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
    },
}
