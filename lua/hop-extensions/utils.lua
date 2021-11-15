local M = {}
local jump_target = require "hop.jump_target"
-- Wrap all the given jump targets using manh_dist
M.wrap_targets = function(targets)
  utils.dump(#targets)
  local cursor_pos = require("hop.window").get_window_context().cursor_pos
  local indir = {}
  for i, v in ipairs(targets) do
    indir[#indir + 1] = {
      index = i,
      score = -jump_target.manh_dist({ v.line, v.column }, cursor_pos),
    }
  end
  -- local indir = setmetatable({}, zero_jump_scores)
  return {
    jump_targets = targets,
    indirect_jump_targets = indir,
  }
end
-- Allows to override global options with user local overrides.
function M.override_opts(opts)
  local hopopts = require("hop").opts
  return setmetatable(opts or {}, {
    -- __index = function(_, key)
    --   return hopopts[key]
    -- end,
    __index = hopopts,
  })
end
return M
