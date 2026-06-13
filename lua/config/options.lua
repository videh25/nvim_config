-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable LazyVim's default autoformat on save (which uses conform.nvim)
vim.g.autoformat = false
vim.g.root_spec = { { ".git", "lua" }, "cwd", "lsp" }

-- Ensure nvm's node bin is on PATH so CLI tools resolve even when nvim is
-- launched from a context where nvm was never sourced. Our ~/.bashrc lazy-loads
-- nvm (it only sources nvm.sh the first time node/npm/npx runs), so a fresh
-- terminal — or any GUI launcher — starts nvim without the node bin on PATH.
-- That makes agentic.nvim's ACP providers (claude-agent-acp, gemini, …) appear
-- "not installed" even though they are. We pick the newest installed version.
if vim.fn.executable("node") == 0 then
  local nvm_node = vim.fn.expand("~/.nvm/versions/node")
  if vim.fn.isdirectory(nvm_node) == 1 then
    local bins = vim.fn.glob(nvm_node .. "/*/bin", true, true)
    local function ver(p) -- parse "/…/vMAJOR.MINOR.PATCH/bin" → {major, minor, patch}
      local maj, min, pat = (p:match("/v([%d.]+)/bin$") or ""):match("(%d+)%.(%d+)%.(%d+)")
      return { tonumber(maj) or 0, tonumber(min) or 0, tonumber(pat) or 0 }
    end
    table.sort(bins, function(a, b)
      local va, vb = ver(a), ver(b)
      for i = 1, 3 do
        if va[i] ~= vb[i] then
          return va[i] > vb[i]
        end
      end
      return false
    end)
    if bins[1] and vim.fn.executable(bins[1] .. "/node") == 1 then
      vim.env.PATH = bins[1] .. ":" .. vim.env.PATH
    end
  end
end
