-- lua/sword/core.lua
local M = {}

local groups = require "sword.groups"
local signs = require "sword.signs"
local casing = require "sword.casing"
local case = require "sword.case"

M.last_operation = nil

-- 💬 Popup helper
function M.show_popup(msg)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { msg })
  local width = vim.fn.strdisplaywidth(msg) + 2
  local opts = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = width,
    height = 1,
    style = "minimal",
    border = "rounded",
    noautocmd = true,
  }
  local win = vim.api.nvim_open_win(buf, false, opts)
  vim.api.nvim_set_option_value("winhl", "Normal:MoreMsg", { win = win })
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 1000)
end

local function escape_pattern(text)
  return text:gsub("([^%w])", "%%%1")
end

-- 🔍 Find symbols (Requires groups to be passed in)
local function get_symbol_at_cursor(line, col, replacement_groups)
  local found_match = nil
  local best_len = 0

  for _, group in ipairs(replacement_groups) do
    for idx, token in ipairs(group) do
      if token:match "[^%w_]" then -- Only check symbols here
        local escaped = escape_pattern(token)
        local start_search = 1
        while true do
          local s, e = line:find(escaped, start_search)
          if not s then
            break
          end
          -- Check overlap with cursor
          if (col + 1) >= s and (col + 1) <= e then
            if (e - s + 1) > best_len then
              best_len = (e - s + 1)
              found_match = { group = group, idx = idx, text = token, start_col = s, end_col = e }
            end
          end
          start_search = e + 1
        end
      end
    end
  end
  return found_match
end

local function get_word_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if #line == 0 or not line:sub(col + 1, col + 1):match "[%w_]" then
    return "", 0, 0, row, line
  end

  local s, e = col + 1, col + 1
  while s > 1 and line:sub(s - 1, s - 1):match "[%w_]" do
    s = s - 1
  end
  while e < #line and line:sub(e + 1, e + 1):match "[%w_]" do
    e = e + 1
  end
  return line:sub(s, e), s, e, row, line
end

-- ==========================================
-- 1. Standard Swap (Groups, Words, Symbols)
-- ==========================================
function M.replace(reverse)
  -- 🔥 FIX: Fetch groups here so we see Custom Groups added during setup()
  local replacement_groups = groups.get()

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  M.last_operation = { type = "replace", reverse = reverse }

  -- A. Priority: Check Symbols (<=, [ ], !=)
  local symbol = get_symbol_at_cursor(line, col, replacement_groups)
  if symbol then
    local next_idx = reverse and ((symbol.idx - 2) % #symbol.group + 1) or (symbol.idx % #symbol.group + 1)
    local replacement = symbol.group[next_idx]
    local new_line = line:sub(1, symbol.start_col - 1) .. replacement .. line:sub(symbol.end_col + 1)

    pcall(vim.cmd, "undojoin")
    vim.api.nvim_set_current_line(new_line)
    M.show_popup("Symbol → " .. replacement)
    return
  end

  -- B. Priority: Check Words (foo, true, monday)
  local word, s, e = get_word_at_cursor()
  if word == "" then
    print "No item under cursor"
    return
  end

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
    local replacement = casing.match_case(word, found_group[next_idx])
    local new_line = line:sub(1, s - 1) .. replacement .. line:sub(e + 1)

    pcall(vim.cmd, "undojoin")
    vim.api.nvim_set_current_line(new_line)
    M.show_popup("Swap → " .. replacement)
  else
    print("No replacement found for: " .. word)
  end
end

-- ==========================================
-- 2. Sign Swap (Numbers, ++, --)
-- ==========================================
function M.change_sign()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  M.last_operation = { type = "change_sign" }

  -- A. Check for ++ / -- nearby
  local ops = { "++", "--" }
  for _, op in ipairs(ops) do
    -- Search in a small window around cursor to catch i++ or ++i
    local s, e = line:find(op, math.max(1, col - 1), true)
    if s and col + 1 >= s and col + 1 <= e then
      local replacement = signs.toggle_sign(op)
      local new_line = line:sub(1, s - 1) .. replacement .. line:sub(e + 1)
      pcall(vim.cmd, "undojoin")
      vim.api.nvim_set_current_line(new_line)
      M.show_popup("Sign → " .. replacement)
      return
    end
  end

  -- B. Check for Number (including negative)
  local word, s, e = get_word_at_cursor()
  if word ~= "" then
    local full_word = word
    local full_s = s
    -- Grab preceding minus if it exists
    if s > 1 and line:sub(s - 1, s - 1) == "-" then
      full_word = "-" .. word
      full_s = s - 1
    end

    local toggled = signs.toggle_sign(full_word)
    if toggled then
      local new_line = line:sub(1, full_s - 1) .. toggled .. line:sub(e + 1)
      pcall(vim.cmd, "undojoin")
      vim.api.nvim_set_current_line(new_line)
      M.show_popup("Sign → " .. toggled)
      return
    end
  end

  print "No sign/number found"
end

function M.case_cycle(reverse, is_visual)
  -- Standard case cycle logic (same as your existing file)
  local filetype = vim.bo.filetype
  if reverse == nil then
    reverse = false
  end
  M.last_operation = { type = "case_cycle", reverse = reverse }

  if is_visual then
    local start_pos = vim.fn.getpos "'<"
    local end_pos = vim.fn.getpos "'>"
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]
    local line = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
    local selected = line:sub(start_col, end_col)
    local swapped = case.cycle_case(selected, filetype, reverse)

    if selected ~= swapped then
      local before = line:sub(1, start_col - 1)
      local after = line:sub(end_col + 1)
      local new_line = before .. swapped .. after
      pcall(vim.cmd, "undojoin")
      vim.api.nvim_buf_set_lines(0, start_row - 1, start_row, false, { new_line })
      M.show_popup("Case → " .. swapped)
    end
  else
    local word, word_start, word_end, row, line = get_word_at_cursor()
    if word == "" then
      return
    end
    local swapped = case.cycle_case(word, filetype, reverse)
    if word ~= swapped then
      local before = line:sub(1, word_start - 1)
      local after = line:sub(word_end + 1)
      local new_line = before .. swapped .. after
      pcall(vim.cmd, "undojoin")
      vim.api.nvim_set_current_line(new_line)
      M.show_popup("Case → " .. swapped)
    end
  end
end

function M.repeat_last()
  if not M.last_operation then
    return
  end
  if M.last_operation.type == "replace" then
    M.replace(M.last_operation.reverse)
  elseif M.last_operation.type == "change_sign" then
    M.change_sign()
  elseif M.last_operation.type == "case_cycle" then
    M.case_cycle(M.last_operation.reverse, false)
  end
end

return M
