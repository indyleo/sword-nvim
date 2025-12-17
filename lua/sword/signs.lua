-- lua/sword/signs.lua
local M = {}

-- Toggle numeric signs and incrementors
function M.toggle_sign(word)
  -- 1. Handle Incrementors (++ / --)
  if word == "++" then
    return "--"
  end
  if word == "--" then
    return "++"
  end

  -- 2. Handle Hex (0xFF <-> -0xFF)
  if word:match "^%-?0x[%da-fA-F]+$" then
    return word:match "^%-" and word:sub(2) or "-" .. word
  end

  -- 3. Handle Decimals/Integers (5 <-> -5, 3.14 <-> -3.14)
  if word:match "^%-?%d+%.?%d*$" then
    return word:match "^%-" and word:sub(2) or "-" .. word
  end

  return nil
end

return M
