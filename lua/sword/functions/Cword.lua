-- lua/functions/Cword.lua

local M = {}

local swap_file = vim.fn.stdpath "data" .. "/swaps.lua"

local default_groups = {
  { "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" },
  { "true", "false", "null" },
  { "on", "off" },
  { "always", "never" },
  { "enable", "disable" },
  { "yes", "no", "maybe" },
  { "up", "down" },
  { "left", "right" },
  { "begin", "end" },
  { "first", "last" },
  { "north", "east", "south", "west" },
  { "==", "!=", "~=" },
  { "<", ">" },
  { "<-", "->" },
  { "<=", ">=" },
  { "&&", "||" },
  { "++", "--" },
}

-- Write the default groups to a file
local function write_default_groups(path)
  local f = io.open(path, "w")
  if not f then
    print("Failed to create swap groups file at " .. path)
    return false
  end
  f:write "return {\n"
  for _, group in ipairs(default_groups) do
    f:write("  { " .. table.concat(
      vim.tbl_map(function(w)
        return string.format("%q", w)
      end, group),
      ", "
    ) .. " },\n")
  end
  f:write "}\n"
  f:close()
  return true
end

-- Load the persistent swap_groups file
local function load_persistent_groups()
  local path = swap_file
  local f = io.open(path, "r")
  if not f then
    -- File does not exist, create with defaults
    if write_default_groups(path) then
      print "Created swaps.lua with default groups"
    end
  else
    f:close()
  end

  local ok, groups = pcall(dofile, path)
  if not ok or type(groups) ~= "table" then
    print "Failed to load swaps.lua or invalid format, using defaults in memory"
    return default_groups
  end

  return groups
end

-- Reload swap groups
function M.reload_swap_groups()
  local path = swap_file
  local f = io.open(path, "r")
  local groups

  if not f then
    groups = default_groups
    print "swaps.lua not found, using default groups"
  else
    f:close()
    local ok, loaded = pcall(dofile, path)
    if not ok or type(loaded) ~= "table" then
      groups = default_groups
      print "Failed to load swaps.lua or invalid format, using default groups"
    else
      groups = loaded
      print "swaps.lua reloaded successfully"
    end
  end

  M.replacement_groups = groups
end

-- Replacement groups: words that cycle through each other
M.reload_swap_groups()

vim.pesc = vim.pesc or function(s)
  return s:gsub("([^%w])", "%%%1")
end

local function is_word_token(token)
  return token:match "^%w+$" ~= nil
end

local function match_case(original, replacement)
  if original:match "^%u+$" then
    return replacement:upper()
  elseif original:match "^%l+$" then
    return replacement:lower()
  elseif original:match "^%u%l+$" then
    return replacement:sub(1, 1):upper() .. replacement:sub(2):lower()
  else
    return replacement
  end
end

-- List swap groups
function M.list_swap_groups()
  print "Active Swap Groups:"
  for i, group in ipairs(M.replacement_groups) do
    print(string.format("%d: %s", i, table.concat(group, ", ")))
  end
end

-- Add swap group
function M.add_swap_group(args)
  local new_group = {}
  for word in string.gmatch(args.args, "%S+") do
    table.insert(new_group, word)
  end

  if #new_group < 2 then
    print "Error: Provide at least two words to form a swap group."
    return
  end

  -- Load current groups
  local current_groups = load_persistent_groups()
  table.insert(current_groups, new_group)

  -- Serialize and write the full file
  local path = swap_file
  local f = io.open(path, "w")
  if not f then
    print("Failed to write to", path)
    return
  end

  f:write "return {\n"
  for _, group in ipairs(current_groups) do
    local serialized = "  { "
      .. table.concat(
        vim.tbl_map(function(w)
          return string.format("%q", w)
        end, group),
        ", "
      )
      .. " },\n"
    f:write(serialized)
  end
  f:write "}\n"
  f:close()

  -- Also update in-memory
  table.insert(M.replacement_groups, new_group)

  print("Added swap group permanently:", table.concat(new_group, ", "))
end

-- Remove a swap group
function M.remove_swap_group(index)
  index = tonumber(index)
  if not index or index < 1 or index > #M.replacement_groups then
    print "Invalid swap group index."
    return
  end

  local removed = table.remove(M.replacement_groups, index)
  print("Removed swap group:", table.concat(removed, ", "))

  -- Update persistent swaps.lua file (overwrite)
  local path = swap_file
  local f, err = io.open(path, "w")
  if not f then
    print("Failed to open swaps.lua for writing:", err)
    return
  end

  f:write "return {\n"
  -- Write all groups except the removed one
  for _, group in ipairs(M.replacement_groups) do
    local line = "  { " .. table.concat(
      vim.tbl_map(function(w)
        return string.format("%q", w)
      end, group),
      ", "
    ) .. " },\n"
    f:write(line)
  end
  f:write "}\n"
  f:close()
end

-- Replace cword
function M.replace(reverse)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local line_lower = line:lower()
  local cursor_pos = col + 1

  local found_token = nil
  local found_start = nil
  local found_end = nil
  local found_group = nil
  local found_idx = nil

  -- Toggle numeric sign: -num <-> num
  local num_pattern = "[+-]?%d+%.?%d*"
  local start = 1
  while true do
    local s, e = line:find(num_pattern, start)
    if not s then
      break
    end

    if cursor_pos >= s and cursor_pos <= e then
      local token = line:sub(s, e)
      local flipped

      if token:sub(1, 1) == "-" then
        flipped = token:sub(2) -- remove minus
      else
        flipped = "-" .. token:gsub("^%+", "") -- remove leading + if exists
      end

      local new_line = line:sub(1, s - 1) .. flipped .. line:sub(e + 1)
      vim.api.nvim_set_current_line(new_line)
      vim.api.nvim_win_set_cursor(0, { row, s - 1 + #flipped })
      return
    end

    start = e + 1
  end

  -- Search for tokens
  for _, group in ipairs(M.replacement_groups) do
    for idx, token in ipairs(group) do
      local token_lower = token:lower()
      local token_len = #token_lower
      local start_pos = 1

      while true do
        local s, e = line_lower:find(token_lower, start_pos, true)
        if not s then
          break
        end

        local is_valid = true
        if is_word_token(token) then
          local before = s == 1 or not line_lower:sub(s - 1, s - 1):match "[%w]"
          local after = e == #line_lower or not line_lower:sub(e + 1, e + 1):match "[%w]"
          is_valid = before and after
        end

        if is_valid and cursor_pos >= s and cursor_pos <= e then
          local original_token = line:sub(s, e)
          if not found_token or (#original_token > #found_token) then
            found_token = original_token
            found_start = s
            found_end = e
            found_group = group
            found_idx = idx
          end
        end

        start_pos = e + 1
      end
    end
  end

  if not found_token then
    print "No replacement token found under cursor"
    return
  end

  local next_idx
  if reverse then
    next_idx = (found_idx - 2) % #found_group + 1
  else
    next_idx = (found_idx % #found_group) + 1
  end

  local next_token = found_group[next_idx]
  local replacement_token = match_case(found_token, next_token)

  local new_line = line:sub(1, found_start - 1) .. replacement_token .. line:sub(found_end + 1)
  vim.api.nvim_set_current_line(new_line)

  local new_cursor_col = found_start - 1 + #replacement_token
  vim.api.nvim_win_set_cursor(0, { row, new_cursor_col })
end

return M
