---
id: TASK-007
title: Investigate orphaned embedded Neovim resource leaks
status: In Progress
assignee: []
created_date: '2026-08-16 11:02'
updated_date: '2026-08-17 08:58'
labels:
  - bug
  - performance
  - neovim
  - fff.nvim
dependencies: []
priority: high
type: bug
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why

macOS became slow under memory pressure after orphaned embedded Neovim processes continued running after their parent exited. Track the cause and a durable recovery/prevention path.

## Cold-start context

- Host: macOS 26.5.2, 8 GB RAM.
- PID 4018: `nvim --embed AGENTS.md`, PPID 1, no TTY, revoked stdio, loaded `fff.nvim`, sustained roughly 80–90% CPU, and reached an observed physical footprint above 8 GB with a peak of 11.3 GB. Its FFF log recorded repeated full Git rescans.
- PID 21335: `nvim --embed /Users/tifan/.config/nvim/init.lua`, PPID 1, no TTY, no `fff.nvim`, sustained roughly 80–90% CPU, and later exceeded 3 GB RSS. Its Lua language server child also consumed significant memory.
- Recovery required SIGKILL because SIGTERM did not stop the processes.
- The installed `fff.nvim` was initially `0.9.7-nightly.a0008b1`; it was later updated through `vim.pack`.

## Scope

Determine why embedded Neovim clients become orphaned, and distinguish the generic embedded-Neovim lifecycle failure from FFF-specific watcher and LMDB resource behavior.

## Related references

- https://github.com/dmtrKovalenko/fff/issues/690
- https://github.com/dmtrKovalenko/fff/issues/664
- https://github.com/dmtrKovalenko/fff/issues/783
- https://github.com/dmtrKovalenko/fff/issues/633
- `dot_config/nvim/init.lua`

## Out of scope / follow-ups

Do not terminate attached interactive Neovim, Herdr, Pi, or Claude sessions as part of recovery.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Identify the launcher or integration that starts each `nvim --embed` process and explain why the child survives after the parent exits.
- [ ] #2 Provide a durable prevention or cleanup change for orphaned embedded Neovim processes.
- [ ] #3 Investigate FFF watcher rescans and LMDB reader-slot behavior against the linked upstream issues.
- [ ] #4 Document a read-only detection and safe recovery procedure that distinguishes orphaned processes from attached editor sessions.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Build a bounded PTY harness that launches isolated Neovim 0.12.4 TUI/server pairs and detects a surviving high-CPU server after client SIGHUP.
2. Run the harness against --clean, the user ModeChanged callback, WhichKey, and both callbacks without changing managed configuration.
3. If a case reproduces, bisect the implicated callback. Otherwise, reproduce the Nushell wrapper and Herdr pane-exit timing.
4. Record commands, measurements, and remaining uncertainty in TASK-007.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
New recurrence: Herdr current workspace wB1 showed btm and Pi panes, with no foreground nvim. System process list found orphan PID 13291: `nvim --embed`, PPID 1, TTY `??`, cwd `/Users/tifan/.local/share/chezmoi`, 70–82% CPU over 30 seconds. Its physical footprint peaked at 2.9 GB, although resident memory fluctuated below that during sampling. It had no fff.nvim library, LMDB files, or FFF log open, so this recurrence is a generic embedded-Neovim lifecycle issue rather than direct evidence of FFF. System swap was 2.5 GB used.

Delegated read-only investigation to new Herdr tab `task-007-rootcause` with Pi agent `orphan-nvim` using `openai/gpt-5.6-sol:medium`. The session started, but both the initial prompt and follow-up failed because the provider reported: account is not active / check billing. Handoff document: `/tmp/task-007-orphan-nvim-handoff.md`.

Read-only follow-up on orphan PID 13291:
- Process remained alive with PPID 1, no TTY, revoked stdio, 88–92% CPU, about 1.9 GiB RSS, and a 7.8 GiB physical footprint with a 7.9 GiB peak. Its process-specific Unix socket still existed under the Neovim temporary directory.
- A bounded three-second read-only RPC query for UIs, channels, and ModeChanged autocmd IDs/groups timed out without a response. This supports that the main event loop remains blocked.
- A second two-second sample placed all 1,458 samples in normal_check -> normal_prepare -> may_trigger_modechanged -> apply_autocmds_group -> LuaJIT; _platform_memmove appeared in 1,375 recursive samples. No Lua filename or alternate callback path appeared.
- The applied ~/.config/nvim/init.lua and chezmoi source had identical checksums. Candidate user-config callback sets vim.opt_local.list from vim.fn.mode().
- Installed which-key.nvim was clean at commit 3aab2147e74890957785941f0c1ad87d0a44c15a (stable-8-g3aab214). Its wk ModeChanged callback remains the other candidate. WhichKey debug logging defaults to false, and no wk.log was open.
- nvim.log contained normal TUI mode warnings for client PID 13290 but no Lua, autocmd, or callback error.
- Remaining uncertainty: read-only live inspection cannot distinguish the user-config callback from WhichKey. A controlled isolated clean-config comparison, disabling one callback at a time, is required in a future session with explicit approval.

Controlled isolated experiments (2026-08-16):
- Built `/tmp/task-007-nvim-repro.py`, a bounded PTY/TUI-server harness. It starts Neovim 0.12.4 with four temporary configurations: instrumentation only (`--clean` baseline), the user `ModeChanged` callback, WhichKey at the installed commit, and both callbacks. It drives normal/insert/visual/operator-pending transitions, closes the PTY, verifies the exact child PID before cleanup, and never targets pre-existing processes.
- Ten PTY runs per configuration did not reproduce the orphan loop. Every TUI exited after terminal loss and every embedded server exited. Callback instrumentation confirmed that the stressed mode path ran.
- Built `/tmp/task-007-herdr-repro.py` to add the exact Nushell `nvim` wrapper and disposable Herdr tab-close/SIGHUP path. Five runs per configuration used 1,200 queued keys and close delays from 0 to 250 ms. Callback counts reached 1,200. All 20 servers exited within one second; none became orphaned or retained CPU/RSS.
- Built `/tmp/task-007-herdr-full-config.py` for five disposable tabs using the applied full config and the actual `nvim <file>` wrapper command. With the same queued-key stress and close timings, all five servers exited within one second. Peak observed pre-close CPU was 23.3% and RSS remained about 17 MiB.
- Preserved harnesses and JSON-producing scripts under `/tmp`. All test tabs and processes were removed. PID 13291 and unrelated sessions were not signaled.
- Result: neither candidate callback alone, both together, nor the full current config reproduced in 50 isolated client-loss runs. The live sample still proves a Lua `ModeChanged` callback loop, but these results do not identify which callback or the missing state needed to enter it. The failure is intermittent or depends on a longer-lived editor state not represented by startup/key/SIGHUP timing.

Correction: the controlled total was 65 runs (40 PTY, 20 Herdr minimal-config, and 5 Herdr full-config), not 50.

Recurrence observed 2026-08-17: orphan PID 73331 was `/opt/homebrew/bin/nvim --embed .`, PPID 1, no TTY, revoked stdio, cwd `/Users/tifan/.local/share/chezmoi`, about 80% CPU, 7.3 GiB physical footprint with 8.0 GiB peak. It had lua-language-server PID 73694 and stylua PID 73702 children, FFF native library and LMDB files open, and an FFF log showing picker input followed by recurring background full Git rescans. A three-second sample placed the main thread in `normal_execute -> nv_colon -> map_execute_lua -> LuaJIT`; FFF worker threads were idle. A read-only RPC query timed out. The active foreground Neovim child reported WhichKey `options.preset = "helix"`, matching `dot_config/nvim/init.lua`; no evidence that WhichKey was using `modern` in the live current session. Safe recovery: SIGTERM did not stop 73331 after two seconds; SIGKILL was required for 73331 and its orphaned LSP/stylua children. The recurrence confirms the split Neovim TUI/`--embed` lifecycle under Neovim 0.12.4, but does not yet prove WhichKey causes the loop.

A bounded isolated test with Neovim 0.12.4, WhichKey at `preset = "helix"`, a `<leader>f` group, and an abrupt parent kill did not orphan the embedded child. This is evidence against a deterministic WhichKey-only failure; the missing trigger/state remains intermittent.

Neovim 0.12.4 runtime `tui.txt` confirms that ordinary `nvim` starts a builtin TUI client, which starts a `nvim --embed` server child. Thus `--embed` is normal core architecture, not a WhichKey or Herdr-specific launcher. A clean PTY run showed the same parent/child pair; the recurrence is the child failing to exit after its TUI client disappears while the child event loop is blocked.

Follow-up recurrence during investigation: PID 92111 later became PPID 1 with revoked stdio and no TTY after its TUI parent 92110 disappeared. It reached about 80% CPU, 1.3 GiB physical footprint with 2.8 GiB peak, and a two-second sample reproduced the same `normal_execute -> nv_colon -> map_execute_lua -> LuaJIT` loop without FFF evidence. SIGTERM again failed; SIGKILL removed it. No attached Neovim process was targeted.

Upstream check: Neovim issue #39501 already tracks an orphaned `nvim --embed` server on macOS with PPID 1, revoked stdio, zero UIs, a stale RPC channel, and unbounded memory growth. Issue #38807 tracks automatic shutdown/ownership for dangling non-stdio clients; #38014 covers a related blocked PTY drain. Do not open a duplicate issue. Our new evidence is a Neovim 0.12.4 recurrence with the main thread stuck in Lua `map_execute_lua`; it should be added as a comment to #39501 only after a discriminating callback trace is captured.

Upstream issue: https://github.com/neovim/neovim/issues/39501

Trace capture prepared: `/tmp/task-007-capture-lua-trace.py PID [OUTPUT]` attaches LLDB to a known orphan, injects `debug.getinfo()` plus `debug.traceback()` through the exported Neovim/LuaJIT symbols, writes the Lua frames to a file, then detaches without killing the target. Validated on a disposable headless Neovim process stuck in `:lua while true do end`; the injected trace included the original `:lua` frame. Use only after PPID=1, no TTY, and revoked stdio have been confirmed.

Maintainer feedback on #39501 (comment https://github.com/neovim/neovim/issues/39501#issuecomment-5312947942): PPID=1 and revoked stdio only prove that the TUI client disappeared; the embedded process may still be finishing shutdown. The maintainer asked whether plugins are keeping it busy. This narrows the next step: capture the Lua traceback and identify the callback before claiming a core channel-teardown bug.

Root cause found on 2026-08-17. A safe orphan (PID 70467: PPID 1, nvim --embed, no TTY, fds 0/1/2 revoked, 80%+ CPU) was captured before termination. The injected Lua traceback was: multicursor-nvim/feedkeys-manager.lua:14 (__concat in its vim.api.nvim_feedkeys wrapper) -> which-key/state.lua:239 (M.execute feeds keys with mode "mit") -> state.lua:214/270/346 -> which-key/triggers.lua:44. Injected state showed WhichKey active with filter.keys = "<Space>" and multicursor FeedkeysManager._fedKeys length 2,683,096; its prefix repeated " r" (the termcode expansion of <Space>r).

The user config maps <leader>r to source ~/.config/nvim/init.lua (init.lua:405), and calls multicursor.setup() (init.lua:385) every time the file is sourced. multicursor core.setup() calls feedkeysManager:setup() (core.lua:57); setup replaces vim.api.nvim_feedkeys and stores the current wrapper as self.nvim_feedkeys. On a second setup, the old wrapper calls the mutable self.nvim_feedkeys field, which now points back to a wrapper, so a later WhichKey replay recursively concatenates the fed macro and grows _fedKeys without bound. This explains the high CPU/memory and why the channel never closes while Lua is executing.

Built and ran a deterministic disposable minimal repro in /tmp/task-007-wk-mc-repro.lua: WhichKey + multicursor in the current config order, with <leader>r sourcing the same file. In a disposable Herdr tab, send Space, wait for the popup, then r. The embedded child reached about 96% CPU; killing only its TUI parent and then closing the test tab left PPID 1/no TTY, and the traceback matched the real orphan. WhichKey alone was also tested: its state.lua:262 getchar path yielded into loop_poll_events and exited cleanly on client loss, so WhichKey by itself is not sufficient; the failure is the WhichKey feedkeys replay combined with repeated multicursor setup.

No managed config was changed. Minimal prevention is to remove the reload mapping (restart Nvim after config edits); an alternative is an explicit one-time guard around multicursor.setup(). The removal is safer because sourcing this full init is not generally idempotent.

Applied local prevention on 2026-08-17 in dot_config/nvim/init.lua and ~/.config/nvim/init.lua. The multicursor setup, its <C-n> mapping, and its <Esc> keymap layer now run only when vim.g.multicursor_nvim_configured is unset. This prevents repeated feedkeys-manager wrapping when the reload mapping sources init.lua. A fixed disposable WhichKey + multicursor repro completed with 0% CPU and the embedded server exited normally after tab close.

Validation passed: stylua --check dot_config/nvim; lua-language-server --check dot_config/nvim --checklevel Warning; luac syntax checks; nvim headless smoke test; chezmoi apply --dry-run --force. The target file was applied selectively with chezmoi apply --force ~/.config/nvim/init.lua and source/target checksums match. Existing Nvim sessions started before this change should be restarted before using <leader>r, because they do not yet have the guard marker.

Follow-up fix on 2026-08-17: WhichKey also reset its layout on reload. Its setup() assigns defaults plus opts immediately, but applies the selected preset window/layout only inside the deferred load function. After the first startup M.loaded is true, so a later setup() call during :source returns before applying the helix preset; the popup falls back to default classic geometry. Wrapped which-key setup() and add() in a one-time vim.g.which_key_nvim_configured guard. An applied-config Herdr test showed the helix popup before reload and after reload. Existing Nvim sessions should be restarted once so both guard markers are initialized.

Follow-up on 2026-08-17: reloading init.lua while mini.starter was current also reapplied general window-local options. mini.starter deliberately sets nonumber, norelativenumber, nocursorline, nowrap, empty colorcolumn, and signcolumn=no in its starter buffer. The top-level config was resetting those options on the current window during :source, so line numbers appeared. Guarded the editor window options for filetype=ministarter; applied target and verified a disposable nvim starter showed no line numbers before and after Space-r reload. Checks and source/target synchronization passed.

Follow-up refinement: the first starter guard only avoided re-enabling options, which did not repair a starter buffer that already had numbers from an earlier reload. The guard now explicitly restores the mini.starter local values in the else branch. A disposable test forced number/relativenumber on the starter buffer, reloaded through Space-r, and confirmed the numbers disappeared.

Created sanitized public reproduction gist for a possible comment on Neovim #39501: https://gist.github.com/tifandotme/2f0a256f6208bba21c1164604c01bf20. It contains only the disposable repro config, concise reproduction notes, and the relevant sanitized traceback/state.
<!-- SECTION:NOTES:END -->
