# tailtime.nvim

Time tracking with a beaver's tail 🦫

A simple Neovim plugin for tracking time spent on tasks. Features live timer display, project-based organization, priority levels, and comprehensive reporting.

## Features

- **Live Timer Display** — Shows elapsed time in lualine status bar
- **Project-Based Tasks** — Organize tasks by project (auto-detected from current directory)
- **Priority Levels** — Track tasks by priority (high/medium/low)
- **Persistent Storage** — Tasks saved as JSON files in `./tailtask/`
- **Time Reports** — View all tasks grouped by project with statistics
- **Export Options** — Export tasks to CSV or JSON format
- **Peak Hours** — Automatically calculates your most productive hours

## Installation

### Using lazy.nvim

```lua
{
  "yourusername/tailtime.nvim",
  config = function()
    require("tailtime").setup({
      -- optional config
    })
  end
}
```

### Using packer.nvim

```lua
use("yourusername/tailtime.nvim")
```

Then configure in your init.lua:

```lua
require("tailtime").setup({})
```

## Configuration

```lua
require("tailtime").setup({
  -- Data directory (default: ./tailtask)
  data_dir = "./tailtask",

  timer = {
    enabled = true,           -- Show timer in statusline
    position = "lualine_y",  -- Lualine section position
    format = "🦫 %s | %s",   -- Display format (task, time)
    color = { fg = "#a6e3a1" }, -- Timer color
  },

  export = {
    default_format = "csv",   -- Default export format
    separator = ",",
  },

  priority = {
    levels = { low = 1, medium = 2, high = 3 },
    icons = { low = "🟢", medium = "🟡", high = "🔴" },
  },
})
```

## Usage

### Commands

| Command | Description | Keymap |
|---------|-------------|--------|
| `:TailStart [task]` | Start a new task | `<leader>ts` |
| `:TailDone` | Stop timer and complete task | `<leader>te` |
| `:TailExport [csv\|json]` | Export tasks to file | `<leader>tx` |
| `:TailReport` | View time report | `<leader>tr` |

### Task Syntax

```vim
:TailStart My Task
:TailStart myproject: Fix bug @h
:TailStart @m
```

**Syntax:** `[project:] title [@priority]`

| Format | Example | Result |
|--------|---------|--------|
| `title` | `:TailStart Fix login` | Project = current dir, Priority = prompt |
| `project: title` | `:TailStart web: Build UI` | Project = "web", Title = "Build UI" |
| `title @priority` | `:TailStart Fix bug @h` | Priority = high |
| `project: title @priority` | `:TailStart api: Add auth @m` | Full specification |
| `@priority` | `:TailStart @l` | Quick task with priority |

**Priority shortcuts:** `@h` (high), `@m` (medium), `@l` (low)

### Report View

The report (`<leader>tr`) shows:

```
🦫 TAILTIME REPORT — All Projects (2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏰ Peak Hour     : 14 - 15 (2h 30m)

📁 sabiqazhar.github.io
   ⏱️  3h 15m | ✅ 3 | ⏳ 1
   ✅ 🟡 [14:00-15:30] Fix auth bug (1h 30m)
   ✅ 🟢 [15:45-17:00] Update README (1h 15m)
   ⏳ 🟡 [17:30-18:00] Review PR (30m)

📁 myproject
   ⏱️  1h 0m | ✅ 1 | ⏳ 0
   ✅ 🔴 [10:00-11:00] Critical fix (1h 0m)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 TOTAL: 4h 15m | 4 done / 1 pending

Press <q> to close • <e> export markdown
```

**Report features:**
- Peak productive hour analysis
- Tasks grouped by project
- Priority indicators (🟢🟡🔴)
- Status icons (✅ done, ⏳ pending)
- Time ranges and durations
- Export to markdown with `<e>`

### Data Storage

Tasks are stored in `./tailtask/` as daily JSON files:

```
./tailtask/
├── 2026-04-04.json
├── 2026-04-05.json
└── report_20260405_143022.md
```

**JSON structure:**
```json
{
  "date": "2026-04-04",
  "created_at": "2026-04-04T16:37:26Z",
  "next_id": 2,
  "tasks": [
    {
      "id": 1,
      "project": "myproject",
      "title": "Fix bug",
      "priority": "high",
      "status": "done",
      "start_ts": 1775320646,
      "end_ts": 1775320705,
      "duration_sec": 59,
      "created_at": "2026-04-04T16:37:26Z"
    }
  ]
}
```

## Requirements

- Neovim 0.10+ (uses `vim.uv` for timers)
- (Optional) [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) for status bar timer

## License

MIT
