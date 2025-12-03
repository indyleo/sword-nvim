-- lua/sword/commands.lua
local sword = require "sword.core"
local tests = require "sword.test"
local mkcmd = vim.api.nvim_create_user_command

local function setup_commands()
  -- Commands
  mkcmd("SwapNext", function()
    sword.replace(false)
  end, { desc = "Cycle replacement forward" })

  mkcmd("SwapPrev", function()
    sword.replace(true)
  end, { desc = "Cycle replacement backward" })

  -- Test commands
  mkcmd("SwapTest", function()
    tests.all()
  end, { desc = "Run all Sword tests" })

  mkcmd("SwapTestCase", function()
    tests.case_test()
  end, { desc = "Run case cycling tests" })

  mkcmd("SwapTestSwap", function()
    tests.swap_test()
  end, { desc = "Run swap/replacement tests" })

  mkcmd("SwapBenchmark", function(opts)
    local iterations = tonumber(opts.args) or 10000
    tests.benchmark(iterations)
  end, {
    nargs = "?",
    desc = "Run performance benchmark (optional: iterations)",
  })

  mkcmd("SwapCNext", function(opts)
    sword.case_cycle(false, opts.range > 0)
  end, { range = true, desc = "Cycle case replacement forward" })

  mkcmd("SwapCPrev", function(opts)
    sword.case_cycle(true, opts.range > 0)
  end, { range = true, desc = "Cycle case replacement backward" })
end

return {
  setup_commands = setup_commands,
}
