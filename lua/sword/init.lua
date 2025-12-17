local M = {}
M.groups = require "sword.groups"
M.signs = require "sword.signs"
M.core = require "sword.core"
M.commands = require "sword.commands"

M.config = {
  popup_timeout = 1000,
  mappings = true,
  custom_groups = {},
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Add custom groups to the global list
  if M.config.custom_groups and #M.config.custom_groups > 0 then
    local groups = M.groups.get()
    for _, group in ipairs(M.config.custom_groups) do
      table.insert(groups, group)
    end
  end

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
    -- 1. Standard Swap (Words & Symbols like <=, [])
    map("n", "<leader>sw", ":SwapNext<CR>", { desc = "Sword: Swap Next" })
    map("n", "<leader>sW", ":SwapPrev<CR>", { desc = "Sword: Swap Prev" })

    -- 2. Sign Swap (Numbers -5, ++, --)
    map("n", "<leader>ss", ":SwapSign<CR>", { desc = "Sword: Swap Sign (+/-)" })

    -- 3. Case Cycling
    map("n", "<leader>sc", ":SwapCNext<CR>", { desc = "Sword: Case Cycle" })

    -- 4. Repeat
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
