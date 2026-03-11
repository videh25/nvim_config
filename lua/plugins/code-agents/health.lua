local M = {}

local agents = {
  { name = "gemini", cmd = "gemini" },
  { name = "claude", cmd = "claude" },
}

function M.check()
  vim.health.start("code-agents")
  for _, agent in ipairs(agents) do
    if vim.fn.executable(agent.cmd) == 1 then
      vim.health.ok(agent.name .. " is installed")
    else
      vim.health.warn(agent.name .. " is not installed or not in PATH")
    end
  end
end

return M
