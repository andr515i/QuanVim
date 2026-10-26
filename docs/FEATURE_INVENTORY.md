# QuanVim feature inventory

Snapshot: 2026-10-25, source `394859cc`. Read with [architecture](ARCHITECTURE.md) and [roadmap](ROADMAP.md). **V** = verified in code/files, **I** = inference needing runtime confirmation, **D** = owner decision. “Configured” is evidence of intent, not usage telemetry or proof a plugin is loaded.

## Scope and classification

The distribution has **150 Lua files / 15,274 lines**: **115 extras files / 9,994 lines**, plus **35 other Lua files / 5,280 lines**. Counts include comments and blank lines. The personal lockfile has **60 entries**; a lockfile is not an active-plugin list. At the audit snapshot its source entry pointed upstream, as detailed in ARCHITECTURE.md; the October 26 follow-up corrected the isolated consumer and verified QuanVim through lazy.nvim. There are no runtime/plugin-count or startup-performance measurements from this audit.

Classifications describe responsibility, not removal recommendations:

- **Infrastructure:** needed for the current loading/customization contract. Some dependencies could be replaced later, but are not independently removable now.
- **Default editor:** useful behavior shipped by default, with personal choices layered above it.
- **Optional:** available bundles/integrations, including some selected automatically as default providers.
- **Compatibility/legacy:** supports existing consumers, older config formats/APIs, or platform/version differences. Optional and old do not mean useless.
- **Complexity candidate:** a mechanism or overlap to investigate; evidence and affected users must precede removal.

## Distribution subsystems

Paths below are under `lua/lazyvim/` unless otherwise stated.

| Subsystem / classification | Responsibility and dependencies | Configuration / entry points |
| --- | --- | --- |
| Bootstrap and plugin lifecycle / infrastructure | Consumer bootstrap + lazy.nvim; fork eager setup, Lua module caching, spec discovery and merging | Consumer `init.lua`, `config/lazy.lua`; distribution [plugins/init.lua](../lua/lazyvim/plugins/init.lua), [config/init.lua](../lua/lazyvim/config/init.lua) |
| Options and phases / infrastructure + default editor | Native options, early clipboard deferral, leader keys, per-phase events | `config/{options,keymaps,autocmds}.lua`; consumer matching files; distribution `defaults` opts |
| Extras / infrastructure for current feature selection | Default groups, JSON, priorities, rename interception; private lazy spec/meta/view APIs | `plugins/xtras.lua`, `util/{plugin,extras,json,inject}.lua`; `lazyvim.json`, `vim.g.lazyvim_*`, `vim.g.xtras_prios` |
| Root detection / infrastructure shared by features | Native LSP workspaces, filesystem markers, cwd, cache | `util/root.lua`; `vim.g.root_spec`, `vim.g.root_lsp_ignore`, `LazyRoot` |
| LSP / default editor | Native `vim.lsp`, nvim-lspconfig definitions; Mason/mason-lspconfig install/enable servers; Snacks capability-aware callbacks | `plugins/lsp/{init,keymaps}.lua`, `util/lsp.lua`; `opts.servers`, `opts.setup`, `diagnostics`, hints/folds/codelens |
| Formatting / default editor | Central save callback + formatter registry; Conform primary, native LSP fallback | `plugins/formatting.lua`, `util/format.lua`; `formatters_by_ft`, `vim.g.autoformat`, `vim.b.autoformat`, `LazyFormat`, `LazyFormatInfo` |
| Linting / default editor | nvim-lint with debouncing, conditional/global/fallback linters | `plugins/linting.lua`; `opts.linters_by_ft`, `opts.linters`, `opts.events` |
| Syntax, indent, folds / default editor | Treesitter main branch, external CLI/compiler, parser/query installation and native attachment; textobjects and autotag | `plugins/treesitter.lua`, `util/treesitter.lua`, root `queries/lua/highlights.scm`; feature flags/ensure lists |
| Completion / default-provider bundle | Blink or nvim-cmp; buffer/path/LSP/snippets, LazyDev, optional AI and compatibility sources | `extras/coding/{blink,nvim-cmp}.lua`, `util/cmp.lua`; `vim.g.lazyvim_cmp`, plugin `opts` |
| Snippets / default native path + optional engines | Native snippets by default; LuaSnip/mini-snippets alternatives and source integrations | `extras/coding/{luasnip,mini-snippets}.lua`, `util/cmp.lua`; engine preset/source config |
| Editing / default editor | mini.pairs, mini.ai, ts-comments, Flash, which-key; native edits and Snacks buffer operations | `plugins/coding.lua`, `plugins/editor.lua`, `util/mini.lua`, default keymaps; plugin opts/keys/enabled |
| Search / default editor + provider bundle | GrugFar search/replace; TODO comments; FzfLua/Telescope/Snacks picker; rg/fzf/fd as applicable | `plugins/editor.lua`, `extras/editor/*picker*`, `fzf.lua`, `telescope.lua`, `util/pick.lua`; `vim.g.lazyvim_picker` |
| Explorer / default-provider bundle | Snacks explorer or Neo-tree; alternative mini.files available | `extras/editor/{snacks_explorer,neo-tree,mini-files}.lua`; `vim.g.lazyvim_explorer` |
| Git / default editor + optional workflows | Gitsigns, Snacks lazygit/gitbrowse/log picker; external git/lazygit | `plugins/editor.lua`, `config/keymaps.lua`; optional Diffview/Octo/GitUI/etc. through personal specs/extras |
| Diagnostics UI / default editor | Native diagnostics, Trouble views; Noice LSP presentation, statusline integration | `plugins/{editor,ui}.lua`, LSP diagnostics opts, `vim.g.trouble_lualine` |
| UI and notifications / default editor + shared infrastructure | Snacks input/notifier/indent/scope/scroll/statuscolumn/dashboard; Noice + Nui; bufferline, lualine; mini.icons shim for devicons API | `plugins/ui.lua`, `util/lualine.lua`, `config/options.lua`; Snacks/plugin opts; theme highlights |
| Themes / default editor + personal options | Tokyonight default loader, Catppuccin alternate/integration patches | `plugins/colorscheme.lua`; QuanVim plugin `opts.colorscheme`; personal `colors/` |
| Terminals/scratch/profiling / default editor | Snacks terminal/scratch/profiler/zen/zoom, root-aware commands; platform shell handling | `plugins/util.lua`, `config/keymaps.lua`, `util/terminal.lua`; shell and Snacks opts |
| Sessions / default editor | persistence.nvim saves session state; native session options | `plugins/util.lua`, dashboard and `<leader>q*`; plugin opts |
| Health/news / supporting infrastructure | Health checks external tools/parser build dependencies; news hashes in JSON; changelog buffer | `health.lua`, `util/news.lua`; `LazyHealth`, `checkhealth lazyvim`, news opts |
| AI, tests, debugging / optional | Provider-specific AI plugins; neotest + adapters; nvim-dap + UI/adapters | `extras/{ai,test,dap}/`, language-specific optional fragments; toolchains/credentials/projects required |
| Types/docs/tests/workflows / maintenance | Lua annotations, existing help/reference, extras validity tests, memoization tests, reusable upstream CI | `types.lua`, `doc/LazyVim.txt`, `tests/`, `scripts/test`, `.github/workflows/` |

Keep these distinctions: a parser is not an LSP server; Mason is not an LSP client; Conform and nvim-lint do different jobs; Trouble is a presentation/navigation layer, not another diagnostic producer. Avoid combining them merely because all are language-related.

## Support module navigation

| Module | Why it exists / coupling to know |
| --- | --- |
| `util/init.lua` | Global facade, lazy module lookup, forwards lazy utility functions, plugin opts/lookup, keymap protection, notifications and safe default setting |
| `util/plugin.lua` | Wraps lazy import/meta operations, renames/deprecations, default filtering, `LazyFile` alias |
| `util/inject.lua` | Function wrapper plus debug upvalue helpers; upvalue helpers have no callers found within distribution Lua |
| `util/extras.lua` | Discovers bundles and renders/toggles Extras UI through lazy private UI/spec APIs |
| `util/json.lua` | Stable-key custom JSON encoder, save and historical schema migrations |
| `util/deprecated.lua` | Old helper names forward to Snacks/current helpers; compatibility cost, not automatically obsolete |
| `util/root.lua`, `util/pick.lua` | Shared project roots and one selected picker backend |
| `util/format.lua`, `util/lsp.lua` | Format arbitration and LSP actions/config helpers |
| `util/cmp.lua`, `util/mini.lua` | Shared snippet/acceptance actions, completion workarounds, mini integration/textobjects |
| `util/treesitter.lua` | Installed-query checks, safe expressions, compiler/CLI checks and asynchronous build coordination |
| `util/lualine.lua` | Root/path/status components and optional backend status |
| `util/terminal.lua` | Shell setup, especially PowerShell; actual terminals are provided by Snacks |
| `util/news.lua` | News/changelog display and change hashing |

## Personal feature selections

**V:** isolated and old `lazyvim.json` both list the following 11 extras and retain `install_version = 7`. These rows describe the audited **fork's** implementations; the October 25 upstream-pointing consumer was not proof these exact implementations were loaded. The October 26 follow-up verified the corrected isolated consumer loads QuanVim.

| Extra | Bundled functionality / dependencies |
| --- | --- |
| `coding.mini-comment` | mini.comment + nvim-ts-context-commentstring; overlaps native/ts-comments comment support |
| `coding.mini-surround` | mini.surround, `gsa/gsd/gsr/...` lazy mappings |
| `lang.angular` | angularls; imports TypeScript; Angular/SCSS parsers; vtsls plugin path via Mason; optional Prettier integration |
| `lang.docker` | Dockerfile parser, dockerls/compose servers, hadolint install/lint; optional none-ls integration |
| `lang.dotnet` | C#/F# parsers; OmniSharp + extended definitions, fsautocomplete; csharpier/fantomas/netcoredbg tools; conditional DAP/neotest/none-ls |
| `lang.java` | Java parser, Mason jdtls registration and specialized nvim-jdtls attach; conditional Java debug/test bundles |
| `lang.json` | jsonls + SchemaStore, JSON5 parser and schema/validation/format settings |
| `lang.kotlin` | Kotlin parser/server, ktlint formatting/linting; conditional DAP and none-ls |
| `lang.php` | phpactor by default or selected intelephense, PHP parser, phpcs/php-cs-fixer; conditional DAP/neotest/none-ls |
| `lang.rust` | rustaceanvim owns rust-analyzer, crates.nvim for Cargo, Rust/RON parsers, codelldb install; optional bacon diagnostics/neotest |
| `lang.typescript` | vtsls/tsc provider choice and disables competing TS servers; conditional DAP, icons and integrations |

With the fork's current history rules and no explicit provider globals, default bundles would also select FzfLua, Neo-tree, and Blink. Optional DAP/test fragments do not themselves activate DAP/test core. Tool installation can still happen without using a debugger: .NET lists netcoredbg directly and Rust adds codelldb when Mason exists.

## Personal configuration versus old reference

**V:** 34 common Lua files are byte-identical. Differences among common Lua files are `config/options.lua`, `config/autocmds.lua`, `config/keymaps.lua`, and `plugins/blink.lua`.

- Only isolated: `plugins/codesnap.lua`, `snippets/{all,cs}.lua`, three Chromognome implementation files.
- Only old: `plugins/lazygit.lua`. The distribution still has Snacks' lazygit mappings; absence of that wrapper plugin does not remove the external program workflow.
- Isolated removed the old global/buffer textwidth-zero settings and clipboard-yank mapping, adds all-filetype spell disabling, and selects Blink's Lua fuzzy implementation. Its comment attributes that choice to a CodeSnap/native-library conflict; this audit did not reproduce that conflict.

| Personal configuration | Intent observed / overrides / dependencies |
| --- | --- |
| `config/options.lua` | Four-space indent, scrolloff 18, wrapping, no swap/backup, persistent undo at shared `~/.vim/undodir`, error-filtered diagnostic attempts, localleader `#`, theme reload command |
| `config/keymaps.lua` | Fixed 22-line movement, centered searches, substitution helpers, diagnostics/quickfix shortcuts, command aliases, project runner, Fzf TODO search, manual Copilot toggle, LuaSnip navigation, character move |
| `config/autocmds.lua` | Kitty reload command, live diagnostic quickfix replacement, Rust hints off, spelling off; host-specific behavior mixed with editor policy |
| `plugins/LazyVim.lua` | Chromognome selection on the distro plugin identity; the October 26 follow-up corrected that identity to QuanVim |
| `plugins/blink.lua`, `snip.lua` | LuaSnip preset, snippet scoring/order and buffer toggle, Lua fuzzy engine; lazy-load Lua snippets from consumer directory |
| `plugins/lazydev.lua` | Lua typing library; also declares old nvim-cmp source fragment, despite Blink's bundle disabling that plugin |
| `plugins/lsp.lua`, `java.lua`, `rustaceanvim.lua` | Hints off, delegate Rust ownership, broaden file loading triggers, repository/Maven Java root override, rustaceanvim major version and eager load |
| `plugins/neotree.lua` | Deep scanning, disable empty-directory grouping, custom `g.` regroup/refresh/reveal callback |
| `plugins/fzflua.lua`, `telescope.lua` | Fzf provider present, avoids split/join key collisions; Telescope retained for command/preview use |
| `plugins/snacks.lua` | Enable dashboard/picker/UI helpers, disable scroll/words/explorer; custom keymap picker, highlights and attempted image/layout configuration |
| `plugins/lualine.lua` | Adds macro-recording, total line/character indicators, removes inherited right sections |
| `plugins/trouble.lua`, `quicker.lua` | Custom floating diagnostics view and quickfix editing/navigation; different roles, not inherently duplicate |
| `plugins/splitjoin.lua` | mini.splitjoin actions on `<leader>sk/sj`; deliberate corresponding Fzf-key disabling |
| `plugins/toggleterm.lua`, `user/project_runner.lua` | Reusable terminals per project/kind; runs Cargo/.NET/Python/Node files, project detection and arbitrary commands |
| `user/rust_runner.lua` | Separate Cargo terminal; no caller found in either inspected config, while project runner already supports Rust |
| `plugins/copilotlua.lua`, `copilotchat.lua`, `copilot.lua` | Manual inline Copilot + chat; legacy copilot.vim explicitly disabled even though listed as chat dependency; credentials/build dependency external |
| `plugins/color.lua`, `hex-colors.lua` | Nightfox/base46 alternate colors, nvim-colorizer for hex previews |
| `colors/chromognome.lua`, `user/themes/chromognomev2/` | Personal theme palette/highlights; some groups address old plugin APIs; active selection must be distinguished from palette availability |
| `colors/chromozome.lua` | Separate complete theme, not the selected Chromognome variant; registers its own ColorScheme callback |
| `plugins/imagemagick.lua`, `markdown.lua` | image.nvim + magick.nvim, render-markdown + Treesitter/mini.nvim; terminal/runtime dependencies apply |
| `plugins/codesnap.lua` | CodeSnap beta pin and transparent/minimal snapshot settings; native/rendering dependencies need independent verification |
| `plugins/conflict-marker.lua`, `undotree.lua` | Conflict highlighting + Diffview; undo history UI |
| `plugins/lazy.lua`, `pairs.lua`, `startup.lua`, `dev.lua` | Flash/pairs/startuptime disabled; dev module empty; these are explicit choices/placeholder, not automatically bugs |
| `snippets/cs.lua`, `snippets/all.lua` | C# templates/dynamic class/namespace snippets and general prompt templates; personal content should not become mandatory distribution policy |

## Confirmed configuration issues and qualified overlaps

| Finding | Evidence strength / implication | Next verification or decision |
| --- | --- | --- |
| Fork not selected by consumer | **V at the 2026-10-25 snapshot:** both spec URLs and lock identity were upstream | Resolved in the October 26 follow-up; retain the finding as historical context and keep runtime provenance checks for future source changes |
| Snacks image key is `images` | **V:** personal opts use `images`; installed Snacks declares/loads `image` | That configuration does not enable the documented image module; decide which image workflow is wanted |
| Picker layout sits outside `opts` | **V:** `plugins/snacks.lua` has top-level `layouts`, while Snacks picker config owns `layouts` | That field is not passed to `Snacks.setup(opts)`; intended layout needs a targeted fix/test |
| Snacks setup hook replaced | **V:** personal `config` bypasses upstream notification-restoration wrapper | **I:** early-message routing can differ; test headless and interactive histories before changing |
| Invalid diagnostic intent | **V:** personal options set `text`; native API's handler is `virtual_text`. Fork LSP also reapplies diagnostics later | Move intended policy to the LSP opts hook in a separate fix; confirm resulting virtual text/sign/underline severity |
| Quickfix ownership | **V:** every DiagnosticChanged replaces the global quickfix list | **I:** overwrites grep/build lists during editing; decide live diagnostic list versus dedicated loclist/Trouble |
| `<C-j>` / `<C-k>` ownership | **V:** LuaSnip global mappings, Copilot acceptance, and LSP insert signature mapping overlap | **I:** winning behavior depends on timing, buffer-local maps and context; inspect mappings after attach/insert |
| Completion engine overlap | **V:** stale nvim-cmp config, but Blink extra disables nvim-cmp | Not proof of two active engines. Decide whether alternate-engine support is wanted before deleting old source config |
| Picker overlap | **V:** selected provider defaults, direct Snacks calls and optional Telescope command coexist | Could be intentional specialization. Ask which workflows use each before consolidation |
| Multiple comment strategies | **V:** native comments + ts-comments + selected mini.comment/context-commentstring | Compare mixed-language behavior/keymaps before choosing a single owner |
| Root policies differ | **V:** shared roots, Java override, project-runner git-first rules | Sometimes necessary for language workspaces; document exceptions rather than forcing one algorithm everywhere |
| Neo-tree custom callback | **V:** uses internal sources.manager and concatenates `file` even when nil | Unnamed-buffer invocation has a likely error path; exercise it, then simplify only that callback |
| Runner complexity and edge cases | **V:** owns detection, command strings, cached terminals and focus; malformed package JSON can leave `read_json(pkg).scripts` indexing nil; `.git` directory-only first search misses worktree-file form | Useful feature with fixable local seams. No need for a task framework; test malformed JSON, nested projects, spaced/quoted paths and reruns |
| Runner command selection | **V:** no generic npm project detector; Python project action opens an interpreter, TS/HTML fallback invokes node; only run_current_file has a config caller | **D:** specify intended actions before making it a supported feature |
| Copilot chat spec | **V:** sticky config is inside an anonymous list; commit mapping lacks `<cmd>`/`:` | **I:** intended chat settings/action may not apply; verify against installed version and key behavior |
| Broad mini.nvim dependency | **V:** Markdown config adds entire mini.nvim alongside standalone mini modules | **I:** overlapping runtime modules can complicate provenance; inspect requirements and runtimepath before replacing dependency |
| Theme naming/lifecycle | **V:** Chromognome registers `chromognome_dark`; Chromozome adds a new ungrouped autocmd whenever sourced | **I:** reload/name checks and repeated callbacks deserve targeted tests |

## Compatibility and complexity candidates

**V:** retained JSON migrations through version 7, extra/repository renames, deprecated utility aliases, old LSP keymap adapter, Windows/PowerShell handling, Neovim 0.11/0.12/0.13 branches and parser pins, devicons mocking, legacy completion/none-ls integration, and optional VSCode integration. The last still lists `LazyVim` and imports `LazyVim/LazyVim`, so it is not fully fork-aware even after PR #2.

Do not remove these as a group. Native Linux-only ownership, supported Neovim versions, VSCode support, upstream synchronization and public compatibility guarantees are **D**. For example, `util/cmp.lua` cannot be called legacy-only merely because nvim-cmp is not selected: Blink still uses its snippet/action helpers.

Potentially useful distribution additions, requiring separate approval: Chromognome as an optional native colorscheme; a small project runner with explicit supported commands; snippet integration (separate from personal prompt contents); a personal preset for diagnostics/statusline/editing conventions. Kitty signals, clipboard overrides, AI model choices and host paths should remain local unless deliberately made opt-in.

## Complete optional bundle catalog

The table below lists all 115 existing extras files by category. Entries describe availability, not activation. Nested `typescript` denotes its directory `init.lua`; its child bundles are separate files. Read a bundle's returned specs before assuming every integration is installed. Language files can configure other categories too.

| Category | Files | Available bundles |
| --- | ---: | --- |
| ai | 9 | [ai/avante](../lua/lazyvim/plugins/extras/ai/avante.lua), [ai/claudecode](../lua/lazyvim/plugins/extras/ai/claudecode.lua), [ai/codeium](../lua/lazyvim/plugins/extras/ai/codeium.lua), [ai/copilot-chat](../lua/lazyvim/plugins/extras/ai/copilot-chat.lua), [ai/copilot-native](../lua/lazyvim/plugins/extras/ai/copilot-native.lua), [ai/copilot](../lua/lazyvim/plugins/extras/ai/copilot.lua), [ai/sidekick](../lua/lazyvim/plugins/extras/ai/sidekick.lua), [ai/supermaven](../lua/lazyvim/plugins/extras/ai/supermaven.lua), [ai/tabnine](../lua/lazyvim/plugins/extras/ai/tabnine.lua) |
| coding | 8 | [coding/blink](../lua/lazyvim/plugins/extras/coding/blink.lua), [coding/luasnip](../lua/lazyvim/plugins/extras/coding/luasnip.lua), [coding/mini-comment](../lua/lazyvim/plugins/extras/coding/mini-comment.lua), [coding/mini-snippets](../lua/lazyvim/plugins/extras/coding/mini-snippets.lua), [coding/mini-surround](../lua/lazyvim/plugins/extras/coding/mini-surround.lua), [coding/neogen](../lua/lazyvim/plugins/extras/coding/neogen.lua), [coding/nvim-cmp](../lua/lazyvim/plugins/extras/coding/nvim-cmp.lua), [coding/yanky](../lua/lazyvim/plugins/extras/coding/yanky.lua) |
| dap | 2 | [dap/core](../lua/lazyvim/plugins/extras/dap/core.lua), [dap/nlua](../lua/lazyvim/plugins/extras/dap/nlua.lua) |
| editor | 18 | [editor/aerial](../lua/lazyvim/plugins/extras/editor/aerial.lua), [editor/dial](../lua/lazyvim/plugins/extras/editor/dial.lua), [editor/fzf](../lua/lazyvim/plugins/extras/editor/fzf.lua), [editor/harpoon2](../lua/lazyvim/plugins/extras/editor/harpoon2.lua), [editor/illuminate](../lua/lazyvim/plugins/extras/editor/illuminate.lua), [editor/inc-rename](../lua/lazyvim/plugins/extras/editor/inc-rename.lua), [editor/leap](../lua/lazyvim/plugins/extras/editor/leap.lua), [editor/mini-diff](../lua/lazyvim/plugins/extras/editor/mini-diff.lua), [editor/mini-files](../lua/lazyvim/plugins/extras/editor/mini-files.lua), [editor/mini-move](../lua/lazyvim/plugins/extras/editor/mini-move.lua), [editor/navic](../lua/lazyvim/plugins/extras/editor/navic.lua), [editor/neo-tree](../lua/lazyvim/plugins/extras/editor/neo-tree.lua), [editor/outline](../lua/lazyvim/plugins/extras/editor/outline.lua), [editor/overseer](../lua/lazyvim/plugins/extras/editor/overseer.lua), [editor/refactoring](../lua/lazyvim/plugins/extras/editor/refactoring.lua), [editor/snacks_explorer](../lua/lazyvim/plugins/extras/editor/snacks_explorer.lua), [editor/snacks_picker](../lua/lazyvim/plugins/extras/editor/snacks_picker.lua), [editor/telescope](../lua/lazyvim/plugins/extras/editor/telescope.lua) |
| formatting | 2 | [formatting/black](../lua/lazyvim/plugins/extras/formatting/black.lua), [formatting/prettier](../lua/lazyvim/plugins/extras/formatting/prettier.lua) |
| lang | 53 | [lang/angular](../lua/lazyvim/plugins/extras/lang/angular.lua), [lang/ansible](../lua/lazyvim/plugins/extras/lang/ansible.lua), [lang/astro](../lua/lazyvim/plugins/extras/lang/astro.lua), [lang/clangd](../lua/lazyvim/plugins/extras/lang/clangd.lua), [lang/clojure](../lua/lazyvim/plugins/extras/lang/clojure.lua), [lang/cmake](../lua/lazyvim/plugins/extras/lang/cmake.lua), [lang/dart](../lua/lazyvim/plugins/extras/lang/dart.lua), [lang/docker](../lua/lazyvim/plugins/extras/lang/docker.lua), [lang/dotnet](../lua/lazyvim/plugins/extras/lang/dotnet.lua), [lang/elixir](../lua/lazyvim/plugins/extras/lang/elixir.lua), [lang/elm](../lua/lazyvim/plugins/extras/lang/elm.lua), [lang/ember](../lua/lazyvim/plugins/extras/lang/ember.lua), [lang/erlang](../lua/lazyvim/plugins/extras/lang/erlang.lua), [lang/git](../lua/lazyvim/plugins/extras/lang/git.lua), [lang/gleam](../lua/lazyvim/plugins/extras/lang/gleam.lua), [lang/go](../lua/lazyvim/plugins/extras/lang/go.lua), [lang/haskell](../lua/lazyvim/plugins/extras/lang/haskell.lua), [lang/helm](../lua/lazyvim/plugins/extras/lang/helm.lua), [lang/java](../lua/lazyvim/plugins/extras/lang/java.lua), [lang/json](../lua/lazyvim/plugins/extras/lang/json.lua), [lang/julia](../lua/lazyvim/plugins/extras/lang/julia.lua), [lang/kotlin](../lua/lazyvim/plugins/extras/lang/kotlin.lua), [lang/lean](../lua/lazyvim/plugins/extras/lang/lean.lua), [lang/markdown](../lua/lazyvim/plugins/extras/lang/markdown.lua), [lang/nix](../lua/lazyvim/plugins/extras/lang/nix.lua), [lang/nushell](../lua/lazyvim/plugins/extras/lang/nushell.lua), [lang/ocaml](../lua/lazyvim/plugins/extras/lang/ocaml.lua), [lang/php](../lua/lazyvim/plugins/extras/lang/php.lua), [lang/prisma](../lua/lazyvim/plugins/extras/lang/prisma.lua), [lang/python](../lua/lazyvim/plugins/extras/lang/python.lua), [lang/r](../lua/lazyvim/plugins/extras/lang/r.lua), [lang/rego](../lua/lazyvim/plugins/extras/lang/rego.lua), [lang/ruby](../lua/lazyvim/plugins/extras/lang/ruby.lua), [lang/rust](../lua/lazyvim/plugins/extras/lang/rust.lua), [lang/scala](../lua/lazyvim/plugins/extras/lang/scala.lua), [lang/solidity](../lua/lazyvim/plugins/extras/lang/solidity.lua), [lang/sql](../lua/lazyvim/plugins/extras/lang/sql.lua), [lang/svelte](../lua/lazyvim/plugins/extras/lang/svelte.lua), [lang/tailwind](../lua/lazyvim/plugins/extras/lang/tailwind.lua), [lang/terraform](../lua/lazyvim/plugins/extras/lang/terraform.lua), [lang/tex](../lua/lazyvim/plugins/extras/lang/tex.lua), [lang/thrift](../lua/lazyvim/plugins/extras/lang/thrift.lua), [lang/toml](../lua/lazyvim/plugins/extras/lang/toml.lua), [lang/twig](../lua/lazyvim/plugins/extras/lang/twig.lua), [lang/typescript/biome](../lua/lazyvim/plugins/extras/lang/typescript/biome.lua), [lang/typescript](../lua/lazyvim/plugins/extras/lang/typescript/init.lua), [lang/typescript/oxc](../lua/lazyvim/plugins/extras/lang/typescript/oxc.lua), [lang/typescript/tsc](../lua/lazyvim/plugins/extras/lang/typescript/tsc.lua), [lang/typescript/vtsls](../lua/lazyvim/plugins/extras/lang/typescript/vtsls.lua), [lang/typst](../lua/lazyvim/plugins/extras/lang/typst.lua), [lang/vue](../lua/lazyvim/plugins/extras/lang/vue.lua), [lang/yaml](../lua/lazyvim/plugins/extras/lang/yaml.lua), [lang/zig](../lua/lazyvim/plugins/extras/lang/zig.lua) |
| linting | 1 | [linting/eslint](../lua/lazyvim/plugins/extras/linting/eslint.lua) |
| lsp | 2 | [lsp/neoconf](../lua/lazyvim/plugins/extras/lsp/neoconf.lua), [lsp/none-ls](../lua/lazyvim/plugins/extras/lsp/none-ls.lua) |
| platform | 1 | [vscode](../lua/lazyvim/plugins/extras/vscode.lua) |
| test | 1 | [test/core](../lua/lazyvim/plugins/extras/test/core.lua) |
| ui | 9 | [ui/alpha](../lua/lazyvim/plugins/extras/ui/alpha.lua), [ui/dashboard-nvim](../lua/lazyvim/plugins/extras/ui/dashboard-nvim.lua), [ui/edgy](../lua/lazyvim/plugins/extras/ui/edgy.lua), [ui/indent-blankline](../lua/lazyvim/plugins/extras/ui/indent-blankline.lua), [ui/mini-animate](../lua/lazyvim/plugins/extras/ui/mini-animate.lua), [ui/mini-indentscope](../lua/lazyvim/plugins/extras/ui/mini-indentscope.lua), [ui/mini-starter](../lua/lazyvim/plugins/extras/ui/mini-starter.lua), [ui/smear-cursor](../lua/lazyvim/plugins/extras/ui/smear-cursor.lua), [ui/treesitter-context](../lua/lazyvim/plugins/extras/ui/treesitter-context.lua) |
| util | 9 | [util/chezmoi](../lua/lazyvim/plugins/extras/util/chezmoi.lua), [util/dot](../lua/lazyvim/plugins/extras/util/dot.lua), [util/gh](../lua/lazyvim/plugins/extras/util/gh.lua), [util/gitui](../lua/lazyvim/plugins/extras/util/gitui.lua), [util/mini-hipatterns](../lua/lazyvim/plugins/extras/util/mini-hipatterns.lua), [util/octo](../lua/lazyvim/plugins/extras/util/octo.lua), [util/project](../lua/lazyvim/plugins/extras/util/project.lua), [util/rest](../lua/lazyvim/plugins/extras/util/rest.lua), [util/startuptime](../lua/lazyvim/plugins/extras/util/startuptime.lua) |

## External dependencies and verification limits

Core environment checks include Git, rg, fd/fdfind, fzf, curl and lazygit, but not every workflow needs every tool. Syntax parsers require build tools/CLI; language support needs its runtime/server and real project roots. Rust needs rust-analyzer/toolchain, Java a suitable Java/jdtls environment, .NET its SDK/server/formatters, web tooling Node/npm. AI needs accounts; image/snapshot tools need their native libraries and compatible terminal/rendering environment. Installing a Neovim plugin is not sufficient evidence for those workflows.

No plugins were installed, removed, updated or run in this audit. No source code or personal config was changed. See ROADMAP.md for targeted verification rather than treating import validity as complete functional testing.
