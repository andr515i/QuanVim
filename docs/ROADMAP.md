# QuanVim incremental roadmap

Based on the 2026-10-25 audit of source `394859cc`. See [current architecture](ARCHITECTURE.md) and [inventory/evidence](FEATURE_INVENTORY.md). This is a proposal, not authorization to implement, remove features, install tools, push or merge.

## Direction

Keep lazy.nvim and the useful LazyVim integration code. Make the installed source, provider choices and customization points explicit before changing module boundaries. The first measure of success is whether the owner can find and safely change behavior, not how many lines disappear.

**Verified:** existing config/spec/helper separation already supports incremental work. **Inference:** a rewrite would spend effort rediscovering working behavior and break customization contracts before delivering comparable ownership benefits. There is no evidence here that a new plugin manager, settings DSL, service container or generic task framework is needed.

## Decisions that need the owner

These can be made one slice at a time; no need to decide the whole architecture first.

1. **Deployment:** should the isolated consumer track the merged remote fork or a local source checkout? Today's bootstrap points upstream despite the merged fork fix. Which repository is authoritative for the consumer?
2. **Support contract:** personal Linux-only distribution, or retain Windows/PowerShell/VSCode and downstream configuration compatibility? Which Neovim versions must work? Current source requires >= 0.11.2, with newer-version branches.
3. **Providers:** default picker (FzfLua/Snacks/Telescope), explorer (Neo-tree/Snacks/mini.files), completion engine and snippet engine. Alternatives can stay available; default choice does not require deletion.
4. **Editing policy:** diagnostic severity/display and quickfix ownership; formatting on save; snippet versus Copilot acceptance keys; spell/wrap/textwidth behavior.
5. **Feature ownership:** which languages and project actions are routine, and which theme/snippets/UI customizations belong in QuanVim versus a private preset? Installed/configured does not answer actual use.
6. **Upstream relationship:** periodically merge LazyVim, selectively port changes, or own a stable fork independently? That determines how aggressively compatibility/private-lazy seams should change.

## Prioritized implementation candidates

Complexity and risk are relative to this codebase, not time estimates. Each row is a separately reviewable change; do not bundle it with feature pruning.

| Order | Small complete outcome | Practical benefit | Complexity | Regression risk |
| --- | --- | --- | --- | --- |
| 1 | Align isolated bootstrap/theme spec with the chosen QuanVim source, preserving its lockfile edits | Ensures tests and daily experiments exercise the code being developed | Low | Low–medium: source switch changes effective specs |
| 2 | Establish a safe isolated startup/override regression check | Makes loader and future provider changes reviewable; covers PR #2 failure mode | Medium | Low for tests; fixtures must avoid installs/state writes |
| 3 | Own fork installation/help/CI references and support contract | Reduces misleading instructions and uncertainty about what CI validates | Low–medium | Low for docs; medium for workflow changes |
| 4 | Explicitly select current picker/explorer/completion policy | Removes install-history surprises without removing any backend | Low | Medium: mappings and UI routing can change |
| 5 | Correct local Snacks/diagnostics configuration in separate focused fixes | Makes requested image/layout/diagnostic behavior apply at the correct hook | Low–medium | Medium: visible behavior and notification timing |
| 6 | Resolve snippet/Copilot/LSP key ownership and diagnostic-list policy | Avoids late-loading shortcuts changing meaning and losing search results | Low–medium | Medium: muscle memory and diagnostic navigation |
| 7 | Package Chromognome as an optional distribution theme | Provides an understandable end-to-end ownership feature | Low–medium | Low–medium: highlight coverage/reloads/integrations |
| 8 | Make the project runner a supported optional feature | Brings a useful personal workflow under a small testable contract | Medium | Medium: shell commands, roots, focus and process lifetime |
| 9 | Curate default feature bundles while retaining alternatives | Reduces default responsibilities/active dependencies based on actual use | Medium | Medium–high: needs workflow comparison before changing defaults |
| 10 | Narrow private lazy/global helper coupling on touched paths | Improves navigation and isolates update-sensitive code | Medium–high | High if import/merge behavior changes |
| 11 | Retire compatibility paths with evidence and an agreed support policy | Reduces future maintenance, without breaking unknown consumers accidentally | Variable | Medium–high: public imports/old installs/platform behavior |

## Acceptance checks for the first slices

### 1. Establish source provenance

Change only the consumer's distribution selection and matching overrides after approval. Validate resolved plugin name, URL, directory, commit and runtimepath. Confirm upstream and fork are not both configured unintentionally. Show the resulting spec/lock diff; preserve unrelated plugin pins and user edits. Do not modify the active config or old reference.

Acceptance: both no-file and file startup use the intended fork; all selected extras resolve; options and personal theme still load. The startup fix is already merged into source; do not reimplement PR #2 or use broad error suppression.

### 2. Protect loading and customization contracts

Use an isolated test consumer and temporary state; do not point test installation at the active editor. Disable automatic install/check/update/save hooks in the fixture or pre-provision known dependencies, while explicitly reporting anything omitted. Protect these behaviors:

- Distribution runtimepath exists before extras import; missing-module failures name the import/path rather than failing at `loadfile(nil)`.
- Startup with and without a file, plus real UI entry or deliberately triggered deferred hooks. Ordinary headless `qa` can miss VeryLazy work and deferred errors.
- Personal options follow defaults; provider selection accounts for old/new install histories and explicit overrides.
- An `opts` mutation preserves inherited fields; replacing `config` is intentional; an optional DAP/test fragment does not activate the subsystem.
- Theme reload, `LazyExtras`, and keymap attachment after LSP/InsertEnter remain usable. Capture error histories as well as exit code.

Retain existing extras/utility checks. The earlier 447 passes demonstrate spec/helper validity at that snapshot, not all startup contracts, native builds or language-server workflows. No new test framework dependency is justified just for these cases.

### 3–4. Own policy and navigation

First correct authoritative fork installation instructions and review actual CI checkout/test arguments; current workflow points to upstream metadata. Do not merely rename job labels and assume coverage changed. Keep upstream attribution/licenses.

Record chosen provider globals at the existing early configuration point. Prefer an explicit personal preset initially over changing defaults for every consumer. Verify root/cwd file search, grep, buffers, symbols, explorer reveal, command completion and snippet expansion. Retain specialized Telescope/Snacks actions if they serve a distinct purpose. Do not confuse a direct Snacks picker with the registered default backend.

### 5–6. Fix policy at its owning layer

Correct one observed problem per change:

- Snacks: correct image module name and place picker layouts inside the options passed to that module; preserve notification ownership when applying custom highlights. Confirm options against the installed plugin version before implementation.
- Diagnostics: use native `virtual_text` and the LSP spec's `opts.diagnostics` rather than a competing early global call. Decide error-only versus all severities. Confirm effective config after LSP loads.
- Quickfix: choose whether diagnostics may own the global list. If not, use a dedicated location list/view and preserve grep/build results. Avoid adding another list abstraction.
- Keymaps: choose distinct or contextual snippet, Copilot and signature actions. Inspect global and buffer-local maps before/after insert entry and LSP attachment. Preserve current muscle memory where practical.
- Personal Neo-tree and runner edge cases: exercise the unnamed-buffer nil path and malformed package JSON before fixing; keep these local fixes out of unrelated architecture work.

### 7–8. Optional personal features, not wholesale migration

Theme: preserve palette and existing integrations, establish one color name and repeatable reload behavior, then offer it through normal colorscheme selection. Keep host/editor overrides outside the palette. Check normal buffers, diagnostics, completion, picker, explorer, floats and terminal colors. Decide on Chromozome independently.

Runner: retain a plain Lua module using an existing terminal backend. Specify supported actions (file versus project), command/root precedence, save behavior and rerun/cancel behavior. Separate only the seams needed to test detection and command selection. Cover worktrees, nested projects, invalid JSON, filenames requiring shell escaping and missing tools. A module split is justified only if this makes those behaviors easier to understand. Do not adopt Overseer or invent a task engine without a workflow that requires it.

Snippet engine integration may become optional distribution code; personal prompt text and project templates remain personal unless explicitly selected. Retire the separate unused Rust runner only after confirming no external caller; local search alone is insufficient.

## Proposed target organization

Keep the existing import namespace initially. A rebrand of Lua modules would touch user configs, JSON names, globals, help and plugin specs without inherently improving ownership.

```text
consumer configuration
  init.lua / lua/config/lazy.lua   source selection + ordinary lazy.nvim setup
  lua/config/                     personal policy and host-specific behavior
  lua/plugins/                    personal overrides or additional plugins

distribution (retain current public imports initially)
  lua/lazyvim/config/              startup phases + default editor policy
  lua/lazyvim/plugins/             default feature specs by recognizable domain
  lua/lazyvim/plugins/extras/      opt-in languages/workflows/provider alternatives
  lua/lazyvim/util/                concrete root/LSP/format/parser integrations
  colors/                         optional owned theme, if approved
  tests/                          loading/override checks + selected real seams
  docs/                           these three authoritative audit/planning files
```

This is an evolutionary boundary map. The audit does not propose moving every file now. If directory-based discovery becomes a practical obstacle, introduce an explicit list of core imports through a compatibility-preserving entry point, still returning standard lazy.nvim specs. Validate phase order before replacing `xtras.lua` or removing its import wrapper. A new generic feature registry would duplicate lazy.nvim unless a concrete missing requirement is demonstrated.

Keep the formatting registry while it arbitrates Conform/LSP/optional integrations; only simplify it after deciding that supported combinations no longer need that arbitration. Keep a shared root service for navigation and terminals while permitting documented language/project exceptions. Keep Snacks where it currently supplies real infrastructure; replacing one UI module does not justify removing the dependency wholesale.

## Pruning and performance gates

Before changing a default or retiring a bundle, identify the owner workflow, callers, keys, external tools, optional cross-integrations and supported configurations. Present a reversible proposal with a concrete acceptance check. Unused in one startup is not unused generally. A comment, compatibility workaround or unfamiliar language is not sufficient evidence for removal.

Measure warm/cold file startup, no-file dashboard, first insert and first language attachment before optimizing. Track plugin initialization/first-use cost separately from installed count and optional source lines. Preserve lazy loading where it has a clear payoff; do not scatter more event indirection to save unmeasured milliseconds. Core success metrics are reproducible startup, predictable overrides and the ability to explain one feature from its entry point.

## Audit completion and remaining uncertainty

The three documents are the only repository output. Source and personal configurations remain unchanged; no feature was migrated. Verification is file inspection, source cross-references, catalog counts, Lua syntax parsing without executing modules, document link checks and before/after file hashes. No fresh configured startup or full test-suite run is claimed.

Still requiring real workflow checks: actual current source loaded by the isolated editor, post-attach key precedence, AI chat settings/authentication, image/snapshot rendering, runner edge cases, native builds, language-server attachment and formatting in real projects, and remote reusable CI behavior. Resolve these as scoped follow-ups rather than turning this audit into an unapproved migration.
