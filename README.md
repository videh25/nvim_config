# Neovim config

A personal [Neovim](https://neovim.io/) configuration built on top of
[LazyVim](https://github.com/LazyVim/LazyVim), tuned for robotics / ROS
development (C, C++, CMake, Python, Rust) with first-class AI agent integration,
LaTeX, Markdown, and image rendering.

> Bootstrapped from the [LazyVim starter](https://github.com/LazyVim/starter);
> the `origin` remote still points there. Personal changes live on the
> `personal` remote (`github.com/videh25/nvim_config`).

## Requirements

- **Neovim ≥ 0.11** (developed against 0.11.4)
- A **[Nerd Font](https://www.nerdfonts.com/)** for icons
- `git`, `ripgrep`, `fd`, and a **C compiler** (Treesitter parsers / `clangd`)
- **Node.js** — required by several agentic ACP CLIs
- `notify-send` (libnotify) — optional, for desktop notifications from the
  agentic integration
- A terminal with image support (e.g. WezTerm/Kitty) for `snacks.nvim` image
  rendering

External tools (LSPs, linters, formatters) are installed automatically by
[mason.nvim](https://github.com/mason-org/mason.nvim) — see `lua/plugins/mason.lua`.

## Installation

This *is* the config directory. To use it on a fresh machine:

```bash
git clone git@github.com:videh25/nvim_config.git ~/.config/nvim
nvim   # lazy.nvim bootstraps itself, then installs everything
```

On first launch, `lazy.nvim` is cloned automatically (`lua/config/lazy.lua`),
LazyVim and all plugins are installed, and Mason pulls the toolchain. Run
`:Lazy` to manage plugins and `:Mason` to manage external tools.

## Layout

```
init.lua                     -- entry point → require("config.lazy")
lua/config/
  lazy.lua                   -- lazy.nvim bootstrap, colorscheme, update checker
  options.lua                -- autoformat off, custom root_spec
  keymaps.lua                -- (LazyVim defaults; add your own here)
  autocmds.lua               -- (LazyVim defaults; add your own here)
lua/plugins/                 -- one spec per file, auto-imported by lazy.nvim
  agentic.lua                -- AI agent chat (ACP) + custom hooks/notifications
  treesitter.lua             -- parser list
  mason.lua                  -- LSPs, linters, formatters to install
  snacks.lua                 -- image rendering, notifier, picker tweaks
  nabla.lua                  -- LaTeX math popups
  render-markdown.lua        -- in-buffer Markdown rendering (tables, headings)
  example.lua                -- disabled LazyVim example spec (reference only)
lua/notif_dash_agentic.lua   -- glue for an external task-notify/-dashboard tool
lazy-lock.json               -- pinned plugin commits
stylua.toml                  -- Lua formatting (2 spaces, width 120)
```

## What's customized

### AI agents — `lua/plugins/agentic.lua`

Uses [agentic.nvim](https://github.com/carlos-algms/agentic.nvim), an
[ACP](https://agentclientprotocol.com/)-based chat panel. Highlights of the
local customization:

- **Claude** (default) and **Gemini** providers enabled; others (Codex,
  OpenCode, Cursor, Copilot, …) are pre-listed and commented out, ready to
  enable once their CLI is installed.
- **Token/cost usage** rendered in the chat header (captured from
  `usage_update` ACP messages the plugin otherwise drops).
- **Per-session prompt history** scrollback via `<localleader>k` / `<localleader>j`.
- **Permission notifications** — a monkey-patch on the permission manager fires
  a `notify-send` (with the provider's icon) whenever an agent asks to run a
  tool, since the plugin exposes no hook for it. Re-verify after plugin updates.
- Nerd-Font / ASCII spinners and status icons instead of emoji.

Key bindings (leader = `<Space>`, localleader = `\`):

| Key | Mode | Action |
| --- | --- | --- |
| `<C-\>` | n/v/i | Toggle agentic chat |
| `<C-'>` | n/v | Add file/selection to context |
| `<C-,>` | n/v/i | New session |
| `<A-i>r` | n/v/i | Restore session |
| `<leader>ad` / `<leader>aD` | n | Add line / buffer diagnostics |
| `<localleader>q` | n/v/i | Stop generation |
| `<localleader>k` / `<localleader>j` | n/i | Previous / next prompt |

### Languages — `lua/plugins/mason.lua`, `lua/plugins/treesitter.lua`

LSPs, linters and formatters for **bash, C/C++, CMake, Docker, Lua, Vim,
Python, Rust, XML, YAML, Markdown**. Treesitter parsers are pinned to that same
set (plus `diff`, `dtd`, `json`, `toml`, `query`).

### Editing & rendering

- **`render-markdown.lua`** — renders headings, code blocks and pipe tables
  in-buffer. Added specifically because LazyVim's `conceallevel=2` hides inline-code
  backticks, which mis-aligns space-padded Markdown tables; this plugin reflows
  the borders.
- **`nabla.lua`** — popups rendered LaTeX math in `.tex` files on cursor move.
- **`snacks.lua`** — terminal image rendering, 5s notifications, hidden files
  shown in the explorer/picker.

### Rendering showcase

These samples double as a live test for `render-markdown.lua` and the math
rendering — open this file in Neovim and the tables should stay aligned on
every row (not just the cursor line) and the LaTeX should render in place.

**Tables** (alignment markers `:---`, `:--:`, `---:` control column justify):

| Tool | Language | Role | Installed via |
| :--- | :------: | :--- | ------------: |
| `clangd` | C / C++ | LSP | Mason |
| `pyright` | Python | LSP | Mason |
| `rust-analyzer` | Rust | LSP | Mason |
| `ruff` | Python | Linter | Mason |
| `stylua` | Lua | Formatter | Mason |

A compact table with inline code in cells — the case that originally exposed
the conceal misalignment:

| Key | Action |
| --- | --- |
| `<C-\>` | Toggle `agentic` chat |
| `<localleader>k` | Previous prompt |
| `<localleader>j` | Next prompt |

**LaTeX** — math written in `$…$` (inline) or `$$…$$` (display) is rendered by
`nabla.nvim` as an ASCII-art popup. Move the cursor onto the expression and the
popup appears — no keybinding, no external tools (it draws the math itself via
the `latex` Treesitter parser). Examples:

$$
\nabla \cdot \mathbf{B} = 0
\qquad
\nabla \times \mathbf{E} = -\frac{\partial \mathbf{B}}{\partial t}
$$

$$
\hat{x}_{k} = \hat{x}_{k}^{-} + K_k \left( z_k - H \hat{x}_{k}^{-} \right)
$$

> The same `nabla.nvim` popup works in `.tex`/`.latex` files and in Markdown —
> see `lua/plugins/nabla.lua`. It needs the `markdown`, `markdown_inline`, and
> `latex` Treesitter parsers (all in `lua/plugins/treesitter.lua`).

### Behavior tweaks — `lua/config/`

- Format-on-save is **disabled** (`vim.g.autoformat = false`).
- Custom `root_spec` prefers a `.git` + `lua` directory marker.
- Default colorscheme: **tokyonight**.

## Conventions

- Lua is formatted with [StyLua](https://github.com/JohnnyMorganz/StyLua)
  (`stylua.toml`: 2-space indent, 120 column width).
- Each plugin gets its own file under `lua/plugins/`; lazy.nvim imports them
  automatically. The header comment in each spec explains *why* the plugin is
  there.
- Plugin versions are pinned in `lazy-lock.json` — commit it after `:Lazy update`.

## CI

`.github/workflows/dispatch_update.yaml` dispatches a `repository_dispatch`
event to [`videh25/ros-development-images`](https://github.com/videh25/ros-development-images)
on every push to `main`, so the development container images rebuild with the
latest config.

## License

[Apache-2.0](./LICENSE).
