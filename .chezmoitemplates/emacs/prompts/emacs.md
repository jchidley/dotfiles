# Emacs Quick Reference

## Windows

| Key | Action |
|-----|--------|
| `C-x 0` | Close current window |
| `C-x 1` | Close all other windows (keep only current) |
| `C-x 2` | Split horizontally |
| `C-x 3` | Split vertically |
| `C-x o` | Switch to other window |

## Buffers

| Key | Action |
|-----|--------|
| `C-x k` | Kill buffer (prompt for which) |
| `C-x k RET` | Kill current buffer |
| `C-x C-b` | List buffers (`d` to mark, `x` to delete) |

## Help

| Key | Action |
|-----|--------|
| `C-h b` | List all keybindings |
| `C-h m` | Describe current mode |
| `C-h k <key>` | Describe what a key does |
| `C-h w <cmd>` | Show key for command |
| `C-h i` | Open Info directory |
| `C-h r` | Open Emacs manual |

## Info Navigation

| Key | Action |
|-----|--------|
| `u` | Up (parent node) |
| `n` | Next node |
| `p` | Previous node |
| `l` | Back (last visited) |
| `t` | Top of manual |
| `d` | Directory (all manuals) |
| `Enter` | Follow link |
| `Tab` | Jump to next link |
| `q` | Quit Info |

## Key Notation

- `C-` = Ctrl
- `M-` = Alt (Meta)
- `S-` = Shift
- `s-` = Super (Windows key)

# Meow (Modal Editing)

## Windows

| Key | Action |
|-----|--------|
| `SPC <n> SPC m ^` | Expand window by `<n>` lines |

# pi-coding-agent (Emacs mode for pi)

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

| Key | Action |
|-----|--------|
| `n` / `p` | Navigate messages |
| `TAB` | Toggle tool section fold |
| `S-TAB` | Cycle all folds |
| `RET` | Visit file at point (other window) |
| `C-u RET` | Visit file at point (same window) |
| `q` | Quit session |
| `C-c C-p` | Open menu |

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
- **Click header**: Click model name or thinking level to change them

# LLM Workflow Essentials

## Most Common: Copy from Output → Paste to Input

**In Chat Buffer (Output):**

1. **Select text** (Meow NORMAL mode):
   - `x` = select current line
   - `w` = select word
   - `v` = expand selection
   
2. **Copy (save to kill ring):**
   - `y` = copy selection
   - `M-w` = copy (works in insert mode too)

3. **Switch to input window:**
   - `SPC o` (in NORMAL mode)
   - `C-x o` (works anywhere)

4. **Paste:**
   - `p` (Meow NORMAL mode)
   - `C-y` (works in insert mode)

**Quick Pattern:**
```
Chat buffer: x (select line) → y (copy) → SPC o (switch) → i (insert) → C-y (paste)
```

## Essential Meow + Consult Commands

**Search & Find (press ESC first, then SPC):**

| Key | Action | Why You Need It |
|-----|--------|-----------------|
| **SPC s** | Search current buffer | Find LLM's answer in long chat |
| **SPC r** | Recent files | Jump back to files LLM mentioned |
| **SPC f** | Find files in project | Open files LLM references |
| **SPC g** | Search across project | Find where LLM's code should go |

**Context Actions (works in any mode):**

| Key | Action | Why You Need It |
|-----|--------|-----------------|
| **M-.** | Show actions menu | See what you can do with file/buffer/text |
| **M-,** | Do obvious action | Quick open/switch without menu |

**Navigation:**

| Key | Action |
|-----|--------|
| `C-x b` | Switch buffers (with preview) | Jump between chat/input/files |
| `C-x p f` | Find file in project | Open files fast |
| `M-g g` | Go to line number | Jump to LLM-mentioned line |

## Kill Ring (Clipboard History)

| Key | Action |
|-----|--------|
| `M-y` | Browse kill ring | Access previous copies (even after multiple copies) |

## Window Management for LLM Work

| Key | Action | Use Case |
|-----|--------|----------|
| `C-x 1` | Maximize current | Focus on chat output |
| `C-x 2` | Split horizontal | Chat above, input below (default) |
| `C-x 3` | Split vertical | Chat left, code right |
| `C-x 0` | Close current | Clean up extra windows |
| `SPC o` | Next window | Switch between chat/input/code |

## Quick Workflow Examples

**1. Copy code from chat, paste to input:**
```
Chat: x y          (select line, copy)
      SPC o        (switch to input)
      i C-y        (insert mode, paste)
```

**2. Copy multiple things, paste specific one:**
```
Chat: x y          (copy first thing)
      [move] x y   (copy second thing)
Input: M-y M-y     (browse kill ring, select first)
```

**3. Find file LLM mentioned:**
```
ESC SPC f          (find file in project)
[type part of name with orderless fuzzy match]
```

**4. Search chat for previous answer:**
```
Chat: ESC SPC s    (search buffer)
[type search term, see live results]
```

**Remember:**
- In **NORMAL mode** (ESC): Use Meow keys (x, y, p, w, etc.)
- In **INSERT mode** (i): Use Emacs keys (C-y, M-w, C-s)
- **SPC** commands only work in NORMAL mode
- **M-.** and **M-,** work in ANY mode
