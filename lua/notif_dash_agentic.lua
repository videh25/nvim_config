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
-- Step 2: Wire the two hooks into your agentic.setup{}
-- ---------------------------------------------------------------------------
--
-- Case A — you have no `hooks` block yet:
--
--   local td = require('notif_dash_agentic')
--   require('agentic').setup {
--       hooks = {
--           on_response_complete = td.on_response_complete,
--           on_prompt_submit     = td.on_prompt_submit,
--       },
--   }
--
-- Case B — you already have `hooks = {...}` with OTHER keys: just add the
-- two new entries alongside your existing ones.
--
-- Case C — you already define your own on_response_complete or
-- on_prompt_submit and want to keep yours running too. Chain them:
--
--   local td = require('notif_dash_agentic')
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
-- Sanity check after wiring
-- ---------------------------------------------------------------------------
--   1. `task-dashboard` running in another pane.
--   2. Trigger any agentic response, wait for completion → notif with source
--      `agentic:<session_id>` appears in 1-2s.
--   3. Submit another prompt to the same session → notif clears.
--   4. `:lua print(vim.inspect(require('notif_dash_agentic')))` should show
--      the table with both functions.
--
-- ---------------------------------------------------------------------------
-- Non-blocking guarantee:
--   Both hooks spawn `task-notify` via `vim.system` with an `on_exit`
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
--   order). If your agentic.nvim version names fields differently, adjust
--   `source_of` / `body_of` below.

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

return M
