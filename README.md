# sword.nvim

A powerful word swapping and case cycling plugin for Neovim. Quickly toggle between related words (true/false, on/off) and cycle through different case styles (camelCase, snake_case, PascalCase, etc.) with intuitive keybindings.

## ✨ Features

- 🔄 **Smart Word Swapping**: Cycle through related word groups (true/false, yes/no, on/off, etc.)
- 🎨 **Intelligent Case Cycling**: Convert between camelCase, snake_case, PascalCase, SCREAM_CASE, kebab-case, and more
- 🔍 **Acronym-Aware**: Properly handles acronyms like `HTTPRequest` → `http_request`
- 👁️ **Visual Mode Support**: Cycle case on selected text
- ⚡ **Repeat Support**: Use `.` to repeat the last sword operation
- 🎯 **Language-Aware**: Preferred case styles per language (snake_case for Python, camelCase for JavaScript, etc.)
- ➕ **Sign Toggling**: Toggle numeric signs (-42 ↔ 42), increment/decrement operators (++ ↔ --)
- 💾 **Persistent Storage**: Save custom swap groups that persist across sessions
- 🎪 **Visual Feedback**: Popup notifications show what changed

## 📦 Installation

### Lazy.nvim

```lua
return {
  "indyleo/sword-nvim",
  lazy = false,
  config = function()
    require('sword').setup({
      popup_timeout = 1000,  -- Popup display duration in ms
      mappings = true,       -- Enable default keymappings
      custom_groups = {      -- Add your own swap groups
        { "foo", "bar", "baz" },
        { "public", "private", "protected" },
      },
    })
  end,
}
```

### Packer

```lua
use {
  'indyleo/sword-nvim',
  config = function()
    require('sword').setup()
  end
}
```

### vim-plug

```vim
Plug 'indyleo/sword-nvim'

" In your init.lua or in a lua block:
lua << EOF
require('sword').setup()
EOF
```

## ⌨️ Default Keymappings

| Mode   | Key          | Action                           |
| ------ | ------------ | -------------------------------- |
| Normal | `<leader>sw` | Cycle word forward (swap group)  |
| Normal | `<leader>sW` | Cycle word backward (swap group) |
| Normal | `<leader>sc` | Cycle case forward               |
| Normal | `<leader>sC` | Cycle case backward              |
| Visual | `<leader>sc` | Cycle case forward on selection  |
| Visual | `<leader>sC` | Cycle case backward on selection |
| Normal | `.`          | Repeat last sword operation      |

**Note:** All mappings use `<leader>s` as a prefix (s for "sword"). By default in Neovim, `<leader>` is the backslash `\` key, but most users remap it to space.

Disable default mappings by setting `mappings = false` in setup, then define your own:

```lua
require('sword').setup({ mappings = false })

-- Custom mappings example
vim.keymap.set('n', 'cr', '<cmd>SwapNext<CR>')
vim.keymap.set('n', 'cR', '<cmd>SwapPrev<CR>')
vim.keymap.set('n', 'crc', '<cmd>SwapCNext<CR>')
```

## 🎯 Usage Examples

### Word Swapping

Place cursor on a word and press `<leader>sw`:

```
true    →  false   →  true
on      →  off     →  on
yes     →  no      →  maybe  →  yes
monday  →  tuesday →  wednesday  →  ...
++      →  --      →  ++
-42     →  42      →  -42
```

### Case Cycling

Place cursor on a word and press `<leader>sc`:

```
myVariable   →  MyVariable   →  my_variable  →  MY_VARIABLE  →  ...
HTTPRequest  →  httpRequest  →  HttpRequest  →  http_request  →  ...
user_id      →  userId       →  UserId       →  USER_ID      →  ...
```

### Visual Mode

Select text and press `<leader>sc` to cycle case:

```
visual selection: "some_variable_name"
press <leader>sc  →  "someVariableName"
press <leader>sc  →  "SomeVariableName"
```

### Repeat with Dot

```
1. Cursor on "true", press <leader>sw  →  "false"
2. Move cursor to another "true"
3. Press .  →  "false" (repeats last operation)
```

## 🎮 Commands

### Word Swapping

| Command                      | Description                            |
| ---------------------------- | -------------------------------------- |
| `:SwapNext`                  | Cycle word forward through swap group  |
| `:SwapPrev`                  | Cycle word backward through swap group |
| `:SwapAdd word1 word2 word3` | Add a new swap group                   |
| `:SwapRm <index>`            | Remove swap group by index             |
| `:SwapList`                  | List all active swap groups            |
| `:SwapReload`                | Reload swap groups from file           |

### Case Cycling

| Command      | Description               |
| ------------ | ------------------------- |
| `:SwapCNext` | Cycle case style forward  |
| `:SwapCPrev` | Cycle case style backward |

### Testing

| Command                       | Description                |
| ----------------------------- | -------------------------- |
| `:SwapTest`                   | Run all tests              |
| `:SwapTestCase`               | Run case cycling tests     |
| `:SwapTestSwap`               | Run swap/replacement tests |
| `:SwapBenchmark [iterations]` | Run performance benchmark  |

## 📝 Configuration

### Full Configuration Example

```lua
require('sword').setup({
  -- Popup display duration in milliseconds
  popup_timeout = 1000,

  -- Enable/disable default keymappings
  mappings = true,

  -- Use default swap groups (true) or start fresh (false)
  default_groups = true,

  -- Add custom swap groups
  custom_groups = {
    { "foo", "bar", "baz" },
    { "public", "private", "protected" },
    { "get", "post", "put", "delete", "patch" },
    { "development", "staging", "production" },
  },

  -- Language-specific case style preferences (optional)
  lang_preferences = {
    lua = { "snake_case", "camelCase", "PascalCase" },
    python = { "snake_case", "SCREAM_CASE" },
    javascript = { "camelCase", "PascalCase" },
  },
})
```

### Default Swap Groups

The plugin comes with these default swap groups:

```lua
{ "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" }
{ "true", "false" }
{ "undefined", "null" }
{ "on", "off" }
{ "always", "never" }
{ "enable", "disable" }
{ "yes", "no", "maybe" }
{ "up", "down" }
{ "left", "right" }
{ "begin", "end" }
{ "first", "last" }
{ "north", "east", "south", "west" }
{ "==", "!=", "~=" }
{ "<", ">" }
{ "<-", "->" }
{ "<=", ">=" }
{ "&&", "||" }
{ "+=", "-=" }
{ "[]", "[X]" }
```

### Managing Swap Groups

```vim
" Add a new swap group
:SwapAdd foo bar baz

" List all groups with their indices
:SwapList
" Output:
" 1: monday, tuesday, wednesday, thursday, friday, saturday, sunday
" 2: true, false
" 3: foo, bar, baz

" Remove a group by index
:SwapRm 3

" Reload from saved file
:SwapReload
```

Swap groups are automatically saved to `~/.local/share/nvim/sword_swaps.lua` and persist across sessions.

## 🎨 Supported Case Styles

| Style       | Example       |
| ----------- | ------------- |
| flatcase    | `myvariable`  |
| camelCase   | `myVariable`  |
| PascalCase  | `MyVariable`  |
| snake_case  | `my_variable` |
| SCREAM_CASE | `MY_VARIABLE` |
| kebab-case  | `my-variable` |
| COBOL-CASE  | `MY-VARIABLE` |

The plugin intelligently handles:

- **Acronyms**: `HTTPRequest` → `["http", "request"]`
- **Mixed case**: `XMLParser` → `["xml", "parser"]`
- **Numbers**: `file_v2` → `["file", "v2"]`

## 🧪 Running Tests

Test the plugin functionality:

```vim
" Run all tests
:SwapTest

" Run specific test suites
:SwapTestCase
:SwapTestSwap

" Run performance benchmark
:SwapBenchmark
:SwapBenchmark 50000

" Or from command line
:lua require('sword.test').all()
:lua require('sword.test').benchmark(10000)
```

Or test interactively:

1. Open a buffer and type: `myVariable true snake_case -42`
2. Place cursor on each word
3. Press `<leader>sw`, `<leader>sc`, or other mappings to see them cycle

## 🚀 Advanced Usage

### Case-Preserving Replacements

The plugin preserves the original case when swapping:

```
TRUE  →  FALSE
True  →  False
true  →  false
```

### Language-Aware Case Cycling

Different languages prefer different case styles:

```lua
-- Python: prefers snake_case
user_name  →  USER_NAME  →  userName  →  ...

-- JavaScript: prefers camelCase
userName  →  UserName  →  user_name  →  ...
```

### Repeat Operations

After any sword operation, press `.` to repeat it on the next word:

```
Line: "true foo true bar true"
      ^
1. Press <leader>sw → "false foo true bar true"
2. Move to next "true": "false foo true bar true"
                                 ^
3. Press . → "false foo false bar true"
4. Move and repeat...
```

## 🐛 Troubleshooting

### Mappings not working

Check if mappings are enabled:

```lua
require('sword').setup({ mappings = true })
```

### Custom groups not persisting

Custom groups added via `:SwapAdd` are saved to:

```
~/.local/share/nvim/sword_swaps.lua
```

Check file permissions and ensure the directory exists.

### Case cycling not working as expected

The plugin detects case style automatically. If detection fails, it falls back to `flatcase`. You can manually add language preferences:

```lua
require('sword').setup({
  lang_preferences = {
    myfiletype = { "preferred_case", "second_choice", "third_choice" },
  },
})
```

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Add more default swap groups

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Credits

Created by [@indyleo](https://github.com/indyleo)

---

**Enjoy swapping! 🗡️**
