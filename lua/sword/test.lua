-- lua/sword/test.lua
local M = {}

local case = require "sword.case"

local tests = {
  "myvariable",
  "myVariable",
  "MyVariable",
  "my_variable",
  "MY_VARIABLE",
  "my-variable",
  "MY-VARIABLE",
}

local lang = "default"

function M.case_test()
  for _, word in ipairs(tests) do
    print("Original: ", word)
    for i = 1, 8 do
      word = case.cycle_case(word, lang, false)
      print("  forward: ", word)
    end
    print "---"
  end
end

return M
