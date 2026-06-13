-- task-dashboard hooks for agentic.nvim.
--
-- This file is a regular Lua module. The recommended way to use it is to make
-- it require()-able from your nvim config so the config itself contains no
-- repo paths.
--
-- ---------------------------------------------------------------------------
-- Step 1: Copy this file into your nvim config (do this ONCE)
-- ---------------------------------------------------------------------------
--
-- Drop it under any `lua/` dir on nvim's runtimepath — simplest is your own
-- nvim config's lua/ dir:
--
--   mkdir -p ~/.config/nvim/lua
--   cp <path-to-this-file> ~/.config/nvim/lua/notif_dash_agentic.lua
--
-- (`bash install.sh` prints the exact command for your checkout location.)
--
-- After that, `require('notif_dash_agentic')` works from anywhere — your
-- nvim config no longer references the repo path. If the file later changes
-- upstream, re-run the cp to update.
--
-- (Prefer a symlink instead of a copy if you want auto-tracking of upstream
-- changes: same command with `ln -sf` in place of `cp`.)
--
-- ---------------------------------------------------------------------------
-- Step 2: Wire the two hooks into your agentic.setup{}, and call the
--         permission-request patch ONCE before setup.
-- ---------------------------------------------------------------------------
--
-- Case A — you have no `hooks` block yet:
--
--   local td = require('notif_dash_agentic')
--   td.patch_permission_requests()        -- see "Permission prompts" below
--   require('agentic').setup {
--       hooks = {
--           on_response_complete = td.on_response_complete,
--           on_prompt_submit     = td.on_prompt_submit,
--       },
--   }
--
-- Case B — you already have `hooks = {...}` with OTHER keys: just add the
-- two new entries alongside your existing ones, plus the patch call.
--
-- Case C — you already define your own on_response_complete or
-- on_prompt_submit and want to keep yours running too. Chain them:
--
--   local td = require('notif_dash_agentic')
--   td.patch_permission_requests()
--   local mine = my_existing_on_response_complete
--   require('agentic').setup {
--       hooks = {
--           on_response_complete = function(ctx)
--               if mine then mine(ctx) end
--               td.on_response_complete(ctx)
--           end,
--           on_prompt_submit = td.on_prompt_submit,
--       },
--   }
--
-- ---------------------------------------------------------------------------
-- Permission prompts
-- ---------------------------------------------------------------------------
--   Upstream agentic.nvim does not expose a user hook for permission
--   requests (only on_prompt_submit / on_response_complete / on_session_update
--   / on_file_edit / on_create_session_response). So when the agent stops
--   to ask you to allow/deny a tool call, no hook fires and the dashboard
--   stays quiet — exactly the case where you most want a ping, since
--   the agent is now blocked on you.
--
--   `patch_permission_requests()` fixes that by wrapping
--   `agentic.session_manager._build_handlers` so we synthesise a
--   permission-request event into our pipeline:
--     * on request  → task-notify with body "permission: <tool title>"
--                     (urgency=critical, so it bypasses focus suppression)
--     * on response → --ack-source clears it from the dashboard
--
--   Safe to call multiple times — the patch is idempotent (guarded by an
--   internal marker). Call it before agentic.setup{} so the very first
--   session picks it up.
--
-- ---------------------------------------------------------------------------
-- Sanity check after wiring
-- ---------------------------------------------------------------------------
--   1. `task-dashboard` running in another pane.
--   2. Trigger any agentic response, wait for completion → notif with source
--      `agentic:<session_id>` appears in 1-2s.
--   3. Submit another prompt to the same session → notif clears.
--   4. Trigger a tool call that requires a permission prompt (e.g. an edit
--      with permission_mode that prompts) → notif appears immediately,
--      body starts with "permission:". Answer it in nvim → notif clears.
--   5. `:lua print(vim.inspect(require('notif_dash_agentic')))` should show
--      a table with on_response_complete, on_prompt_submit,
--      on_permission_request, and patch_permission_requests.
--
-- ---------------------------------------------------------------------------
-- Non-blocking guarantee:
--   All hooks spawn `task-notify` via `vim.system` with an `on_exit`
--   callback. The callback's presence is what makes vim.system asynchronous
--   (per `:h vim.system` — without it, vim.system waits for the process to
--   exit). The empty callback is intentional; we don't care about the exit
--   status and never call :wait().
--
--   Do NOT replace this with `vim.fn.system` or `io.popen` — both block
--   the nvim UI while task-notify runs.
--
-- ---------------------------------------------------------------------------
-- Hook signatures:
--   This snippet assumes each hook receives a single `ctx` table containing
--   at least `session_id`. on_response_complete is also expected to carry
--   a body field (summary / message / text / response — checked in that
--   order). on_permission_request receives `{session_id, tool_title,
--   tool_kind}` (synthesised by the patch). If your agentic.nvim version
--   names fields differently, adjust `source_of` / `body_of` below.

local M = {}

local function spawn(args)
    vim.system(args, { text = true }, function(_) end)
end

local function source_of(ctx)
    local sid
    if type(ctx) == 'table' then
        sid = ctx.session_id or ctx.id
    end
    if sid == nil or sid == '' then sid = 'unknown' end
    return 'agentic:' .. tostring(sid)
end

local function body_of(ctx)
    if type(ctx) ~= 'table' then return 'response complete' end
    local b = ctx.summary or ctx.message or ctx.text or ctx.response
    if b == nil or b == '' then return 'response complete' end
    local s = tostring(b)
    s = (s:gsub('[\r\n]+', ' '))   -- one-line in the dashboard
    if #s > 200 then s = s:sub(1, 197) .. '...' end
    return s
end

function M.on_response_complete(ctx)
    spawn({ 'task-notify', '--source', source_of(ctx), '--', body_of(ctx) })
end

function M.on_prompt_submit(ctx)
    spawn({ 'task-notify', '--ack-source', source_of(ctx) })
end

-- Synthesised hook for permission requests. Called by the monkey-patch
-- installed via `patch_permission_requests()`, but exposed in M so users
-- can also chain it (mirrors the pattern of the two real hooks).
function M.on_permission_request(ctx)
    local title = 'permission requested'
    if type(ctx) == 'table' and ctx.tool_title and ctx.tool_title ~= '' then
        title = 'permission: ' .. tostring(ctx.tool_title)
    end
    spawn({
        'task-notify',
        '--source', source_of(ctx),
        '--urgency', 'critical',
        '--', title,
    })
end

-- Monkey-patch agentic.session_manager._build_handlers so on_request_permission
-- fires our synthesised hook on entry and an --ack-source when the user picks
-- an option. Idempotent.
function M.patch_permission_requests()
    local ok, SessionManager = pcall(require, 'agentic.session_manager')
    if not ok or type(SessionManager) ~= 'table' then
        return false
    end
    if SessionManager.__notif_dash_patched then
        return true
    end

    local orig = SessionManager._build_handlers
    if type(orig) ~= 'function' then
        return false
    end

    SessionManager._build_handlers = function(self)
        local handlers = orig(self)
        local orig_perm = handlers.on_request_permission
        if type(orig_perm) ~= 'function' then
            return handlers
        end

        handlers.on_request_permission = function(request, callback)
            local sid = (request and request.sessionId)
                or (self and self.session_id)
            local tc = (request and request.toolCall) or {}
            local hook_ctx = {
                session_id = sid,
                tool_title = tc.title,
                tool_kind = tc.kind,
            }
            -- Fire on entry: dashboard shows that the agent is waiting on us.
            pcall(M.on_permission_request, hook_ctx)

            local wrapped = function(option_id)
                -- Fire on resolution: clear the notif. We do this before
                -- delegating to agentic's callback so the dashboard updates
                -- regardless of any downstream errors.
                pcall(spawn, {
                    'task-notify', '--ack-source', source_of(hook_ctx),
                })
                callback(option_id)
            end

            orig_perm(request, wrapped)
        end

        return handlers
    end

    SessionManager.__notif_dash_patched = true
    return true
end

return M
