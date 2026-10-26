# Contributing to LazyVim

## Local QuanVim regression tests

Run all existing and startup/configuration tests from the repository:

```sh
./scripts/test
```

To run only the loading/configuration regressions:

```sh
./scripts/test tests/startup/config_spec.lua tests/startup/startup_spec.lua
```

Requires Python 3, Neovim >= 0.11.2, and an already provisioned dependency
directory containing `lazy.nvim`, `mini.nvim` (for `mini.test`), `plenary.nvim`
(for `luassert`), `mini.icons`, `mason.nvim`, `mason-lspconfig.nvim`,
`nvim-treesitter`, and `snacks.nvim`. The default dependency directory is
`~/.local/share/quanvim/lazy`. An existing Mason registry snapshot at
`~/.local/share/quanvim/mason/registries/github/mason-org/mason-registry`
must contain `registry.json`. Missing prerequisites cause an error; the runner
never downloads them. To use a separately provisioned cache, in fish:

```fish
env QUANVIM_TEST_DEPS=/path/to/plugins QUANVIM_TEST_REGISTRY=/path/to/mason-registry ./scripts/test
```

The runner copies dependencies and the registry into a temporary directory and
removes it on exit. It replaces HOME and XDG config/data/state/cache paths before
launching Neovim. It does not load or write personal configuration, `nvim_old`,
or the isolated consumer. Installs, updates, package/rock discovery, project-local
specs, and change detection are disabled; lazy.nvim management tasks also fail
explicitly if attempted. Mason tests use the copied registry without refreshing it.

Fresh headless consumers import real distribution and provider specs, execute
QuanVim and Snacks, and deliberately trigger `VeryLazy` after `VimEnter`. They
check startup notifications, message history, import diagnostics and exit status.
Other plugin activation is disabled: this tests loading and customization
contracts, not real UI entry, language-server attachment, completion, external
tools, parser builds, the personal theme, or the interactive LazyExtras UI.
Results depend on the provisioned dependency versions; no versions are fetched
or updated automatically. The upstream CI configuration is unchanged by this slice.

## General Guidelines

- Avoid using Vim plugins whenever possible.
- If an extra requires a Vim plugin, explain why in the PR description.
- Ensure all configurations are overridable by the user, using Lazy's specs.
- Tag specs as `optional` if they should only be enabled when the user has them installed.
- Implement proper lazy-loading for every plugin added in an extra.
- Understand how Lazy's dependencies work. For Lua dependencies, do not specify
  them in the `dependencies` field. Instead, add them as a separate spec with `lazy=true`.

## Contributing an Extra Plugin

- The plugin should be well-known and require significant configuration.
- Simple specs containing just the plugin with some options will not be accepted.

## Contributing an Extra Language

- You should be familiar with the language you are adding.
- You should have experience with the language's ecosystem, including formatters,
  linters, and LSP servers.
- The extra should include the setup most widely used by the community.
- Include Tree-sitter parsers that are not yet the default.
- Include the most widely used LSP server setup.
- Avoid the need for LSP wrapper packages whenever possible.
- Only add a formatter if it is typically used by the community instead of the LSP formatter.
- Only add extra linters if the community typically uses them instead of just the LSP linters.
- Every language extra requires a `recommended` section as part of the extra.
  Check lspconfig server configurations for the proper filetypes and root directories.
  Refer to other extras for creating the `recommended` section.

### Language-Specific Keymaps

- Use `<localleader>` for language-specific keymaps (follows Vim/Neovim convention for filetype-specific mappings).
- For LSP servers, define keymaps in the server's `keys` field, not in `on_attach`:
  ```lua
  servers = {
    rust_analyzer = {
      keys = {
        { "<localleader>e", function() vim.cmd.RustLsp("expandMacro") end, desc = "Expand Macro" },
      }
    }
  }
  ```
- LazyVim's LSP system will automatically resolve and apply these keymaps (see `lua/lazyvim/plugins/lsp/keymaps.lua`).
- Don't override standard LSP keymaps (like `K` for hover, `gd` for definition) unless absolutely necessary.
- Use standard `<leader>c*` keymaps where they make sense (e.g., `<leader>co` for organize imports).
- Refer to the R and Haskell extras for examples of proper `<localleader>` usage.
