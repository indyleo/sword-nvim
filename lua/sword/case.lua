-- lua/sword/case.lua
local M = {}

function vim.tbl_indexof(tbl, val)
  for i, v in ipairs(tbl) do
    if v == val then
      return i
    end
  end
  return nil
end

function M.split_words(word)
  local parts = {}

  if word:find "_" then -- snake or SCREAM
    for w in word:gmatch "[^_]+" do
      table.insert(parts, w:lower())
    end
  elseif word:find "-" then -- kebab or COBOL
    for w in word:gmatch "[^-]+" do
      table.insert(parts, w:lower())
    end
  elseif word:match "^[A-Z0-9_-]+$" then -- SCREAM or COBOL
    for w in word:gmatch "[A-Z0-9]+" do
      table.insert(parts, w:lower())
    end
  elseif word:match "[a-z]" and word:match "[A-Z]" then -- camel or Pascal
    local first = word:match "^[a-z]+"
    if first then
      table.insert(parts, first)
    end
    for w in word:gmatch "[A-Z][a-z0-9]*" do
      table.insert(parts, w:lower())
    end
  else
    -- 💡 Flatcase fallback (e.g. myvariable): split by vowel-consonant transitions or 50/50
    if #word >= 6 then
      -- Try a basic heuristic split at the middle
      local mid = math.floor(#word / 2)
      table.insert(parts, word:sub(1, mid))
      table.insert(parts, word:sub(mid + 1))
    else
      table.insert(parts, word)
    end
  end

  return parts
end

M.to_cases = function(parts)
  local joined = table.concat(parts)
  local first = parts[1] or ""
  local rest = {}
  for i = 2, #parts do
    rest[#rest + 1] = parts[i]:sub(1, 1):upper() .. parts[i]:sub(2)
  end

  local pascal = {}
  for _, w in ipairs(parts) do
    pascal[#pascal + 1] = w:sub(1, 1):upper() .. w:sub(2)
  end

  local function map_upper(tbl)
    local res = {}
    for _, w in ipairs(tbl) do
      res[#res + 1] = w:upper()
    end
    return res
  end

  return {
    flatcase = joined,
    camelCase = first .. table.concat(rest),
    PascalCase = table.concat(pascal),
    snake_case = table.concat(parts, "_"),
    SCREAM_CASE = table.concat(map_upper(parts), "_"),
    ["kebab-case"] = table.concat(parts, "-"),
    ["COBOL-CASE"] = table.concat(map_upper(parts), "-"),
  }
end

function M.detect_style(word)
  if word:match "^%l+$" then
    return "flatcase"
  elseif word:match "^%l+%u" then
    return "camelCase"
  elseif word:match "^%u%l" and not word:find "_" and not word:find "-" then
    return "PascalCase"
  elseif word:match "^%l+_%l+" then
    return "snake_case"
  elseif word:match "^%u+_%u+" then
    return "SCREAM_CASE"
  elseif word:match "^%l+%-%l+" then
    return "kebab-case"
  elseif word:match "^%u+%-%u+" then
    return "COBOL-CASE"
  else
    return "flatcase"
  end
end

--- Cycle case with direction support
---@param word string
---@param lang string
---@param reverse number false=forward, true=backward
function M.cycle_case(word, lang, reverse)
  local direction = reverse and -1 or 1
  local parts = M.split_words(word)
  local all = M.to_cases(parts)

  local preferred = {
    lua = { "snake_case", "camelCase", "PascalCase", "SCREAM_CASE" },
    javascript = { "camelCase", "PascalCase", "snake_case" },
    python = { "snake_case", "SCREAM_CASE", "camelCase" },
    rust = { "snake_case", "SCREAM_CASE", "camelCase" },
    default = { "flatcase", "camelCase", "PascalCase", "snake_case", "SCREAM_CASE", "kebab-case", "COBOL-CASE" },
  }

  local order = preferred[lang or ""] or preferred.default
  local current_style = M.detect_style(word)
  local idx = vim.tbl_indexof(order, current_style) or 1
  local len = #order
  local new_idx = idx

  for _ = 1, len do
    new_idx = ((new_idx - 1) + direction) % len + 1
    local candidate = all[order[new_idx]]
    -- skip flatcase if parts length = 1 (likely stuck)
    if not (order[new_idx] == "flatcase" and #parts == 1) and candidate ~= word then
      return candidate
    end
  end

  -- fallback to original word if nothing else fits
  return word
end

return M
