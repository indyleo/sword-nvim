-- lua/sword/case.lua
local M = {}

-- Helper: find index in table
function vim.tbl_indexof(tbl, val)
  for i, v in ipairs(tbl) do
    if v == val then
      return i
    end
  end
end

-- 🧠 Smarter word splitter: handles acronyms + camel/Pascal/kebab/snake
function M.split_words(word)
  local parts = {}

  if word:find "_" then
    for w in word:gmatch "[^_]+" do
      table.insert(parts, w:lower())
    end
  elseif word:find "-" then
    for w in word:gmatch "[^-]+" do
      table.insert(parts, w:lower())
    end
  elseif word:match "^[A-Z0-9_-]+$" then
    for w in word:gmatch "[A-Z0-9]+" do
      table.insert(parts, w:lower())
    end
  elseif word:match "[a-z]" and word:match "[A-Z]" then
    -- Handle acronyms like "XMLHttpRequest" or "MyXMLParser"
    local chunk = ""
    for i = 1, #word do
      local c = word:sub(i, i)
      local nextc = word:sub(i + 1, i + 1)
      if c:match "%u" and nextc and nextc:match "%l" and #chunk > 1 then
        table.insert(parts, chunk:lower())
        chunk = c
      elseif c:match "%l" and nextc and nextc:match "%u" then
        chunk = chunk .. c
        table.insert(parts, chunk:lower())
        chunk = ""
      else
        chunk = chunk .. c
      end
    end
    if #chunk > 0 then
      table.insert(parts, chunk:lower())
    end
  else
    -- fallback
    table.insert(parts, word:lower())
  end

  return parts
end

-- 🧩 Convert back into all case formats
function M.to_cases(parts)
  local function upper_all(tbl)
    local res = {}
    for _, w in ipairs(tbl) do
      table.insert(res, w:upper())
    end
    return res
  end

  local first = parts[1] or ""
  local rest = {}
  for i = 2, #parts do
    rest[i - 1] = parts[i]:sub(1, 1):upper() .. parts[i]:sub(2)
  end

  local pascal = {}
  for _, w in ipairs(parts) do
    table.insert(pascal, w:sub(1, 1):upper() .. w:sub(2))
  end

  return {
    flatcase = table.concat(parts),
    camelCase = first .. table.concat(rest),
    PascalCase = table.concat(pascal),
    snake_case = table.concat(parts, "_"),
    SCREAM_CASE = table.concat(upper_all(parts), "_"),
    ["kebab-case"] = table.concat(parts, "-"),
    ["COBOL-CASE"] = table.concat(upper_all(parts), "-"),
  }
end

-- 🕵️ Detect case style
function M.detect_style(word)
  if word:match "^%l+$" then
    return "flatcase"
  elseif word:match "^%l+%u" then
    return "camelCase"
  elseif word:match "^%u%l" and not word:find "[_%-]" then
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

-- 🔁 Cycle case style
function M.cycle_case(word, lang, reverse)
  local direction = reverse and -1 or 1
  local parts = M.split_words(word)
  local all = M.to_cases(parts)
  local style = M.detect_style(word)

  local preferred = {
    lua = { "snake_case", "camelCase", "PascalCase", "SCREAM_CASE" },
    javascript = { "camelCase", "PascalCase", "snake_case" },
    python = { "snake_case", "SCREAM_CASE", "camelCase" },
    rust = { "snake_case", "SCREAM_CASE", "camelCase" },
    default = { "flatcase", "camelCase", "PascalCase", "snake_case", "SCREAM_CASE", "kebab-case", "COBOL-CASE" },
  }

  local order = preferred[lang or ""] or preferred.default
  local idx = vim.tbl_indexof(order, style) or 1
  local len = #order

  for i = 1, len do
    idx = ((idx - 1) + direction) % len + 1
    local next_style = order[idx]
    local candidate = all[next_style]
    if candidate and candidate ~= word then
      return candidate
    end
  end

  return word
end

return M
