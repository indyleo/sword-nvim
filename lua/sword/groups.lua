-- lua/sword/groups.lua
local M = {}

local swap_file = vim.fn.stdpath "data" .. "/sword_swaps.lua"

local default_groups = {
  { "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" },
  { "true", "false" },
  { "undefined", "null" },
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

local groups = {}

function M.get()
  if #groups == 0 then
    local ok, loaded = pcall(dofile, swap_file)
    if ok and type(loaded) == "table" then
      groups = loaded
    else
      groups = default_groups
    end
  end
  return groups
end

function M.save()
  local f, err = io.open(swap_file, "w")
  if not f then
    return false, err
  end

  f:write "return {\n"
  for _, group in ipairs(groups) do
    f:write "  { "
    for i, word in ipairs(group) do
      f:write(string.format("%q", word))
      if i < #group then
        f:write ", "
      end
    end
    f:write " },\n"
  end
  f:write "}\n"
  f:close()
  return true
end

function M.reload()
  groups = {}
  return M.get()
end

return M
