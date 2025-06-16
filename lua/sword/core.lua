-- lua/sword/core.lua
local M = {}

local groups = require "sword.groups"
local signs = require "sword.signs"
local casing = require "sword.casing"
local case = require "sword.case"

local replacement_groups = groups.get()

function M.replace(reverse)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local word = vim.fn.expand "<cWORD>"

  -- Try toggle sign
  local toggled = signs.toggle_sign(word)
  if toggled then
    local new_line = line:gsub(vim.pesc(word), toggled, 1)
    vim.api.nvim_set_current_line(new_line)
    return
  end

  -- Try replacement groups
  local found_group, found_idx
  for _, group in ipairs(replacement_groups) do
    for idx, token in ipairs(group) do
      if token:lower() == word:lower() then
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
    local next_idx = reverse and ((found_idx - 2) % #found_group + 1) or (found_idx % #found_group + 1)
    local replacement_raw = found_group[next_idx]
    local replacement = casing.match_case(word, replacement_raw)
    local new_line = line:gsub(vim.pesc(word), replacement, 1)
    vim.api.nvim_set_current_line(new_line)
  else
    print("No replacement found for: " .. word)
  end
end

function M.add_swap_group(args)
  if #args < 2 then
    print "Need at least two words to form a swap group"
    return
  end
  table.insert(replacement_groups, args)
  local ok, err = groups.save()
  if ok then
    print "Added swap group and saved"
  else
    print("Failed to save swap groups: " .. (err or "unknown error"))
  end
end

function M.remove_swap_group(index_str)
  local idx = tonumber(index_str)
  if not idx or idx < 1 or idx > #replacement_groups then
    print("Invalid index: " .. tostring(index_str))
    return
  end
  table.remove(replacement_groups, idx)
  local ok, err = groups.save()
  if ok then
    print "Removed swap group and saved"
  else
    print("Failed to save swap groups: " .. (err or "unknown error"))
  end
end

function M.list_swap_groups()
  for i, group in ipairs(replacement_groups) do
    print(string.format("%d: %s", i, table.concat(group, ", ")))
  end
end

function M.reload_swap_groups()
  replacement_groups = groups.reload()
  print "Reloaded swap groups from file"
end

function M.case_cycle(reverse)
  local word = vim.fn.expand "<cword>"
  local filetype = vim.bo.filetype
  if reverse == nil then
    reverse = false -- default forward (not reversed)
  end
  local swapped = case.cycle_case(word, filetype, reverse)
  if word ~= swapped then
    vim.cmd("normal! ciw" .. swapped)
  end
end

return M
