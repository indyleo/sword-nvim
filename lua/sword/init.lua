-- lua/sword/init.lua
local M = {}
M.groups = require "sword.groups"
M.signs = require "sword.signs"
M.core = require "sword.core"
M.commands = require "sword.commands"

M.config = {
  popup_timeout = 1000,
  mappings = true,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Create User Commands
  vim.api.nvim_create_user_command("SwapNext", function()
    M.core.replace(false)
  end, {})
  vim.api.nvim_create_user_command("SwapPrev", function()
    M.core.replace(true)
  end, {})
  vim.api.nvim_create_user_command("SwapSign", function()
    M.core.change_sign()
  end, {}) -- NEW
  vim.api.nvim_create_user_command("SwapCNext", function()
    M.core.case_cycle(false)
  end, {})

  -- Default Mappings
  if M.config.mappings then
    local map = vim.keymap.set
    -- Standard Group Swap
    map("n", "<leader>sw", ":SwapNext<CR>", { desc = "Sword: Swap Next" })
    map("n", "<leader>sW", ":SwapPrev<CR>", { desc = "Sword: Swap Prev" })

    -- NEW: Separate Sign Swap (e.g., numbers, ++, --)
    -- You can rebind this in your own config easily
    map("n", "<leader>ss", ":SwapSign<CR>", { desc = "Sword: Swap Sign (+/-)" })

    -- Case Cycling
    map("n", "<leader>sc", ":SwapCNext<CR>", { desc = "Sword: Case Cycle" })

    -- Repeat
    map("n", ".", function()
      if M.core.last_operation then
        M.core.repeat_last()
      else
        vim.cmd "normal! ."
      end
    end, { desc = "Sword: Repeat" })
  end
end

return M
