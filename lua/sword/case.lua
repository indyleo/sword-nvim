-- lua/sword/case.lua
local M = {}

-- Polyfill for vim.tbl_indexof if not available
if not vim.tbl_indexof then
  function vim.tbl_indexof(tbl, val)
    for i, v in ipairs(tbl) do
      if v == val then
        return i
      end
    end
  end
end

-- 🧠 Improved word splitter: handles acronyms + camel/Pascal/kebab/snake
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
    -- Pure uppercase/screaming case - treat as single word
    table.insert(parts, word:lower())
  elseif word:match "[a-z]" and word:match "[A-Z]" then
    -- CamelCase/PascalCase with potential acronyms
    local chunk = ""
    for i = 1, #word do
      local c = word:sub(i, i)
      local nextc = word:sub(i + 1, i + 1)
      local prevc = word:sub(i - 1, i - 1)

      if c:match "%u" then
        -- Uppercase letter
        if nextc and nextc:match "%l" then
          -- Start of new word (e.g., XMLParser -> "XML" + "Parser")
          if #chunk > 0 then
            table.insert(parts, chunk:lower())
          end
          chunk = c
        elseif prevc and prevc:match "%l" then
          -- Transition from lower to upper (e.g., myVariable)
          if #chunk > 0 then
            table.insert(parts, chunk:lower())
          end
          chunk = c
        else
          -- Consecutive uppercase (acronym like HTTP)
          chunk = chunk .. c
        end
      else
        -- Lowercase letter or number
        chunk = chunk .. c
      end
    end
    if #chunk > 0 then
      table.insert(parts, chunk:lower())
    end
  else
    -- Fallback: single word
    table.insert(parts, word:lower())
  end

  return parts
end

-- 🧩 Convert back into all case formats
function M.to_cases(parts)
  if #parts == 0 then
    return {}
  end

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
    typescript = { "camelCase", "PascalCase", "snake_case" },
    python = { "snake_case", "SCREAM_CASE", "camelCase" },
    rust = { "snake_case", "SCREAM_CASE", "camelCase" },
    go = { "camelCase", "PascalCase", "snake_case" },
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
