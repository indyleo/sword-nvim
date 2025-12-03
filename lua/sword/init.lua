-- lua/sword/init.lua
local M = {}

M.groups = require "sword.groups"
M.signs = require "sword.signs"
M.core = require "sword.core"
M.commands = require "sword.commands"

-- Default configuration
M.config = {
  popup_timeout = 1000,
  mappings = true,
  default_groups = true,
  custom_groups = {},
  lang_preferences = {},
}

function M.setup(opts)
  opts = opts or {}

  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Add custom groups if provided
  if M.config.custom_groups and #M.config.custom_groups > 0 then
    local groups = M.groups.get()
    for _, group in ipairs(M.config.custom_groups) do
      table.insert(groups, group)
    end
  end

  -- Setup commands
  M.commands.setup_commands()

  -- Setup default keymappings if enabled
  if M.config.mappings then
    -- Shorten function name
    local keymap = vim.keymap.set
    -- Keymap options helper
    local function opts(desc)
      return { noremap = true, silent = true, desc = desc }
    end
    -- Helper for multiple modes
    local function map(modes, lhs, rhs, desc)
      keymap(modes, lhs, rhs, opts(desc))
    end
    -- Normal mode mappings
    map("n", "<leader>sw", ":SwapNext<CR>", "Sword: Cycle word forward")
    map("n", "<leader>sW", ":SwapPrev<CR>", "Sword: Cycle word backward")
    map("n", "<leader>sc", ":SwapCNext<CR>", "Sword: Cycle case forward")
    map("n", "<leader>sC", ":SwapCPrev<CR>", "Sword: Cycle case backward")
    -- Visual mode mappings
    map("x", "<leader>sc", "<cmd>SwapCNext<CR>", "Sword: Cycle case forward (visual)")
    map("x", "<leader>sC", "<cmd>SwapCPrev<CR>", "Sword: Cycle case backward (visual)")
    -- Repeat support with dot
    map("n", ".", function()
      -- Check if last command was a sword operation
      if M.core.last_operation then
        M.core.repeat_last()
      else
        -- Fall back to default repeat
        vim.cmd "normal! ."
      end
    end, "Repeat last operation")
  end
end

return M
