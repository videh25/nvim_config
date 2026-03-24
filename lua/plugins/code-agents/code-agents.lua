-- Switch AI CLI agent with :CodeAgent gemini|claude
-- or interactively with <leader>a?
-- Launch or resume a session with <leader>a/

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

-- Parse `gemini --list-sessions` output into a list of {index, label} entries.
-- Expected format (one session per line): "1. <title>" or "1) <title>"
local function get_gemini_sessions()
  local lines = vim.fn.systemlist("gemini --list-sessions 2>/dev/null")
  local sessions = {}
  for _, line in ipairs(lines) do
    local idx, name = line:match("^%s*(%d+)[.)%]]%s+(.*)")
    if idx then
      table.insert(sessions, { index = tonumber(idx), label = name:match("^(.-)%s*$") })
    end
  end
  return sessions
end

local labels = { gemini = " Gemini AI ", claude = " Claude AI " }

local function launch(agent, cmd)
  require("snacks").terminal.toggle(cmd, {
    win = {
      position = "right",
      width = 0.4,
      wo = { winbar = labels[agent] or (" " .. agent .. " ") },
    },
  })
end

local function pick_gemini_session()
  local sessions = get_gemini_sessions()
  if #sessions == 0 then
    vim.notify("No previous Gemini sessions found, starting new session.", vim.log.levels.INFO)
    launch("gemini", "gemini")
    return
  end

  local items = { "Latest session" }
  for _, s in ipairs(sessions) do
    table.insert(items, s.label)
  end

  vim.ui.select(items, { prompt = "Select Gemini session" }, function(selected)
    if not selected then return end
    if selected == "Latest session" then
      launch("gemini", "gemini --resume latest")
    else
      for _, s in ipairs(sessions) do
        if s.label == selected then
          launch("gemini", "gemini --resume " .. s.index)
          return
        end
      end
    end
  end)
end

local function pick_session_and_launch()
  local agent = state.code_agent

  vim.ui.select({ "New session", "Resume session" }, {
    prompt = "Start mode (" .. agent .. ")",
  }, function(choice)
    if not choice then return end

    if choice == "New session" then
      launch(agent, agent)
    elseif agent == "claude" then
      -- claude --resume opens a native interactive TUI picker inside the terminal
      launch("claude", "claude --resume")
    else
      pick_gemini_session()
    end
  end)
end

local function pick_agent()
  local agents = available_agents()
  if #agents == 0 then
    vim.notify("No code agents found in PATH. Run :checkhealth code-agents for details.", vim.log.levels.WARN)
    return
  end
  vim.ui.select(agents, {
    prompt = "Select code agent",
    format_item = function(item)
      local marker = item == state.code_agent and "  (active)" or ""
      return (labels[item] and labels[item]:gsub(" ", "") or item) .. marker
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
      pick_session_and_launch,
      desc = "AI CLI (Right Split)",
    },
    {
      "<leader>a?",
      pick_agent,
      desc = "Select AI code agent",
    },
  },
}
