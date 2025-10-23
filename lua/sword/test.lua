-- lua/sword/test.lua
local M = {}

local case = require "sword.case"
local casing = require "sword.casing"
local signs = require "sword.signs"
local groups = require "sword.groups"

-- ✅ case cycling tests
local case_tests = {
  "myvariable",
  "myVariable",
  "MyVariable",
  "my_variable",
  "MY_VARIABLE",
  "my-variable",
  "MY-VARIABLE",
  "MyXMLParser",
  "HTTPRequest",
  "id2Name",
  "userID",
  "file_v2",
  "count",
}

-- ✅ punctuation + edge replacement tests
local swap_tests = {
  "true",
  "True",
  "FALSE",
  "false,",
  "(False)",
  "yes;",
  "off)",
  "-3.14",
  "0xFF",
  "++",
  "--",
  "north",
  "west",
}

-- helper to print section headers
local function section(title)
  print(("\n==== %s ===="):format(title))
end

-- test 1: case cycling
function M.case_test()
  section "CASE CYCLING"
  local lang = "default"

  for _, word in ipairs(case_tests) do
    print("→ Original:", word)
    local seen = {}
    for i = 1, 8 do
      word = case.cycle_case(word, lang, false)
      if seen[word] then
        break
      end -- stop infinite loops
      seen[word] = true
      print(("   [%d] %s"):format(i, word))
    end
  end
end

-- test 2: replacement groups
function M.swap_test()
  section "REPLACEMENT / SIGN TOGGLE"
  local replacement_groups = groups.get()

  for _, word in ipairs(swap_tests) do
    local toggled = signs.toggle_sign(word)
    if toggled then
      print(("→ Sign toggle: %s → %s"):format(word, toggled))
    else
      local found_group, found_idx
      for _, group in ipairs(replacement_groups) do
        for idx, token in ipairs(group) do
          if token:lower() == word:lower():gsub("%p", "") then
            found_group = group
            found_idx = idx
            break
          end
        end
        if found_group then
          break
        end
      end
      if found_group then
        local next_idx = (found_idx % #found_group) + 1
        local replacement_raw = found_group[next_idx]
        local replacement = casing.match_case(word, replacement_raw)
        print(("→ Swap: %s → %s"):format(word, replacement))
      else
        print(("→ No group match: %s"):format(word))
      end
    end
  end
end

--------------------------------------------------------------------
-- 🔥 PERFORMANCE BENCHMARKS
--------------------------------------------------------------------
function M.benchmark(iterations)
  iterations = iterations or 10000
  print(("\n==== BENCHMARK (%d iterations) ===="):format(iterations))

  local start_time = vim.loop.hrtime()

  local words = {
    "true",
    "false",
    "MyVariable",
    "my_variable",
    "HTTPRequest",
    "snake_case",
    "kebab-case",
    "SCREAM_CASE",
    "file_v2",
    "off",
  }

  local langs = { "lua", "python", "javascript", "rust", "default" }

  -- benchmark case cycling
  for i = 1, iterations do
    local word = words[(i % #words) + 1]
    local lang = langs[(i % #langs) + 1]
    case.cycle_case(word, lang, false)
  end

  -- benchmark replacement toggles
  local signs = require "sword.signs"
  for i = 1, iterations do
    local word = words[(i % #words) + 1]
    signs.toggle_sign(word)
  end

  local elapsed = (vim.loop.hrtime() - start_time) / 1e6 -- ms
  local per_op = elapsed / (iterations * 2)
  print(("✅ Done in %.2f ms (%.4f ms per op)\n"):format(elapsed, per_op))
end

function M.all()
  M.case_test()
  M.swap_test()
end

return M
