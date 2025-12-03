-- lua/sword/core.lua
local M = {}

local groups = require "sword.groups"
local signs = require "sword.signs"
local casing = require "sword.casing"
local case = require "sword.case"

local replacement_groups = groups.get()

-- Store last operation for repeat support
M.last_operation = nil

-- 💬 show a small floating message near the cursor
function M.show_popup(msg)
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

  -- auto close after configured timeout
  local config = require("sword").config or {}
  local timeout = config.popup_timeout or 1000

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, timeout)
end

-- 🔄 Get word under cursor with better boundary detection
local function get_word_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  -- Find word boundaries
  local word_start = col
  local word_end = col

  -- Move backward to find start
  while word_start > 0 and line:sub(word_start, word_start):match "[%w_]" do
    word_start = word_start - 1
  end
  word_start = word_start + 1

  -- Move forward to find end
  while word_end <= #line and line:sub(word_end + 1, word_end + 1):match "[%w_]" do
    word_end = word_end + 1
  end

  local word = line:sub(word_start, word_end)
  return word, word_start, word_end, row, line
end

function M.replace(reverse)
  local word, word_start, word_end, row, line = get_word_at_cursor()

  if word == "" then
    print "No word under cursor"
    return
  end

  -- Store operation for repeat
  M.last_operation = { type = "replace", reverse = reverse }

  -- Try toggle sign
  local toggled = signs.toggle_sign(word)
  if toggled then
    local before = line:sub(1, word_start - 1)
    local after = line:sub(word_end + 1)
    local new_line = before .. toggled .. after
    vim.api.nvim_set_current_line(new_line)
    M.show_popup("Toggled → " .. toggled)
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

  -- Replace with proper boundaries
  local before = line:sub(1, word_start - 1)
  local after = line:sub(word_end + 1)
  local new_line = before .. replacement .. after

  -- Use undojoin to allow proper undo/redo
  local ok = pcall(vim.cmd, "undojoin")
  vim.api.nvim_set_current_line(new_line)

  M.show_popup("Swapped → " .. replacement)
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
  if #replacement_groups == 0 then
    print "No swap groups configured"
    return
  end

  for i, group in ipairs(replacement_groups) do
    print(string.format("%d: %s", i, table.concat(group, ", ")))
  end
end

function M.reload_swap_groups()
  replacement_groups = groups.reload()
  print "Reloaded swap groups from file"
end

-- 🎨 Case cycle with visual mode support
function M.case_cycle(reverse, is_visual)
  local filetype = vim.bo.filetype

  if reverse == nil then
    reverse = false
  end

  -- Store operation for repeat
  M.last_operation = { type = "case_cycle", reverse = reverse }

  if is_visual then
    -- Visual mode: cycle selected text
    local start_pos = vim.fn.getpos "'<"
    local end_pos = vim.fn.getpos "'>"
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    if start_row ~= end_row then
      print "Multi-line selection not supported for case cycling"
      return
    end

    local line = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
    local selected = line:sub(start_col, end_col)
    local swapped = case.cycle_case(selected, filetype, reverse)

    if selected ~= swapped then
      local before = line:sub(1, start_col - 1)
      local after = line:sub(end_col + 1)
      local new_line = before .. swapped .. after

      local ok = pcall(vim.cmd, "undojoin")
      vim.api.nvim_buf_set_lines(0, start_row - 1, start_row, false, { new_line })
      M.show_popup("Case → " .. swapped)
    end
  else
    -- Normal mode: cycle word under cursor
    local word, word_start, word_end, row, line = get_word_at_cursor()

    if word == "" then
      print "No word under cursor"
      return
    end

    local swapped = case.cycle_case(word, filetype, reverse)

    if word ~= swapped then
      local before = line:sub(1, word_start - 1)
      local after = line:sub(word_end + 1)
      local new_line = before .. swapped .. after

      local ok = pcall(vim.cmd, "undojoin")
      vim.api.nvim_set_current_line(new_line)
      M.show_popup("Case → " .. swapped)
    end
  end
end

-- ⚡ Repeat last operation (for . support)
function M.repeat_last()
  if not M.last_operation then
    print "No previous sword operation to repeat"
    return
  end

  local op = M.last_operation
  if op.type == "replace" then
    M.replace(op.reverse)
  elseif op.type == "case_cycle" then
    M.case_cycle(op.reverse, false)
  end
end

return M
