-- lua/sword/commands.lua
local sword = require "sword.core"
local mkcmd = vim.api.nvim_create_user_command

local function setup_commands()
  -- Commands
  mkcmd("SwapNext", function()
    sword.replace(false)
  end, { desc = "Cycle replacement forward" })

  mkcmd("SwapPrev", function()
    sword.replace(true)
  end, { desc = "Cycle replacement backward" })

  mkcmd("SwapAdd", function(args)
    sword.add_swap_group(args)
  end, {
    nargs = "+",
    desc = "Add a new word swap group and save it",
  })

  mkcmd("SwapRm", function(opts)
    sword.remove_swap_group(opts.args)
  end, {
    nargs = 1,
    desc = "Remove a swap group by index",
  })

  mkcmd("SwapList", function()
    sword.list_swap_groups()
  end, { desc = "List active swap groups" })

  mkcmd("SwapReload", function()
    sword.reload_swap_groups()
  end, { desc = "Reload swap groups from swaps.lua" })
end

return {
  setup_commands = setup_commands,
}
