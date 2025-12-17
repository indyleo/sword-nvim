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
  -- Symbol Groups
  { "==", "!=", "~=" },
  { "===", "!==" },
  { "<=", ">=" },
  { "<", ">" },
  { "<-", "->" },
  { "&&", "||" },
  { "+=", "-=" },
  { "*=", "/=" },
  -- Checkboxes (various styles)
  { "[]", "[ ]", "[x]", "[X]" },
  { "- [ ]", "- [x]" },
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
