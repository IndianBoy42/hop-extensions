local M = {}
local hop = require("hop")
-- Monkey patching
local old_hint_with = hop.hint_with
hop.hint_with = function(targets, opts, callback)
	callback = callback or opts.callback
	if type(callback) == "string" then
		callback = require("hop-extensions.actions")[callback](opts)
	end
	if callback then
		return hop.hint_with_callback(targets, opts, callback)
	else
		old_hint_with(targets, opts)
	end
end

local jump_target = require("hop.jump_target")
-- Wrap all the given jump targets using manh_dist
local get_window_context = require("hop.window").get_window_context
M.wrap_targets = function(targets, contexts)
	local cursor_pos = { vim.fn.line("."), vim.fn.charcol(".") }
	local indir = {}
	for i, v in ipairs(targets) do
		indir[#indir + 1] = {
			index = i,
			score = jump_target.manh_dist(cursor_pos, { v.line, v.column }),
		}
	end
	-- local indir = setmetatable({}, zero_jump_scores)
	jump_target.sort_indirect_jump_targets(indir, {})
	return {
		jump_targets = targets,
		indirect_jump_targets = indir,
	}
end
-- Allows to override global options with user local overrides.
function M.override_opts(opts)
	local hopopts = hop.opts
	opts = opts or {}
	opts.hint_with = opts.hint_with or hop.hint_with
	opts.filter_window = opts.filter_window or M.filter_window
	return setmetatable(opts, {
		-- __index = function(_, key)
		--   return hopopts[key]
		-- end,
		__index = hopopts,
	})
end

function M.filter_window(opts, node, nodes_set)
	opts = opts or {}
	local contexts = get_window_context(opts.multi_windows)
	if not node.line and node.lnum then
		node.line = node.lnum - 1 -- This comes from quickfix... just correct it
	end
	local line = node.line
	if not node.column and node.col then
		node.column = node.col
	end
	local column = node.column

	-- TODO: support multi window
	local context = contexts[1].contexts[1] -- Just the primary window
	if line > context.bot_line or line < context.top_line then
		return false
	end
	if node.hwin and node.hwin ~= context.hwin then
		return false
	end
	if node.bufnr and node.bufnr ~= contexts[1].hbuf then
		return false
	end
	if node.filename then
		local bufnr = contexts[1].hbuf

		local name = vim.api.nvim_buf_get_name(bufnr)
		if name ~= node.filename then
			return false
		end
	end

	local n = {}
	for key, value in pairs(node) do
		n[key] = value
	end
	nodes_set[line .. column] = n

	return true
end

M.on_list_hop = function(opts, callback)
	opts = M.override_opts(opts)
	return {
		on_list = function(list)
			local contexts = get_window_context(opts.multi_windows --[[ hint_opts --]])
			local items = list.items

			local out = {}
			for _, loc in ipairs(items) do
				loc.window = 0
				opts.filter_window(opts, loc, out)
			end
			-- TODO: fallback to just jumping if none visible
			local targets = M.wrap_targets(vim.tbl_values(out), contexts)

			opts.hint_with(function()
				return targets
			end, opts, callback)
		end,
	}
end

return M
