-- Switch AI CLI agent with :CodeAgent gemini|claude
-- or interactively with <leader>a?

local all_agents = { "gemini", "claude" }

local function available_agents()
  return vim.tbl_filter(function(a)
    return vim.fn.executable(a) == 1
  end, all_agents)
end

local persist_path = vim.fn.stdpath("data") .. "/code-agent.json"

local function load_persisted()
  local file = io.open(persist_path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(vim.json.decode, content)
    if ok and data and data.code_agent then
      return data.code_agent
    end
  end
  return "gemini"
end

local function save_persisted(agent)
  local file = io.open(persist_path, "w")
  if file then
    file:write(vim.json.encode({ code_agent = agent }))
    file:close()
  end
end

local state = { code_agent = load_persisted() }

local function set_agent(agent)
  state.code_agent = agent
  vim.notify("Code agent set to: " .. agent, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("CodeAgent", function(opts)
  set_agent(opts.args)
end, {
  nargs = 1,
  complete = function()
    return available_agents()
  end,
})

local function pick_agent()
  local agents = available_agents()
  if #agents == 0 then
    vim.notify("No code agents found in PATH. Run :checkhealth code-agents for details.", vim.log.levels.WARN)
    return
  end
  vim.ui.select(agents, {
    prompt = "Select code agent",
    format_item = function(item)
      local labels = { gemini = " Gemini AI", claude = " Claude AI" }
      local marker = item == state.code_agent and "  (active)" or ""
      return (labels[item] or item) .. marker
    end,
  }, function(agent)
    if not agent then return end
    vim.ui.select({ "Session only", "All future sessions" }, {
      prompt = "Persist setting?",
    }, function(choice)
      if not choice then return end
      set_agent(agent)
      if choice == "All future sessions" then
        save_persisted(agent)
      end
    end)
  end)
end

return {
  "folke/snacks.nvim",
  opts = {
    terminal = {},
  },
  keys = {
    {
      "<leader>a/",
      function()
        local agent = state.code_agent
        local labels = { gemini = " Gemini AI ", claude = " Claude AI " }
        require("snacks").terminal.toggle(agent, {
          win = {
            position = "right",
            width = 0.4,
            wo = {
              winbar = labels[agent] or (" " .. agent .. " "),
            },
          },
        })
      end,
      desc = "AI CLI (Right Split)",
    },
    {
      "<leader>a?",
      pick_agent,
      desc = "Select AI code agent",
    },
  },
}
