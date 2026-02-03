# Emacs Bootstrap

## How to Press Keys (Meow Keypad)

In **normal mode**, press `SPC` to enter keypad mode, then:

| To get | Press | Why |
|--------|-------|-----|
| `C-x C-f` | `SPC x f` | `x` starts C-x, next key gets C- too |
| `C-x f` | `SPC x SPC f` | SPC before `f` = literal (no C-) |
| `C-c f` | `SPC c SPC f` | `c` starts C-c, SPC makes `f` literal |
| `C-h f` | `SPC h SPC f` | `h` starts C-h, SPC makes `f` literal |
| `M-x` | `SPC m x` | `m` = Meta prefix |
| `C-M-f` | `SPC g f` | `g` = Ctrl+Meta prefix |

**Keypad start keys:** `x`=C-x, `c`=C-c, `h`=C-h
**Modifiers:** `m`=Meta, `g`=Ctrl+Meta, `SPC`=literal (no modifier)

**Or just use Alt directly:** `M-x` = Alt+x (works in any mode)

**Get help:** `SPC ?` → Meow cheatsheet

## Quick Reference

| Key | Action |
|-----|--------|
| `ESC` | Return to normal state |
| `i` | Insert before |
| `g` | Cancel selection (or `C-g` quit) |
| `G` | Grab (multi-line editing / BEACON mode — records macro, replays at each cursor) |
| `SPC` | Leader menu (which-key shows options) |
| `C-x C-s` | Save file |
| `F10` | Menu bar |
| `x s` | Select line + kill |
| `s` | Kill to end of line (no selection) |
| `x c` | Select line + change (delete + insert) |
| `M-x` | Command palette (orderless: `bu sw` → switch-to-buffer, marginalia shows keys) |
| `C-x <left>` | Previous buffer |
| `C-x <right>` | Next buffer |
| `M-x revert-buffer` | Reload file from disk |

## Leader Commands (SPC)

| Key | Action |
|-----|--------|
| `SPC s` | Search in buffer (consult-line) |
| `SPC f` | Find file with fd (prompts for dir) |
| `SPC r` | Recent files |
| `SPC b` | Switch buffer |
| `SPC o` / `C-c o` | Other window |
| `SPC .` / `M-.` | Embark act (context menu) |
| `SPC ,` / `M-,` | Embark dwim (default action) |
| `SPC l 1` | Pi layout: default |
| `SPC l 2` | Pi layout: with right window |
| `SPC w p` | Paste from Windows |
| `SPC w c` | Copy to Windows |
| `SPC w e` | Open Explorer here |

## Help & Discovery

| Command | Action |
|---------|--------|
| `SPC ?` | Meow cheatsheet |
| `M-x describe-mode` | What modes are active? |
| `M-x describe-bindings` | List all keybindings |

## Navigation

| Key | Action |
|-----|--------|
| `M-<` | Beginning of buffer |
| `M->` | End of buffer |
| `h/j/k/l` | Left/down/up/right (normal mode) |
| `M-g g` | Go to line (consult) |
| `M-v` | Page up (C-v page down intercepted by terminal) |

## Editing

| Normal | Insert | Action |
|--------|--------|--------|
| `x` | `C-SPC` | Select line / set mark |
| `w` | | Mark word |
| `s` | `C-w` | Kill (cut) |
| `y` | `M-w` | Save (copy) |
| `p` | `C-y` | Yank (paste) |
| | `M-y` | Cycle kill ring (consult) |
| `c` | | Change (delete + insert) |
| `d` | | Delete char |
| | `C-k` | Kill to end of line |
| `u` | `C-x u` | Undo |

## Files & Buffers

| Key | Action |
|-----|--------|
| `C-x C-f` | Find/open file (navigate directories) |
| `C-c f` | Find file with fd (fuzzy search all files) |
| `C-x C-s` | Save file |
| `C-x b` | Switch buffer (consult) |
| `C-x k` | Kill buffer |

## Projects

**What's a project?** Any directory with `.git` (or `.hg`, `.svn`, `.project`).

**Current project** = determined by the focused buffer's file location (looks up for `.git`).

**Known projects** stored in `~/.emacs.d/projects` (auto-added when you open files in git repos).

| Key | Action |
|-----|--------|
| `C-x p p` | Switch project (shows list, then action menu) |
| `C-x p f` | Find file in current project |
| `C-x p g` | Ripgrep in project |
| `C-x p b` | Switch buffer (project only) |
| `C-x p k` | Kill all project buffers |

## Windows

| Key | Action |
|-----|--------|
| `C-x 0` | Close current window |
| `C-x 1` | Close all other windows |
| `C-x 2` | Split horizontally |
| `C-x 3` | Split vertically |
| `C-x o` | Switch to other window |
| `C-x C-b` | List buffers (`d` to mark, `x` to delete) |

## Workflow

```
M-x pi      → Start coding agent
SPC         → Leader menu (wait for which-key popup)
M-x         → Type partial names with spaces
```

## Quick Recovery

| Key | Action |
|-----|--------|
| `C-g` | Cancel/quit current command |
| `u` | Undo (normal mode) |
| `C-x u` | Undo (insert mode) |
| `ESC ESC ESC` | Emergency escape |

# pi-coding-agent

## Input Buffer

| Key | Action |
|-----|--------|
| `C-c C-c` | Send (queues follow-up if busy) |
| `C-c C-s` | Queue steering message (busy only) |
| `C-c C-k` | Abort streaming |
| `C-c C-p` | Open menu |
| `C-c C-r` | Resume session |
| `M-p` / `M-n` | History navigation |
| `C-up` / `C-down` | History navigation (alternate) |
| `C-r` | Search history |
| `TAB` | Complete paths, @files, /commands |
| `@` | File reference (search project files) |

## Chat Buffer

**Note:** Meow NORMAL mode captures `n`, `p`, `q`, `TAB`, `RET`. Use `i` to enter INSERT mode first, or use M-x:

| Key (INSERT) | M-x command | Action |
|--------------|-------------|--------|
| `n` / `p` | `pi-coding-agent-next/previous-message` | Navigate messages |
| `TAB` | `pi-coding-agent-toggle-tool-section` | Toggle fold |
| `S-TAB` | | Cycle all folds |
| `RET` | `pi-coding-agent-visit-file` | Visit file (tool blocks) |
| `q` | `pi-coding-agent-quit` | Quit session |
| `M-.` / `SPC .` | | Actions menu (works in any mode) |

## Menu Commands (C-c C-p)

| Key | Action |
|-----|--------|
| `m` | Select model |
| `t` | Cycle thinking level |
| `n` | New session |
| `r` | Resume session |
| `f` | Fork session |
| `c` | Compact context |
| `e` | Export HTML |
| `s` | Session stats |
| `y` | Copy last message |

## Tips

- **Steering vs Follow-up**: `C-c C-s` interrupts after current tool; `C-c C-c` waits until done
- **File reference**: Type `@` then search; respects `.gitignore`
- **Path completion**: `./`, `../`, `~/` then TAB
- **Slash commands**: `/command` then TAB for custom commands

# LLM Workflow Patterns

## Copy from Chat → Paste to Input

```
Chat buffer (NORMAL mode):
  x            Select line
  y            Copy
  SPC o        Switch to input window
  i            Enter INSERT mode
  C-y          Paste
```

## Copy Multiple Items

```
Chat: x y        Copy first thing
      [move]     Navigate to next
      x y        Copy second thing
Input: M-y       Browse kill ring (clipboard history)
       [select]  Choose what to paste
```

## Find File LLM Mentioned

```
ESC SPC f        Find file in project
[type name]      Orderless fuzzy match
```

## Search Chat History

```
ESC SPC s        Search current buffer
[type term]      Live results
```

## Mode Reminder

- **NORMAL mode** (ESC): Use Meow keys (`x`, `y`, `p`, `w`, etc.)
- **INSERT mode** (i): Use Emacs keys (`C-y`, `M-w`, `C-s`)
- **SPC** commands only work in NORMAL mode
- **M-.** and **M-,** work in ANY mode
