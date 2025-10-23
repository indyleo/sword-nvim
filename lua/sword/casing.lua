-- lua/sword/casing.lua
local M = {}

function M.match_case(original, replacement)
  local base = replacement
  if original:match "^%u+$" then
    base = base:upper()
  elseif original:match "^%l+$" then
    base = base:lower()
  elseif original:match "^%u%l+$" then
    base = base:sub(1, 1):upper() .. base:sub(2):lower()
  end
  return base
end

return M
