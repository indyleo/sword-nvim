-- lua/sword/core.lua
local M = {}

local groups = require "sword.groups"
local signs = require "sword.signs"
local casing = require "sword.casing"
local case = require "sword.case"

local replacement_groups = groups.get()

-- 💬 show a small floating message near the cursor
local function show_popup(msg)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { msg })

  -- compute popup width and height
  local width = vim.fn.strdisplaywidth(msg) + 2
  local height = 1

  local opts = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    noautocmd = true,
  }

  local win = vim.api.nvim_open_win(buf, false, opts)
  vim.api.nvim_set_option_value("winhl", "Normal:MoreMsg", { win = win })

  -- auto close after ~1 second
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 1000)
end

function M.replace(reverse)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local word = vim.fn.expand "<cword>"

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

  if not found_group then
    print("No replacement found for: " .. word)
    return
  end

  local next_idx = reverse and ((found_idx - 2) % #found_group + 1) or (found_idx % #found_group + 1)

  local replacement_raw = found_group[next_idx]
  local replacement = casing.match_case(word, replacement_raw)

  -- Match boundaries: capture any punctuation around
  local pattern = "([%w_]+)"
  local new_line, count = line:gsub(pattern, function(match)
    if match:lower() == word:lower() then
      return replacement
    end
    return match
  end, 1)

  if count == 0 then
    -- fallback with punctuation-aware pattern
    local alt_pat = "([^%w_])" .. vim.pesc(word) .. "([^%w_])"
    new_line = line:gsub(alt_pat, function(before, after)
      return before .. replacement .. after
    end, 1)
  end

  vim.api.nvim_set_current_line(new_line)
  show_popup("Swapped → " .. replacement)
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
    show_popup("Case → " .. swapped)
  end
end

return M
