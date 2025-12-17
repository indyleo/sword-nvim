-- lua/sword/groups.lua
local M = {}

local default_groups = {
  { "true", "false" },
  { "yes", "no" },
  { "on", "off" },
  { "enable", "disable" },
  { "up", "down" },
  { "left", "right" },
  { "begin", "end" },
  { "first", "last" },
  { "min", "max" },
  { "width", "height" },
  { "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" },
  { "public", "private", "protected" },
  -- Symbols / Operators
  { "==", "!=", "~=" },
  { "===", "!==" },
  { "<=", ">=" },
  { "<", ">" },
  { "<-", "->" },
  { "&&", "||" },
  { "+=", "-=" },
  { "*=", "/=" },
  -- Checkboxes
  { "[]", "[ ]", "[x]", "[X]" },
  { "- [ ]", "- [x]" },
}

local groups = {}

function M.get()
  -- If empty, fill with defaults.
  -- We allow init.lua to append to this table later.
  if #groups == 0 then
    groups = vim.deepcopy(default_groups)
  end
  return groups
end

return M
