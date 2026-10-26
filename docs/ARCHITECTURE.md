# QuanVim architecture audit

Audit date: 2026-10-25. Source: `~/.config/QuanVim`, commit `394859cc` on `main` (PR #2 merged). Companion documents: [feature inventory](FEATURE_INVENTORY.md), [roadmap](ROADMAP.md).

## Evidence and boundaries

- **Verified** means read directly from the local source, installed lazy.nvim source, or configuration files. It does not imply a feature was exercised interactively during this audit.
- **Inference** means a likely consequence of that code; runtime ordering or a real project may still need checking.
- **Decision** means a policy choice for the owner, not an approved implementation change.

This is a static, read-only investigation with documentation output. No configured editor startup, plugin installation, configuration migration, or implementation refactor was run. Normal startup is not read-only: it can install plugins, parsers, and tools and rewrite JSON/lock state. Earlier startup tests and 447 passing checks belong to the PR #2 investigation, not a fresh verification of the 2026-10-25 configuration.

**Historical audit finding (2026-10-25):** the isolated `lua/config/lazy.lua` and `lua/plugins/LazyVim.lua` named `LazyVim/LazyVim`, not `andr515i/QuanVim`. Its lockfile named upstream LazyVim at `999700997f72227187d49d8b92667183dc7fc809`, with no QuanVim entry. Installed directories for both distributions existed; directory presence did not prove which was running. The audit intentionally did not change this mismatch.

**October 26 follow-up:** the isolated configuration was corrected to select `andr515i/QuanVim`. Runtime verification through lazy.nvim confirmed that QuanVim was loaded and upstream LazyVim was absent from the resolved plugin registry and runtimepath. The historical finding above remains part of this audit; it describes the state at the audit snapshot, not the corrected current state.

## Two repositories, two entry points

The distribution is a plugin and collection of plugin specifications. The working configuration is its consumer. They are not interchangeable.

```text
NVIM_APPNAME=quanvim
  ~/.config/quanvim/init.lua
    require("config.lazy")
      bootstrap lazy.nvim under stdpath("data")/lazy
      lazy.setup(spec = { distribution import, personal plugins import })
        discover and combine plugin specifications
        distribution config.init(): early options + extras machinery
        distribution setup(): theme + deferred setup
        plugin loading: eager startup, events, filetypes, commands, keys, require()
```

The distribution's root [init.lua](../init.lua) prints “Do not use this repository directly” and quits. It is a guard, not a bootstrap. [lua/lazyvim/init.lua](../lua/lazyvim/init.lua) supplies the `setup(opts)` used when lazy.nvim configures the distribution plugin. Keep this distinction visible in installation instructions.

The isolated config sets lazy.nvim's `defaults.lazy = false` and `version = false`. This does **not** make every plugin eager: lazy.nvim infers lazy loading when a spec has `event`, `ft`, `cmd`, or `keys` unless explicitly overridden. `init` callbacks still run during startup even for lazy plugins. `require()` can also load an available plugin. A plugin spec's presence, installation, initialization, and full loading are four different states.

`NVIM_APPNAME` separates standard config/data/state/cache locations. It does not isolate arbitrary paths: personal `options.lua` explicitly uses `~/.vim/undodir`, and user commands can invoke external programs.

## Startup phases and why order matters

1. **Bootstrap:** consumer `init.lua` requires `config.lazy`; that file installs lazy.nvim only if absent, prepends its runtime directory, and calls `lazy.setup`. The imported distribution and personal plugin specs are separate entries.
2. **Spec discovery:** lazy.nvim scans direct modules of an import, sorts module names, executes their returned tables, and recursively processes explicit imports/dependencies/specs. A nested directory is not automatically an enabled feature merely because it exists. Its `init.lua` or an explicit import makes it reachable.
3. **Distribution entry:** [plugins/init.lua](../lua/lazyvim/plugins/init.lua) checks Neovim >= 0.11.2, calls `config.init()`, and declares QuanVim (priority 10000, eager) and Snacks (priority 1000, eager). The global `LazyVim` namespace is established by [config/init.lua](../lua/lazyvim/config/init.lua).
4. **Early config:** `config.init()` adds the QuanVim plugin directory to runtimepath **while specs are still being imported**. It queues early notifications, loads distribution options then personal options, records selected option defaults, temporarily clears clipboard integration, wraps lazy.nvim import handling, and loads `lazyvim.json`.
5. **Extras import:** [plugins/xtras.lua](../lua/lazyvim/plugins/xtras.lua) combines JSON selections and provider defaults, handles renames, deduplicates and priority-sorts imports. It is reached as a direct module of `lazyvim.plugins`.
6. **Actual plugin startup:** lazy.nvim runs plugin `init` callbacks, then eager plugins in priority order. QuanVim's `setup` merges its distribution options, loads autocmds immediately if a file was supplied, chooses the theme, and registers deferred work. Theme failure is reported before falling back to habamax; it is not silently ignored.
7. **Deferred setup:** on `User VeryLazy`, QuanVim loads remaining autocmds and keymaps, restores clipboard, sets up formatting/root/news, creates `LazyExtras` and `LazyHealth`, and checks import order. The installed lazy.nvim schedules this after `LazyDone`/UI entry; ordinary headless startup can miss it.
8. **File/insert/command phases:** `LazyFile` aliases `BufReadPost`, `BufNewFile`, and `BufWritePre`; LSP itself uses `BufReadPre`/`BufNewFile`. Completion uses `InsertEnter`/`CmdlineEnter`. Other features load on their declared triggers. Neither `VeryLazy` nor `LazyFile` is a built-in Neovim event name.

PR #2 corrected the phase-4 lookup from `spec.plugins.LazyVim` to `spec.plugins.QuanVim`, plus news/changelog lookups. Without early runtime registration, `vim.loader.find(extra)[1]` could be absent and [util/plugin.lua](../lua/lazyvim/util/plugin.lua) passed a nil path to `loadfile`. The startup regression slice now guards missing extras explicitly: its diagnostic names the module and runtimepath rather than calling `loadfile(nil)`. See [local test commands and boundaries](../CONTRIBUTING.md#local-quanvim-regression-tests).

## How customization actually composes

Two mechanisms coexist:

| Mechanism | Distribution location | Consumer customization | Important limit |
| --- | --- | --- | --- |
| Editor options | `config/options.lua` | `lua/config/options.lua` runs afterward | Later plugins/ftplugins can change options again |
| Global keymaps | `config/keymaps.lua` | `lua/config/keymaps.lua` runs afterward | Later buffer-local LSP/plugin maps can win |
| Autocmds | `config/autocmds.lua` | `lua/config/autocmds.lua` runs afterward | Adding a competing callback does not delete the original |
| Plugin behavior | `plugins/*.lua`, extras | Later specs for the same plugin identity | `opts` merges; `config` replacement replaces setup logic |
| Distribution options | `config/init.lua` defaults | QuanVim plugin `opts` | Only applies if the override targets the correct plugin name |
| Feature selection | `plugins/xtras.lua`, default groups | `lazyvim.json`, explicit imports, `vim.g.lazyvim_*` | History (`install_version`) affects defaults |
| Project-local specs | lazy.nvim's local-spec discovery | `.lazy.lua`, when enabled | Another policy source beyond the two repositories |

The loader [config.load](../lua/lazyvim/config/init.lua) emits `User LazyVimOptionsDefaults`/`LazyVimOptions` (and equivalent Keymaps/Autocmds events). `defaults.keymaps = false` and `defaults.autocmds = false` disable distribution sets while preserving personal files. Options are deliberately early and do not have that ordinary switch; the source documents preloading `package.loaded["lazyvim.config.options"] = true` as a bypass.

lazy.nvim merges fragments by resolved plugin name. Tables generally merge as maps, but list semantics differ: `opts_extend` names lists to append; `opts = function(_, opts)` can mutate inherited options or return a replacement. `keys` has its own mode/key identity handling and supports disabling inherited mappings. A later `config` function is not an additional hook. For example, personal `plugins/snacks.lua` replaces the distribution's notification-preserving setup function, even if its merged `opts` remain useful.

Recommended customization practice: prefer the nearest existing plugin's `opts`, use its existing list extension behavior, and replace `config` only when taking ownership of its full setup contract. No new settings framework is needed to express these cases.

## Extras are feature bundles, not just optional plugins

Each extra returns lazy.nvim specs and sometimes imports other extras. It can add parsers, LSP servers, Mason tools, formatting rules, keys, and conditional integrations at once. For example, Angular imports TypeScript, modifies its server, adds parsers, and can integrate Prettier. .NET adds C#/F# tooling and extends DAP/neotest **only if those plugins are present**. `optional = true` means “extend this plugin if another spec provides it,” not “install everything mentioned here.”

[config.get_defaults](../lua/lazyvim/config/init.lua) chooses one provider per group:

- New-install order: Snacks picker, Blink completion, Snacks explorer.
- Install history before version 8: FzfLua and Neo-tree move to the front; completion still prefers Blink.
- A valid `vim.g.lazyvim_picker`, `vim.g.lazyvim_cmp`, or `vim.g.lazyvim_explorer` takes precedence; otherwise enabled/imported matching extras are considered before fallback.
- TypeScript registers another provider group (vtsls versus tsc). Language selection is not all controlled in one file.

Today's personal JSON has `version = 8` and `install_version = 7`. These are different: schema version versus preserved default history. It explicitly selects 11 extras, but the effective imports also include default providers and transitive imports.

`recommended` metadata powers suggestions based on the current buffer/filetype/root; it does not automatically install every matching language. [util/extras.lua](../lua/lazyvim/util/extras.lua) builds the Extras UI by walking sources, executing imports through temporary lazy specs, and evaluating recommendation functions. This is executable introspection, not a passive manifest. It uses private lazy view/spec APIs and a mutable `handle_defaults` flag. UI toggles write JSON and request a restart. Imported dependency extras can be shown as unmanaged rather than independently removable.

## Main runtime relationships

```text
global LazyVim -> util facade -> lazy.core.util + lazily required util modules
      |                     -> config/root/pick/format/cmp/treesitter/lsp
      + plugin specs ------> Snacks ----------------> UI, keymaps, LSP events,
      |                                            terminal, picker, debug
      + LSP config --------> native vim.lsp.config / vim.lsp.enable
      |                     + mason-lspconfig -----> tools/server installation
      + format registry ---> Conform primary + native LSP fallback
      + Treesitter --------> parsers, queries, highlight/indent/fold attachment
```

**Options/keymaps/autocmds:** simple Lua remains the configuration language, but shared mappings call helpers and Snacks. `safe_keymap_set` avoids overwriting lazy key handlers and delegates to Snacks keymap setup. LSP maps are buffer/capability-aware and attach later, so “personal runs last” is only true within a phase.

**LSP:** [plugins/lsp/init.lua](../lua/lazyvim/plugins/lsp/init.lua) combines `opts.servers`, diagnostics and feature controls, registers per-server keys, and uses native Neovim LSP APIs. `servers["*"]` supplies common capabilities/maps; `setup[server]` returning true delegates ownership to another integration (Java/Rust). Mason supplies server binaries and other tools, not the language protocol itself. LSP attach and capability callbacks use Snacks. Language support also needs a real project and external runtime/toolchain; a passing import does not prove server attachment.

**Formatting/linting:** [util/format.lua](../lua/lazyvim/util/format.lua) owns format-on-save, global/buffer enable flags, manual format and status commands, and formatter priority. Conform registers as the primary formatter; LSP registers a fallback. The Conform setup explicitly warns against replacing its `config` or enabling a second save hook. nvim-lint independently debounces file/read/insert-leave events and reports diagnostics. Mason can install both sets of tools.

**Completion/snippets:** Blink and nvim-cmp are alternative provider bundles. `util/cmp.lua` also supplies snippet actions and AI acceptance shared beyond nvim-cmp. Blink config can call native snippets, LuaSnip, compatibility sources, and LazyDev. The personal config chooses LuaSnip directly without selecting the full distribution LuaSnip extra; those are different levels of integration.

**Themes:** Tokyonight/Catppuccin are lazy specs; distribution `opts.colorscheme` chooses what to load. Personal `colors/chromognome.lua` requires a palette/highlight implementation in `lua/user/themes/chromognomev2`; its registered color name is `chromognome_dark`. `ReloadChromo` invalidates three Lua modules. Colorscheme name mismatch and plugin-specific highlight overrides need checking when packaging it, not a loader rewrite.

**Roots and pickers:** root detection tries LSP workspaces, marker directories (`.git`, `lua`), then cwd, with per-buffer cache invalidation. Pickers and terminals use it, while personal Java and runner modules have separate root rules. `LazyRoot` and `LazyFormatInfo` already offer useful explanations. `LazyVim.pick` registers one default backend; direct `Snacks.picker.*` calls can intentionally bypass it.

## Maintainability assessment

| Finding | Evidence / consequence | Assessment |
| --- | --- | --- |
| Distribution identity has several meanings | Git repo/plugin key `QuanVim`; Lua/global/event/schema names `lazyvim`/`LazyVim`; README/CI/VSCode still upstream | Verified. Separate functional references from cosmetic branding; do not bulk-rename |
| Global util facade hides ownership | `util/init.lua` proxies unknown fields to `lazy.core.util`, deprecated adapters, or required submodules | Verified; convenient but difficult to navigate. Document first, replace only touched dependencies |
| lazy.nvim internals are modified | `util/plugin.lua` wraps `Plugin.Spec.import` and `Meta.add`; Extras UI uses `lazy.view.*` | Verified tight coupling. Avoid a second plugin manager, protect this seam with focused tests |
| Provider selection depends on install history | `install_version`, globals, JSON, explicit imports, transitive bundles | Verified. Explicit owner choices would improve predictability without removing alternatives |
| Configuration has side effects at several phases | parse-time imports, eager `init`, `config`, deferred event callbacks | Verified. Avoid treating specs as pure data or startup as read-only |
| Snacks is infrastructure in the current design | Options, LSP maps, utility modules, UI and editor keys depend on it | Verified. Disabling its picker is not equivalent to removing Snacks |
| Compatibility is mixed with live behavior | renamed extras/repos, old JSON migration, deprecated facade, version branches | Verified. Audit callers and supported versions before retiring anything |
| Local dead-code candidates exist | `root.pretty_path()` returns empty string; injection upvalue helpers have no source callers found | Verified local search only. External configurations may still call them; not deletion authorization |
| Regression coverage | extras/utility checks plus disposable startup consumers | Startup identity, phases, overrides, providers and optional integrations are covered; real UI, root workflows and external tools still need interactive checks |
| CI ownership is still upstream-oriented | workflow passes `plugin: LazyVim`, `repo: LazyVim/LazyVim` to a reusable upstream workflow | Verified inputs; actual remote workflow behavior was not fetched. Do not claim it tests this fork correctly |

The codebase has useful boundaries already: config, specs, optional bundles, and support modules. **Inference:** a gradual clarification of policy and dependency ownership will buy more maintainability than an early directory/namespace rewrite. The 115 extras files account for 9,994 of 15,274 Lua lines, but unselected files are not automatically loaded at startup. A smaller supported surface and fewer active choices are different goals from deleting source lines.

## Recommended shape, without a rewrite

Keep lazy.nvim for installation, spec merging, and loading. Keep current public Lua import names while stabilizing the fork. Treat these as the four navigable layers:

1. **Bootstrap/selection:** one consumer entry selects QuanVim; explicit provider policy identifies picker, explorer, completion, tool installation, formatting and supported versions.
2. **Editor policy:** existing `config/` owns options, global keys and autocmds. Each policy has one authoritative control with visible local overrides.
3. **Feature bundles:** existing `plugins/` files describe default editor behavior; `plugins/extras/` contains opt-in language/workflow integrations. Preserve useful bundles and conditional DAP/test hooks. Change whether a feature is default independently of whether its implementation is retained.
4. **Integration helpers:** keep root, formatting, LSP and parser lifecycle helpers where they prevent real duplication. Prefer explicit local imports for new work; avoid growing the catch-all facade or inventing a generic service/container/event framework.

A future curated core may explicitly import its modules instead of relying on directory scanning, but only after startup/override tests exist. It should still return ordinary lazy.nvim specs and preserve consumer imports during transition. Personal theme, snippet and runner migration should be separate opt-in slices. The [roadmap](ROADMAP.md) ranks those decisions and their regression risks.
