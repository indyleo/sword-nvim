-- lua/sword/init.lua
local M = {}

M.groups = require "sword.groups"
M.signs = require "sword.signs"
M.core = require "sword.core"
M.commands = require "sword.commands"

function M.setup()
  M.commands.setup_commands()
end

return M
