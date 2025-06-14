local M = {}

function M.setup()
  local FCword = require "sword.functions.Cword"
  local mkcmd = vim.api.nvim_create_user_command

  -- Commands
  mkcmd("SwapNext", function()
    FCword.replace(false)
  end, { desc = "Cycle replacement forward" })

  mkcmd("SwapPrev", function()
    FCword.replace(true)
  end, { desc = "Cycle replacement backward" })

  mkcmd("SwapAdd", function(args)
    FCword.add_swap_group(args)
  end, {
    nargs = "+",
    desc = "Add a new word swap group and save it",
  })

  mkcmd("SwapRm", function(opts)
    FCword.remove_swap_group(opts.args)
  end, {
    nargs = 1,
    desc = "Remove a swap group by index",
  })

  mkcmd("SwapList", function()
    FCword.list_swap_groups()
  end, { desc = "List active swap groups" })

  mkcmd("SwapReload", function()
    FCword.reload_swap_groups()
  end, { desc = "Reload swap groups from swaps.lua" })
end

return M
