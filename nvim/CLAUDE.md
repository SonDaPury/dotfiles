# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration (Lua, using the `lazy.nvim` plugin manager). There is no build step, test suite, or application logic — "correctness" means the config loads without error and the intended keymaps/plugins behave as configured.

## Commands

- **Validate the config loads cleanly** (no errors on startup): `nvim --headless -c 'quitall'` then check `echo $?` — this is the pattern already used for sanity checks in this repo (see `.claude/settings.local.json`).
- **Sync/install/update plugins**: open Neovim and run `:Lazy` (UI), or `:Lazy sync` / `:Lazy update` / `:Lazy clean`.
- **Install/manage LSP servers, formatters, linters, DAP adapters**: `:Mason`.
- **Diagnose environment/plugin issues**: `:checkhealth`.
- After editing any Lua file under `lua/`, restart Neovim (or `:source %` the affected file, though full restart is safer since `lazy.nvim` specs are collected at startup).

## Architecture

**Load order** — `init.lua` requires four modules in order: `config.keymaps` → `config.options` → `config.autocmds` → `config.lazy`. `config.lazy` bootstraps `lazy.nvim` itself (git-clones it if missing) and then calls `require("lazy").setup({ spec = { { import = "plugins" } } })`, which auto-loads every file under `lua/plugins/`. Each file there returns a list of lazy.nvim plugin specs — that's the only mechanism for registering a plugin; add a plugin by adding a spec to an existing `lua/plugins/*.lua` file or creating a new one (no other file needs to change).

`lazy-lock.json` pins exact plugin commits for reproducibility; treat it like a lockfile (commit it alongside plugin spec changes).

**LSP** (`lua/plugins/lsp.lua` + `lua/config/lsp/`):
- `lua/config/lsp/servers.lua` is the single source of truth for which LSP servers are installed and how they're configured — it's a table keyed by server name. Adding a server = adding one key to this table; `mason-lspconfig`'s `ensure_installed` and `vim.lsp.config(name, opts)` are both driven off `vim.tbl_keys(servers)`.
- `lsp.lua`'s `config()` merges `blink.cmp` completion capabilities into every server's `opts.capabilities` before calling `vim.lsp.config`.
- Gotcha: `servers.lua` grabs `vim.lsp.config.eslint.on_attach` (the default eslint on_attach that registers `LspEslintFixAll`) into a local *before* `lsp.lua` overwrites `eslint`'s config — and wraps it. Overwriting this ordering causes infinite recursion; if you touch eslint config, preserve the capture-then-wrap pattern.
- LSP-attached keymaps (`lua/config/lsp/keymaps.lua`) are bound inside an `LspAttach` autocmd and go through `lspsaga.nvim` (peek_definition, finder, hover_doc, rename, code_action) rather than Neovim's built-in `vim.lsp.buf.*`. Diagnostic navigation keymaps are bound unconditionally (not gated on LspAttach) since diagnostics can also come from `nvim-lint`.
- Default diagnostic virtual text is disabled (`vim.diagnostic.config({ virtual_text = false })`) because `tiny-inline-diagnostic.nvim` renders it instead.

**Formatting** (`lua/plugins/format.lua`): `conform.nvim`, format-on-save with `lsp_fallback = true`. Add a filetype by adding an entry to `formatters_by_ft`.

**Linting** (`lua/plugins/lint.lua`): `nvim-lint`, triggered on `BufWritePost`/`InsertLeave`. `linters_by_ft` is currently empty — enabling a linter for a filetype means adding an entry there.

**Debugging** (`lua/plugins/dap.lua`): `nvim-dap` + `nvim-dap-ui`, adapters installed via `mason-nvim-dap` (`ensure_installed = { "js-debug-adapter", "codelldb" }`). JS/TS/JSX/TSX all share the `pwa-node`/`pwa-chrome` adapter configured through `nvim-dap-vscode-js` (mason-nvim-dap has no automatic handler for `js-debug-adapter`, hence the extra plugin). C/C++ share a `codelldb` config (`dap.configurations.c = dap.configurations.cpp`). Keymaps live under `<leader>d*`.

**File explorer** (`lua/plugins/navigation.lua`): `neo-tree.nvim`, toggled with `<leader>e` / revealed with `<leader>E`. `filesystem.follow_current_file.enabled = true` keeps the tree auto-scrolled/highlighted to whatever file is active in the buffer; `leave_dirs_open = true` means previously expanded directories stay expanded as you move to other files instead of auto-collapsing.

Gotcha — **neo-tree's buffer bypasses normal buffer-open events**: it creates its buffer via `nvim_create_buf()` + `nvim_buf_set_name()` and assigns `filetype = "neo-tree"` directly through the Lua API (`neo-tree/ui/renderer.lua`'s `get_buffer`), never through `:edit`. This means `BufReadPre`/`BufNewFile` never fire for it, so any plugin lazy-loaded on those events (and only registering its neo-tree exclusion inside `config()`) can lose the race if neo-tree opens before any real file has been read in that session. Also, neo-tree *reuses* the same buffer across toggles, so a one-shot `FileType` autocmd only fires once for that buffer's whole lifetime — fine for buffer-local state, not enough for window-local state (see Folding below). Any new plugin that needs to special-case neo-tree should register its exclusion in `init()` (runs eagerly at startup, independent of lazy-load triggers), and use `BufEnter`/`BufWinEnter` + a `vim.bo.filetype` check (mirroring what neo-tree itself does internally) rather than a `FileType` pattern autocmd if the thing being toggled is a window-local option.

**Markdown rendering** (`lua/plugins/markdown.lua`): `render-markdown.nvim` decorates headings/bullets/tables/code blocks/checkboxes directly in the buffer via treesitter (no browser or Node.js involved). Lazy-loaded on `ft = "markdown"`, starts `enabled = false` per-buffer, toggled with `<leader>mp` (`:RenderMarkdown toggle`).

**Folding** (`lua/plugins/fold.lua`): `nvim-ufo` (+ `promise-async` dependency) replaces native folding. `init()` sets `foldcolumn = "1"`, `foldlevel = 99`, `foldlevelstart = 99` so every fold starts open on file load; `provider_selector` uses `treesitter` with `indent` as fallback. `zR`/`zM` are rebound to `ufo.openAllFolds()`/`ufo.closeAllFolds()` (required — native `zR`/`zM` don't know about ufo's fold state), and `zK` previews a closed fold's contents without opening it. Unbound fold commands (`za`, `zo`, `zc`, `zj`, `zk`, ...) keep working natively. `foldcolumn`/`foldenable` are window-local options with a global fallback, and neo-tree never resets them for its own sidebar window — so `init()` also registers a `BufEnter`/`BufWinEnter` autocmd (checking `vim.bo.filetype == "neo-tree"`/`"neo-tree-popup"`) that sets `vim.opt_local.foldcolumn = "0"` / `foldenable = false` on *every* entry into a neo-tree window, not just once — required because neo-tree can tear down and recreate the window (toggle close/open) while reusing the same buffer, and a window-local option set on the old window doesn't carry over to the new one.

**Indent scope** (`lua/plugins/ui.lua`): `mini.indentscope` draws a vertical line marking the indent scope containing the cursor, with animation disabled (`gen_animation.none()`) so it appears instantly. The `FileType` autocmd that sets `vim.b.miniindentscope_disable = true` on UI/panel filetypes (`neo-tree`, `help`, `lazy`, `mason`, `qf`, etc. — the same list `autocmds.lua` uses for its `q`-to-close binding, plus a few extra panel filetypes) lives in the plugin's `init()`, not `config()` — see the neo-tree gotcha above; registering it in `config()` missed neo-tree buffers opened before the plugin's `BufReadPre`/`BufNewFile` lazy-load trigger had fired. Complements — doesn't replace — `indent-blankline.nvim`, whose own `scope` is kept disabled to avoid double-rendering.

**Colorscheme**: `dracula.nvim` loads eagerly (`lazy = false, priority = 1000`) as the startup default; all other themes are `lazy = true` and only activated through the `themery.nvim` picker (`<leader>th`), which persists the chosen theme across restarts.

**Session persistence** (`lua/plugins/session.lua`) is currently disabled — the file returns `{}`; the `auto-session` spec is present but commented out.

## Conventions

- Inline comments in config files are written in Vietnamese explaining the *why* (e.g. ordering gotchas, non-obvious workarounds) — match this style when editing existing files.
- Custom keymaps of note: leader is `<Space>`; `jj` → Esc in insert mode; `x`/`c` (normal & visual) delete into the black-hole register instead of yanking; `ss`/`sv` for horizontal/vertical split; `<C-s>` saves; `sa`/`sd`/`sr` are `nvim-surround` add/delete/replace (bound manually via `<Plug>` mappings since `nvim_surround_no_mappings = true` disables the plugin's defaults).
