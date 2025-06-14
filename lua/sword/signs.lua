-- lua/sword/signs.lua
local M = {}

function M.toggle_sign(word)
  -- hex with optional sign
  if word:match "^%-?0x[%da-fA-F]+$" then
    return word:match "^%-" and word:sub(2) or "-" .. word
  end
  -- decimal or float with optional sign
  if word:match "^%-?%d+%.?%d*$" then
    return word:match "^%-" and word:sub(2) or "-" .. word
  end
  return nil
end

return M
