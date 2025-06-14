-- lua/sword/signs.lua
local M = {}

function M.toggle_sign(word)
  -- toggle hex (e.g., -0xFF <-> 0xFF)
  if word:match "^%-?0x[%da-fA-F]+$" then
    return word:match "^%-" and word:sub(2) or "-" .. word
  end

  -- toggle decimal/float (e.g., -3.14 <-> 3.14)
  if word:match "^%-?%d+%.?%d*$" then
    return word:match "^%-" and word:sub(2) or "-" .. word
  end

  -- toggle ++ and --
  if word:find "%+%+" then
    return word:gsub("%+%+", "--", 1)
  elseif word:find "%-%-" then
    return word:gsub("%-%-", "++", 1)
  end

  return nil
end

return M
