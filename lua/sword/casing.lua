local M = {}

function M.match_case(original, replacement)
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

return M
