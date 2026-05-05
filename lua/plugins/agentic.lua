-- Helpers shared by the response-complete hook and the permission monkey-patch.

local prompts_by_session = {}

local function brief(text, n)
  text = (text or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  if #text <= n then return text end
  return text:sub(1, n - 1) .. "…"
end

local function provider_for_tab(tab_page_id)
  local ok, registry = pcall(require, "agentic.session_registry")
  if not ok then return nil end
  local sm = registry.sessions and registry.sessions[tab_page_id]
  return sm and sm.agent and sm.agent.provider_config and sm.agent.provider_config.name
end

local function provider_for_session(session_id)
  local ok, registry = pcall(require, "agentic.session_registry")
  if not ok then return nil end
  for _, sm in pairs(registry.sessions or {}) do
    if sm.session_id == session_id then
      return sm.agent and sm.agent.provider_config and sm.agent.provider_config.name
    end
  end
end

-- Resolve a provider's display name (e.g. "Claude Agent ACP") to an SVG icon
-- shipped with the plugin. Returns nil if no match or file missing.
local function icon_for(provider_name)
  if not provider_name then return nil end
  local key_to_file = {
    claude   = "claude.svg",
    gemini   = "gemini.svg",
    codex    = "openai.svg",
    opencode = "opencode.svg",
    cursor   = "cursor.svg",
    copilot  = "copilot.svg",
    auggie   = "augment.svg",
    mistral  = "mistral.svg",
    cline    = "cline.svg",
    goose    = "goose.svg",
  }
  local lower = provider_name:lower()
  local base = vim.fn.stdpath("data") .. "/lazy/agentic.nvim/.github/assets/images/"
  for key, file in pairs(key_to_file) do
    if lower:find(key, 1, true) then
      local path = base .. file
      if vim.fn.filereadable(path) == 1 then return path end
    end
  end
  return nil
end

-- Per-session prompt history for <localLeader>k / <localLeader>j scrollback.
-- Ring buffer of the most recent N prompts. In-memory only; cleared on nvim exit.
local HISTORY_LIMIT = 10
local history_by_session = {}  -- session_id -> { prompts = string[], cursor = integer|nil }

local function record_prompt(session_id, prompt)
  if not session_id or not prompt or prompt == "" then return end
  local h = history_by_session[session_id] or { prompts = {}, cursor = nil }
  table.insert(h.prompts, prompt)
  while #h.prompts > HISTORY_LIMIT do
    table.remove(h.prompts, 1)
  end
  h.cursor = nil  -- reset after each new submission
  history_by_session[session_id] = h
end

local function current_session()
  local ok, registry = pcall(require, "agentic.session_registry")
  if not ok then return nil end
  local tab = vim.api.nvim_get_current_tabpage()
  return registry.sessions and registry.sessions[tab]
end

local function set_input_text(session, text)
  local bufnr = session and session.widget and session.widget.buf_nrs and session.widget.buf_nrs.input
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return false end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(text or "", "\n", { plain = true }))
  return true
end

-- direction: "prev" (older) | "next" (newer)
local function navigate_history(direction)
  local session = current_session()
  if not session or not session.session_id then return end
  local h = history_by_session[session.session_id]
  if not h or #h.prompts == 0 then return end

  if direction == "prev" then
    if h.cursor == nil then
      h.cursor = #h.prompts
    elseif h.cursor > 1 then
      h.cursor = h.cursor - 1
    end
  else  -- next
    if h.cursor == nil then return end
    if h.cursor < #h.prompts then
      h.cursor = h.cursor + 1
    else
      h.cursor = nil  -- past most recent → clear input
    end
  end

  set_input_text(session, h.cursor and h.prompts[h.cursor] or "")
end

local function notify(level, urgency, title, body, icon)
  vim.notify(body ~= "" and body or title, level, { title = title })
  if vim.fn.executable("notify-send") == 1 then
    local cmd = { "notify-send", "-a", "Agentic", "-u", urgency, "-t", "5000" }
    if icon then
      table.insert(cmd, "-i")
      table.insert(cmd, icon)
    end
    table.insert(cmd, title)
    table.insert(cmd, body)
    vim.system(cmd, { detach = true })
  end
end

return {
  "carlos-algms/agentic.nvim",

  --- @type agentic.PartialUserConfig
  opts = {
    -- Default provider when a new chat opens.
    -- Switch mid-session in the chat widget with <localLeader>s.
    provider = "claude-agent-acp",

    -- Enabled ACP providers. Built-in defaults are merged, so an empty
    -- table value means "use the plugin's defaults for this provider".
    --
    -- To add a new provider later (e.g. Codex, OpenCode, Cursor, Copilot,
    -- Auggie, Mistral Vibe, Cline, Goose):
    --   1. Install its ACP CLI (see agentic.nvim README).
    --   2. Add an entry below — `{}` is enough if you accept the defaults.
    acp_providers = {
      ["claude-agent-acp"] = {},
      ["gemini-acp"] = {},
      -- ["codex-acp"]        = {},
      -- ["opencode-acp"]     = {},
      -- ["cursor-acp"]       = {},
      -- ["copilot-acp"]      = {},
      -- ["auggie-acp"]       = {},
      -- ["mistral-vibe-acp"] = {},
      -- ["cline-acp"]        = {},
      -- ["goose-acp"]        = {},
    },

    windows = {
      position = "right",
      width = "40%",
    },

    -- Replace emoji icons with Nerd Font / ASCII for a developer-terminal look.
    spinner_chars = {
      thinking  = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      searching = { "[/]", "[-]", "[\\]", "[|]" },
    },

    diagnostic_icons = {
      error = "✗",
      warn  = "⚠",
      info  = "ℹ",
      hint  = "★",
    },

    message_icons = {
      thinking = "⋯",
      finished = "✓",
      stopped  = "■",
      error    = "✗",
    },

    -- Provider-agnostic notification when the agent finishes a turn.
    -- Fires for any ACP provider (Claude, Gemini, Codex, ...).
    hooks = {
      on_prompt_submit = function(data)
        prompts_by_session[data.session_id] = data.prompt
        record_prompt(data.session_id, data.prompt)
      end,

      on_response_complete = function(data)
        local prompt = prompts_by_session[data.session_id] or ""
        prompts_by_session[data.session_id] = nil

        local provider = provider_for_tab(data.tab_page_id) or "Agent"
        local folder   = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        local status   = data.success and "finished" or "error"
        local title    = string.format("%s · %s [%s]", provider, status, folder)

        local level   = data.success and vim.log.levels.INFO or vim.log.levels.ERROR
        local urgency = data.success and "normal" or "critical"
        notify(level, urgency, title, brief(prompt, 80), icon_for(provider))
      end,
    },
  },

  -- Custom config: run normal setup, then monkey-patch PermissionManager.add_request
  -- to fire a notification on every incoming permission request.
  -- agentic.nvim does not expose an `on_request_permission` user hook (as of source
  -- inspected against main). This patch is a workaround — re-verify after plugin updates.
  config = function(_, opts)
    require("agentic").setup(opts)

    local ok, PM = pcall(require, "agentic.ui.permission_manager")
    if not ok then return end

    local original_add_request = PM.add_request
    PM.add_request = function(self, request, callback)
      local tool     = request.toolCall or {}
      local provider = provider_for_session(request.sessionId) or "Agent"
      local folder   = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      local kind     = tool.kind or "tool"
      local title    = string.format("%s · permission [%s]", provider, folder)
      local body     = string.format("%s: %s", kind, brief(tool.title or "(unnamed)", 80))

      notify(vim.log.levels.WARN, "critical", title, body, icon_for(provider))

      return original_add_request(self, request, callback)
    end
  end,

  keys = {
    { "<C-\\>", function() require("agentic").toggle() end,
      mode = { "n", "v", "i" }, desc = "Toggle Agentic Chat" },
    { "<C-'>", function() require("agentic").add_selection_or_file_to_context() end,
      mode = { "n", "v" }, desc = "Add file/selection to Agentic context" },
    { "<C-,>", function() require("agentic").new_session() end,
      mode = { "n", "v", "i" }, desc = "New Agentic session" },
    { "<A-i>r", function() require("agentic").restore_session() end,
      mode = { "n", "v", "i" }, desc = "Restore Agentic session" },
    { "<leader>ad", function() require("agentic").add_current_line_diagnostics() end,
      mode = "n", desc = "Add line diagnostic to Agentic" },
    { "<leader>aD", function() require("agentic").add_buffer_diagnostics() end,
      mode = "n", desc = "Add buffer diagnostics to Agentic" },
    { "<localLeader>q", function() require("agentic").stop_generation() end,
      mode = { "n", "v", "i" }, desc = "Stop Agentic generation" },
    { "<localLeader>k", function() navigate_history("prev") end,
      mode = { "n", "i" }, desc = "Agentic: previous prompt" },
    { "<localLeader>j", function() navigate_history("next") end,
      mode = { "n", "i" }, desc = "Agentic: next prompt" },
  },
}
