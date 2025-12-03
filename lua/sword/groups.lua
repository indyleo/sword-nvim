-- lua/sword/groups.lua
local M = {}

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
  { "+=", "-=" },
  { "[]", "[X]" },
}

local groups = {}

function M.get()
  if #groups == 0 then
    groups = vim.deepcopy(default_groups)
  end
  return groups
end

function M.get_default()
  return default_groups
end

return M
